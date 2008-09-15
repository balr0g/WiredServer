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

#define SYSLOG_NAMES
#import <syslog.h>
#undef SYSLOG_NAMES

#import "WSConfig.h"
#import "WSConfigController.h"
#import "WSDashboardController.h"
#import "WSSettings.h"
#import "WSStatusController.h"

static WSConfigController		*sharedConfigController;

@interface WSConfigController(Private)

- (void)_update;

- (void)_readFromFile:(NSString *)path;
- (BOOL)_writeToFile:(NSString *)path;
- (BOOL)_writeFlagsToFile:(NSString *)path;

- (void)_setBanner:(NSImage *)banner;
- (void)_setLaunchesAtBoot:(BOOL)value;
- (void)_changeOwnerOfPrefixPathToUser:(NSString *)user group:(NSString *)group;

@end


@implementation WSConfigController(Private)

- (void)_update {
	BOOL		enabled;
	NSInteger	method;
	
	enabled = [[WSDashboardController dashboardController] isAuthorized];
	method = [[_logMethodMatrix selectedCell] tag];

	[_nameTextField setEnabled:enabled];
	[_portTextField setEnabled:enabled];
	[_descriptionTextField setEnabled:enabled];
	[_bannerImageView setEnabled:enabled];
	[_bannerImageView setEditable:enabled];
	[_selectBannerButton setEnabled:enabled];
	[_clearBannerButton setEnabled:enabled];
	[_totalDownloadsTextField setEnabled:enabled];
	[_downloadSpeedTextField setEnabled:enabled];
	[_totalUploadsTextField setEnabled:enabled];
	[_uploadSpeedTextField setEnabled:enabled];
	[_filesTextField setEnabled:enabled];
	[_selectFilesButton setEnabled:enabled];
	
	[_registerWithTrackersButton setEnabled:enabled];
	[_trackersTableView setEnabled:enabled];
	[_trackersTableView setNeedsDisplay:YES];
	[_addTrackerButton setEnabled:enabled];
	[_deleteTrackerButton setEnabled:(enabled && [_trackersTableView selectedRow] >= 0)];
	[_indexPopUpButton setEnabled:enabled];
	[_limitNewsButton setEnabled:enabled];
	[_limitNewsButton setEnabled:enabled];
	[_limitNewsTextField setEnabled:(enabled && [_limitNewsButton state] == NSOnState)];

	[_userPopUpButton setEnabled:enabled];
	[_groupPopUpButton setEnabled:enabled];
	[_launchAtBootButton setEnabled:enabled];
	[_logMethodMatrix setEnabled:enabled];
	[_syslogPopUpButton setEnabled:(enabled && method == WSLogMethodSyslog)];
	[_logFileTextField setEnabled:(enabled && method == WSLogMethodFile)];
	[_selectLogFileButton setEnabled:(enabled && method == WSLogMethodFile)];
	[_limitLogFileButton setEnabled:(enabled && method == WSLogMethodFile)];
	[_limitLogFileTextField setEnabled:(enabled && method == WSLogMethodFile && [_limitLogFileButton state] == NSOnState)];
}



#pragma mark -

