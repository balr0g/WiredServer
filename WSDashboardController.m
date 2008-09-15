/* $Id$ */

/*
 *  Copyright (c) 2003-2006 Axel Andersson
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
 * ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import "WSAccountsController.h"
#import "WSConfigController.h"
#import "WSDashboardController.h"
#import "WSLogController.h"
#import "WSSettings.h"
#import "WSStatusController.h"

static WSDashboardController		*sharedDashboardController;


@interface WSDashboardController(Private)

- (void)_update;

@end


@implementation WSDashboardController(Private)

- (void)_update {
	BOOL	enabled;

	if([_statusController isRunning])
		[_startButton setTitle:WSLS(@"Stop", "Stop button title")];
	else
		[_startButton setTitle:WSLS(@"Start", "Start button title")];
	
	enabled = [self isAuthorized] && [_statusController isAvailable];
	[_startButton setEnabled:enabled];
	enabled = [self isAuthorized] && [_statusController isAvailable] && [_statusController isRunning];
	[_restartButton setEnabled:enabled];
	[_reloadButton setEnabled:enabled];
	[_registerButton setEnabled:enabled];
	[_indexButton setEnabled:enabled];
}

@end


@implementation WSDashboardController

+ (WSDashboardController *)dashboardController {
	return sharedDashboardController;
}



- (id)init {
	self = [super init];
	
	sharedDashboardController = self;
	
	return self;
}



- (void)awakeFromNib {
	NSArray					*tasks;
	AuthorizationRights		rights;
	unsigned int			i;
	
	tasks = [NSArray arrayWithObjects:
		WSExpandWiredPath(@"wiredctl"),
		@"/usr/bin/touch",
		@"/bin/mv",
		@"/bin/rm",
		@"/usr/bin/openssl",
		@"/usr/sbin/chown",
		NULL];

	rights.count = [tasks count];
	rights.items = (AuthorizationItem *) malloc(rights.count * sizeof(AuthorizationItem));
	
	for(i = 0; i < rights.count; i++) {
		rights.items[i].name = kAuthorizationRightExecute;
		rights.items[i].flags = 0;
		rights.items[i].value = (char *) [[tasks objectAtIndex:i] UTF8String];
		rights.items[i].valueLength = strlen(rights.items[i].value);
	}

	[_authorizationView setAuthorizationRights:&rights];
	[_authorizationView setDelegate:self];
	[_authorizationView updateStatus:self];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(wiredStatusDidChange:)
			   name:WSWiredStatusDidChange
			 object:NULL];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(configDidChange:)
			   name:WSConfigDidChange
			 object:NULL];
}



- (void)awakeFromController {
	[self _update];
}



- (void)closeFromController {
}



#pragma mark -

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view {
	_authorized = YES;
	
	[self _update];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:WSAuthorizationStatusDidChange object:[NSNumber numberWithBool:_authorized]];
}



- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view {
	_authorized = NO;
	
	[self _update];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:WSAuthorizationStatusDidChange object:[NSNumber numberWithBool:_authorized]];
}



- (void)wiredStatusDidChange:(NSNotification *)notification {
	[self _update];
}



- (void)configDidChange:(NSNotification *)notification {
	if([_statusController isAvailable] && [_statusController isRunning])
		[self reload:self];
}



#pragma mark -

- (NSArray *)launchArguments {
	NSMutableArray	*arguments;
	
	arguments = [NSMutableArray array];
	
	switch([[WSSettings objectForKey:WSLogMethod] intValue]) {
		case WSLogMethodSyslog:
			[arguments addObject:@"-s"];
			[arguments addObject:[WSSettings objectForKey:WSSyslogFacility]];
			break;
			
		case WSLogMethodFile:
			[arguments addObject:@"-L"];
			[arguments addObject:[[WSSettings objectForKey:WSLogFile] stringByExpandingTildeInPath]];
			
			if([WSSettings boolForKey:WSLimitLogFile]) {
				[arguments addObject:@"-i"];
				[arguments addObject:[NSSWF:@"%u", [WSSettings intForKey:WSLimitLogFileLines]]];
			}
			break;
	}
	
	return arguments;
}



#pragma mark -

- (BOOL)isAuthorized {
	return _authorized;
}



- (BOOL)launchTaskWithPath:(NSString *)path arguments:(NSArray *)arguments {
	NSFileHandle	*fileHandle;
	NSData			*data;
	OSStatus		err;
	FILE			*fp = NULL;
	char			**argv;
	NSUInteger		i, argc;
	int				status;
	pid_t			pid;
	
	argc = [arguments count];
	argv = (char **) malloc(sizeof(char *) * (argc + 1));
	
	for(i = 0; i < argc; i++)
		argv[i] = (char *) [[[arguments objectAtIndex:i] description] UTF8String];
	
	argv[i] = NULL;
	
	err = AuthorizationExecuteWithPrivileges([[_authorizationView authorization] authorizationRef],
											 [path UTF8String],
											 kAuthorizationFlagDefaults,
											 argv,
											 &fp);
	free(argv);
	
	if(err != errAuthorizationSuccess) {
		NSLog(@"AuthorizationExecuteWithPrivileges: %d", err);
		
		return NO;
	}
	
	pid = wait3(&status, WNOHANG, NULL);

	if(pid > 0) {
		fileHandle = [[NSFileHandle alloc] initWithFileDescriptor:fileno(fp) closeOnDealloc:NO];
		data = [fileHandle availableData];
		[[WSLogController logController] log:[NSString stringWithData:data encoding:NSUTF8StringEncoding]];
		[fileHandle release];
	}
	
	fclose(fp);
	
	return YES;
}



- (BOOL)createFileAtPath:(NSString *)path {
	return [self launchTaskWithPath:@"/usr/bin/touch" arguments:[NSArray arrayWithObject:path]];
}



- (BOOL)movePath:(NSString *)fromPath toPath:(NSString *)toPath {
	NSArray		*arguments;
	
	arguments = [NSArray arrayWithObjects:
		@"-f",
		fromPath,
		toPath,
		NULL];
	
	return [self launchTaskWithPath:@"/bin/mv" arguments:arguments];
}



- (BOOL)removeFileAtPath:(NSString *)path {
	NSArray		*arguments;
	
	arguments = [NSArray arrayWithObjects:
		@"-rf",
		path,
		NULL];
	
	return [self launchTaskWithPath:@"/bin/rm" arguments:arguments];
}



- (BOOL)changeOwnerOfPath:(NSString *)path toUser:(NSString *)user group:(NSString *)group {
	NSArray		*arguments;
	
	arguments = [NSArray arrayWithObjects:
		@"-h",
		[NSSWF:@"%@:%@", user, group],
		path,
		NULL];
	
	return [self launchTaskWithPath:@"/usr/sbin/chown" arguments:arguments];
}



#pragma mark -

- (IBAction)start:(id)sender {
	NSMutableArray	*arguments;
	
	arguments = [NSMutableArray array];
	
	if([_statusController isRunning])
		[arguments addObject:@"stop"];
	else
		[arguments addObject:@"start"];
	
	[self launchTaskWithPath:WSExpandWiredPath(@"wiredctl") arguments:arguments];
}



- (IBAction)restart:(id)sender {
	NSMutableArray	*arguments;
	
	arguments = [NSMutableArray array];
	[arguments addObject:@"restart"];
	
	[self launchTaskWithPath:WSExpandWiredPath(@"wiredctl") arguments:arguments];
}



- (IBAction)reload:(id)sender {
	[self launchTaskWithPath:WSExpandWiredPath(@"wiredctl") arguments:[NSArray arrayWithObject:@"reload"]];
}



- (IBAction)registerWithTracker:(id)sender {
	[self launchTaskWithPath:WSExpandWiredPath(@"wiredctl") arguments:[NSArray arrayWithObject:@"register"]];
}



- (IBAction)indexFiles:(id)sender {
	[self launchTaskWithPath:WSExpandWiredPath(@"wiredctl") arguments:[NSArray arrayWithObject:@"index"]];
}

@end