- (void)_readFromFile:(NSString *)path {
	[_config release];
	_config = [[WSConfig alloc] initWithContentsOfFile:path];
	
	// --- config
	[_limitNewsButton setState:[WSSettings boolForKey:WSLimitNews]];
	
	[_logMethodMatrix selectCellWithTag:[WSSettings intForKey:WSLogMethod]];
	[_syslogPopUpButton selectItemWithTitle:[WSSettings objectForKey:WSSyslogFacility]];
	[_logFileTextField setStringValue:[WSSettings objectForKey:WSLogFile]];
	[_limitLogFileButton setState:[WSSettings boolForKey:WSLimitLogFile]];
	
	if([WSSettings intForKey:WSLimitLogFileLines] > 0)
		[_limitLogFileTextField setIntValue:[WSSettings intForKey:WSLimitLogFileLines]];

	// --- settings
	[_nameTextField setStringValue:[_config stringForKey:@"name"]];
	[_portTextField setStringValue:[_config stringForKey:@"port"]];
	
	[_descriptionTextField setStringValue:[_config stringForKey:@"description"]];
	[_bannerImageView setImage:[_config imageForKey:@"banner"]];
	[_launchAtBootButton setState:[[NSFileManager defaultManager] fileExistsAtPath:
		WSExpandWiredPath(@"etc/wired.startup")]];
	
	[_totalDownloadsTextField setStringValue:[_config stringForKey:@"total downloads"]];
	
	if([_config intForKey:@"total download speed"] > 0)
		[_downloadSpeedTextField setIntValue:[_config doubleForKey:@"total download speed"] / 1024.0];
	
	[_totalUploadsTextField setStringValue:[_config stringForKey:@"total uploads"]];
	
	if([_config intForKey:@"total upload speed"] > 0)
		[_uploadSpeedTextField setIntValue:[_config doubleForKey:@"total upload speed"] / 1024.0];
	
	[_filesTextField setStringValue:[_config pathForKey:@"files"]];
	
	// --- advanced
	[_registerWithTrackersButton setState:[_config boolForKey:@"register"]];
	
	[_trackersTableView reloadData];

	if([_config intForKey:@"index time"] == 86400)
		[_indexPopUpButton selectItemAtIndex:2];
	if([_config intForKey:@"index time"] == 3600)
		[_indexPopUpButton selectItemAtIndex:1];
	else
		[_indexPopUpButton selectItemAtIndex:0];
	
	[_limitNewsTextField setStringValue:[_config stringForKey:@"news limit"]];
	
	// --- system
	[_userPopUpButton selectItemWithTitle:[_config stringForKey:@"user"]];
	[_groupPopUpButton selectItemWithTitle:[_config stringForKey:@"group"]];
}



- (BOOL)_writeToFile:(NSString *)path {
	NSString				*temp, *owner;
	WSDashboardController	*controller;

	// --- config
	[WSSettings setBool:([_limitNewsButton state] == NSOnState) forKey:WSLimitNews];
	
	[WSSettings setInt:[[_logMethodMatrix selectedCell] tag] forKey:WSLogMethod];
	[WSSettings setObject:[_syslogPopUpButton titleOfSelectedItem] forKey:WSSyslogFacility];
	[WSSettings setObject:[_logFileTextField stringValue] forKey:WSLogFile];
	[WSSettings setBool:([_limitLogFileButton state] == NSOnState) forKey:WSLimitLogFile];
	[WSSettings setInt:[_limitLogFileTextField intValue] forKey:WSLimitLogFileLines];
	
	// --- settings
	[_config setString:[_nameTextField stringValue] forKey:@"name"];
	[_config setString:[_portTextField stringValue] forKey:@"port"];
	[_config setString:[_descriptionTextField stringValue] forKey:@"description"];
	
	[_config setString:[_totalDownloadsTextField stringValue] forKey:@"total downloads"];
	[_config setInt:[_downloadSpeedTextField intValue] * 1024 forKey:@"total download speed"];
	[_config setString:[_totalUploadsTextField stringValue] forKey:@"total uploads"];
	[_config setInt:[_uploadSpeedTextField intValue] * 1024 forKey:@"total upload speed"];
	
	[_config setString:[_filesTextField stringValue] forKey:@"files"];
	
	// --- advanced
	[_config setBool:([_registerWithTrackersButton state] == NSOnState) forKey:@"register"];
	
	switch([_indexPopUpButton indexOfSelectedItem]) {
		case 0:
			[_config setString:@"" forKey:@"index time"];
			break;
			
		case 2:
			[_config setInt:3600 forKey:@"index time"];
			break;
			
		case 3:
			[_config setInt:86400 forKey:@"index time"];
			break;
	}
	
	if([_limitNewsButton state] == NSOnState)
		[_config setString:[_limitNewsTextField stringValue] forKey:@"news limit"];
	else
		[_config setString:@"" forKey:@"news limit"];
	
	// --- system
	[_config setString:[_userPopUpButton titleOfSelectedItem] forKey:@"user"];
	[_config setString:[_groupPopUpButton titleOfSelectedItem] forKey:@"group"];
	
	controller	= [WSDashboardController dashboardController];
	temp		= [NSFileManager temporaryPathWithPrefix:@"config" suffix:@"conf"];
	
	if([_config writeToFile:temp]) {
		if([controller movePath:temp toPath:path]) {
			if([controller changeOwnerOfPath:path
									  toUser:[_config stringForKey:@"user"]
									   group:[_config stringForKey:@"group"]]) {
				owner = [[NSFileManager defaultManager] ownerAtPath:[WSSettings objectForKey:WSPrefixPath]];

				if(![owner isEqualToString:[_config stringForKey:@"user"]])
					[self _changeOwnerOfPrefixPathToUser:[_config stringForKey:@"user"] group:[_config stringForKey:@"group"]];
				
				_touched = NO;
				
				return YES;
			}
		}
	}

	return NO;
}



- (BOOL)_writeFlagsToFile:(NSString *)path {
	NSString				*string, *temp;
	WSDashboardController	*controller;
	
	controller	= [WSDashboardController dashboardController];
	string		= [[controller launchArguments] componentsJoinedByString:@" "];
	temp		= [NSFileManager temporaryPathWithPrefix:@"wired" suffix:@"flags"];
	
	if([string writeToFile:temp atomically:YES]) {
		if([controller movePath:temp toPath:path]) {
			if([controller changeOwnerOfPath:path
									  toUser:[_config stringForKey:@"user"]
									   group:[_config stringForKey:@"group"]])
				return YES;
		}
	}
	
	return NO;
}



#pragma mark -

- (void)_setBanner:(NSImage *)banner {
	NSData					*data;
	NSString				*path, *temp;
	WSDashboardController	*controller;
	BOOL					success = NO;

	banner		= [banner scaledImageWithSize:NSMakeSize(200.0, 32.0)];
	data		= [[NSBitmapImageRep imageRepWithData:[banner TIFFRepresentation]] representationUsingType:NSPNGFileType properties:NULL];
	path		= WSExpandWiredPath(@"banner.png");
	controller	= [WSDashboardController dashboardController];
	temp		= [NSFileManager temporaryPathWithPrefix:@"banner" suffix:@"png"];
	
	if([data writeToFile:temp atomically:YES]) {
		if([controller movePath:temp toPath:path]) {
			if([controller changeOwnerOfPath:path
									  toUser:[_config stringForKey:@"user"]
									   group:[_config stringForKey:@"group"]]) {
				[_config setString:path forKey:@"banner"];
				_touched = YES;
				success = YES;
			}
		}
	}
	
	[_bannerImageView setImage:success ? banner : NULL];
}



- (void)_setLaunchesAtBoot:(BOOL)value {
	NSString				*path;
	WSDashboardController	*controller;
	
	path		= WSExpandWiredPath(@"etc/wired.startup");
	controller	= [WSDashboardController dashboardController];

	if(value) {
		if([controller createFileAtPath:path]) {
			[controller changeOwnerOfPath:path
								   toUser:[_config stringForKey:@"user"]
									group:[_config stringForKey:@"group"]];
		}
	} else {
		[controller removeFileAtPath:path];
	}
}



- (void)_changeOwnerOfPrefixPathToUser:(NSString *)user group:(NSString *)group {
	NSEnumerator			*enumerator;
	NSString				*path, *file;
	WSDashboardController	*controller;
	
	controller	= [WSDashboardController dashboardController];
	path		= [WSSettings objectForKey:WSPrefixPath];
	
	if(![controller changeOwnerOfPath:path toUser:user group:group])
		return;
	
	enumerator = [[[NSFileManager defaultManager] directoryContentsAtPath:path] objectEnumerator];
	
	while((file = [enumerator nextObject])) {
		if(![controller changeOwnerOfPath:[path stringByAppendingPathComponent:file] toUser:user group:group])
			return;
	}
}

@end


@implementation WSConfigController

+ (WSConfigController *)configController {
	return sharedConfigController;
}



- (id)init {
	self = [super init];
	
	sharedConfigController = self;
	
	return self;
}



- (void)awakeFromNib {
	NSComboBoxCell		*comboCell;
	NSMutableArray		*array;
	struct passwd		*user;
	struct group		*group;
	int					i;
	
	_okImage = [[NSImage alloc] initWithContentsOfFile:
		[[self bundle] pathForResource:@"OK" ofType:@"tiff"]];
	_errorImage = [[NSImage alloc] initWithContentsOfFile:
		[[self bundle] pathForResource:@"Error" ofType:@"tiff"]];

	array = [NSMutableArray array];
	[_userPopUpButton removeAllItems];
	
	while((user = getpwent()))
		[array addObject:[NSString stringWithCString:user->pw_name]];
	
	[array sortUsingSelector:@selector(compare:)];
	[_userPopUpButton addItemsWithTitles:array];
	
	[array removeAllObjects];
	[_groupPopUpButton removeAllItems];
	
	while((group = getgrent()))
		[array addObject:[NSString stringWithCString:group->gr_name]];
	
	[array sortUsingSelector:@selector(compare:)];
	[_groupPopUpButton addItemsWithTitles:array];
	
	[array removeAllObjects];
	[_syslogPopUpButton removeAllItems];

	for(i = 0; facilitynames[i].c_name != NULL; i++)
		[array addObject:[NSString stringWithCString:facilitynames[i].c_name]];
	
	[array sortUsingSelector:@selector(compare:)];
	[_syslogPopUpButton addItemsWithTitles:array];

	comboCell = [[NSComboBoxCell alloc] init];
	[comboCell setControlSize:NSSmallControlSize];
	[comboCell addItemsWithObjectValues:[NSArray arrayWithObjects:
		@"Chat",
		@"Movies",
		@"Music",
		@"Regional/Asia",
		@"Regional/Europe",
		@"Regional/Oceania",
		@"Regional/North America",
		@"Regional/South America",
		@"Software",
		NULL]];
	[comboCell setNumberOfVisibleItems:[comboCell numberOfItems]];
	[comboCell setEditable:YES];
	[_categoryTableColumn setDataCell:comboCell];
	[comboCell release];
	
	[_certificateProgressIndicator setUsesThreadedAnimation:YES];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(authorizationStatusDidChange:)
			   name:WSAuthorizationStatusDidChange
			 object:NULL];

	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(wiredStatusDidChange:)
			   name:WSWiredStatusDidChange
			 object:NULL];
}



- (void)awakeFromController {
	[self _readFromFile:WSExpandWiredPath(@"etc/wired.conf")];
	
	[self _update];
}



- (BOOL)saveFromController {
	if(_touched) {
		if([self _writeToFile:WSExpandWiredPath(@"etc/wired.conf")]) {
			[[NSNotificationCenter defaultCenter] postNotificationName:WSConfigDidChange];

			if(_logTouched) {
				[[NSNotificationCenter defaultCenter] postNotificationName:WSLogConfigDidChange];
				
				_logTouched = YES;
			}
			
			[self _writeFlagsToFile:WSExpandWiredPath(@"etc/wired.flags")];
			[self _setLaunchesAtBoot:[_launchAtBootButton state]];
			
			return YES;
		}
		
		return NO;
	}
	
	return YES;
}



- (void)closeFromController {
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[_okImage release];
	[_errorImage release];
	
	[super dealloc];
}



#pragma mark -

- (void)authorizationStatusDidChange:(NSNotification *)notification {
	_authorized = [[notification object] boolValue];
	
	if(_authorized) {
		if(![[NSFileManager defaultManager] fileExistsAtPath:WSExpandWiredPath(@"etc/wired.flags")])
			[self _writeFlagsToFile:WSExpandWiredPath(@"etc/wired.flags")];
	}

	[self _update];
}



- (void)wiredStatusDidChange:(NSNotification *)notification {
	[self _update];
}



- (void)controlTextDidChange:(NSNotification *)notification {
	NSControl   *control;
	
	control = [notification object];
	
	if(control == _logFileTextField)
		_logTouched = YES;
		
	_touched = YES;
}



- (void)filesPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(NSInteger)returnCode contextInfo:(void  *)contextInfo {
	if(returnCode == NSOKButton) {
		[_filesTextField setStringValue:[[openPanel filenames] objectAtIndex:0]];
	
		_touched = YES;
	}
}



- (void)logFilePanelDidEnd:(NSOpenPanel *)openPanel returnCode:(NSInteger)returnCode contextInfo:(void  *)contextInfo {
	if(returnCode == NSOKButton) {
		[_logFileTextField setStringValue:[[openPanel filenames] objectAtIndex:0]];
		
		_touched = YES;
		_logTouched = YES;
	}
}



#pragma mark -

- (WSConfig *)config {
	return _config;
}



#pragma mark -

- (IBAction)touch:(id)sender {
	[self _update];
	
	if(sender == _logMethodMatrix)
		_logTouched = YES;
	
	_touched = YES;
}



- (IBAction)banner:(id)sender {
	[self _setBanner:[_bannerImageView image]];
}



- (IBAction)setBanner:(id)sender {
	NSOpenPanel		*openPanel;
	
	openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel beginSheetForDirectory:[WSSettings objectForKey:WSPrefixPath]
								 file:NULL
								types:NULL
					   modalForWindow:[_selectBannerButton window]
						modalDelegate:self
					   didEndSelector:@selector(bannerPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:NULL];
}



- (void)bannerPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(int)returnCode contextInfo:(void  *)contextInfo {
	NSData		*data;
	NSImage		*image;

	if(returnCode == NSOKButton) {
		data = [NSData dataWithContentsOfFile:[openPanel filename]];
		image = [NSImage imageWithData:data];
		
		if(image)
			[self _setBanner:image];
	}
}



- (IBAction)clearBanner:(id)sender {
	[_bannerImageView setImage:NULL];
	[_config setString:NULL forKey:@"banner"];
	
	_touched = YES;
}



- (IBAction)selectFiles:(id)sender {
	NSOpenPanel		*openPanel;
	NSString		*path;
	
	path = [_filesTextField stringValue];
	openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setCanChooseFiles:NO];
	[openPanel beginSheetForDirectory:[path stringByDeletingLastPathComponent]
								 file:[path lastPathComponent]
								types:NULL
					   modalForWindow:[_selectFilesButton window]
						modalDelegate:self
					   didEndSelector:@selector(filesPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:NULL];
}



- (IBAction)addTracker:(id)sender {
	NSMutableArray  *tracker;
	NSInteger		row;
	
	tracker = [_config arrayForKey:@"tracker"];
	[tracker addObject:@"wiredtracker:///"];
	[_config setArray:tracker forKey:@"tracker"];
	
	[_trackersTableView reloadData];
	_touched = YES;
	
	row = [[_config arrayForKey:@"tracker"] count] - 1;
	[_trackersTableView selectRow:row byExtendingSelection:NO];
	[_trackersTableView editColumn:0 row:row withEvent:NULL select:YES];
}



- (IBAction)deleteTracker:(id)sender {
	[[_config arrayForKey:@"tracker"] removeObjectAtIndex:[_trackersTableView selectedRow]];
	
	[_trackersTableView reloadData];
	_touched = YES;
}



- (IBAction)selectLogFile:(id)sender {
	NSOpenPanel		*openPanel;
	
	openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setCanChooseFiles:YES];
	[openPanel beginSheetForDirectory:[WSSettings objectForKey:WSPrefixPath]
								 file:NULL
								types:NULL
					   modalForWindow:[_selectLogFileButton window]
						modalDelegate:self
					   didEndSelector:@selector(logFilePanelDidEnd:returnCode:contextInfo:)
						  contextInfo:NULL];
}



#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[_config arrayForKey:@"tracker"] count];
}



- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSString	*tracker, *host, *category;
	WIURL		*url;
	
	tracker = [[_config arrayForKey:@"tracker"] objectAtIndex:row];
	url = [WIURL URLWithString:tracker];
	
	if(url) {
		host = [url hostpair];
		category = ([[url path] length] > 0) ? [[url path] substringFromIndex:1] : NULL;
	} else {
		host = tracker;
		category = NULL;
	}
	
	if(tableColumn == _trackerTableColumn)
		return host;
	else if(tableColumn == _categoryTableColumn)
		return category;

	return NULL;
}



- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	NSString	*tracker, *value = NULL;
	WIURL		*url;

	tracker = [[_config arrayForKey:@"tracker"] objectAtIndex:row];
	url = [WIURL URLWithString:tracker];

	if(tableColumn == _trackerTableColumn) {
		if(url)
			value = [NSSWF:@"wiredtracker://%@%@", object, [url path]];
		else
			value = [NSSWF:@"wiredtracker://%@/", object];
	}
	else if(tableColumn == _categoryTableColumn) {
		if(url)
			value = [NSSWF:@"wiredtracker://%@/%@", [url hostpair], object];
		else
			value = [NSSWF:@"wiredtracker://%@/%@", tracker, object];
	}
	
	if(value) {
		[[_config arrayForKey:@"tracker"] replaceObjectAtIndex:row withObject:value];

		[_trackersTableView reloadData];
		_touched = YES;
	}
}



- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	BOOL	enabled;
	
	enabled = [[WSDashboardController dashboardController] isAuthorized];
	[cell setEnabled:enabled];
	[cell setEditable:enabled];
}



- (void)tableViewSelectionDidChange:(NSNotification *)notification {
	[self _update];
}

@end
