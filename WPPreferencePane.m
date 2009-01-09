/* $Id$ */

/*
 *  Copyright (c) 2003-2009 Axel Andersson
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

#import "WPAccountManager.h"
#import "WPConfigManager.h"
#import "WPLogManager.h"
#import "WPPortChecker.h"
#import "WPPreferencePane.h"
#import "WPSettings.h"
#import "WPWiredManager.h"

@interface WPPreferencePane(Private)

- (void)_updateInstallationStatus;
- (void)_updateRunningStatus;
- (void)_updateSettings;
- (void)_updatePortStatus;

- (void)_install;
- (void)_uninstall;

@end


@implementation WPPreferencePane(Private)

- (void)_updateInstallationStatus {
	NSString		*version;
	
	version = [_wiredManager installedVersion];
	
	if(version)
		[_versionTextField setStringValue:version];
	else
		[_versionTextField setStringValue:WPLS(@"Wired is not installed", @"Installed version notice")];
	
	if([_wiredManager isInstalled]) {
		[_installButton setTitle:WPLS(@"Uninstall\u2026", @"Uninstall button title")];
		[_installButton setAction:@selector(uninstall:)];
	} else {
		[_installButton setTitle:WPLS(@"Install", @"Install button title")];
		[_installButton setAction:@selector(install:)];
	}
}



- (void)_updateRunningStatus {
	NSString		*status;
	
	if(![_wiredManager isInstalled]) {
		status = WPLS(@"Wired Server not found", @"Server status");
	}
	else if(![_wiredManager isRunning]) {
		status = WPLS(@"Wired Server is not running", @"Server status");
	}
	else if(_installDate && [_installDate compare:[_wiredManager launchDate]] == NSOrderedDescending) {
		status = [NSSWF:WPLS(@"A previous version of Wired Server is running since %@", @"Server status"),
			[_dateFormatter stringFromDate:[_wiredManager launchDate]]];
	}
	else {
		status = [NSSWF:WPLS(@"Wired Server is running since %@", @"Server status"),
			[_dateFormatter stringFromDate:[_wiredManager launchDate]]];
	}
	
	[_statusTextField setStringValue:status];
	
	if(![_wiredManager isInstalled]) {
		[_statusImageView setImage:_grayDropImage];
		
		[_startButton setTitle:WPLS(@"Start", @"Start button")];
		[_startButton setEnabled:NO];
	}
	else if(![_wiredManager isRunning]) {
		[_statusImageView setImage:_redDropImage];

		[_startButton setTitle:WPLS(@"Start", @"Start button")];
		[_startButton setEnabled:YES];
		[_startButton setAction:@selector(start:)];
	}
	else {
		[_statusImageView setImage:_greenDropImage];

		[_startButton setTitle:WPLS(@"Stop", @"Stop button")];
		[_startButton setEnabled:YES];
		[_startButton setAction:@selector(stop:)];
	}
	
	[_launchAutomaticallyButton setState:[_wiredManager launchesAutomatically]];
}



- (void)_updateSettings {
	NSImage			*image;
	NSString		*string, *password;
	
	string = [_configManager stringForConfigWithName:@"files"];
	
	if(string) {
		image = [[NSWorkspace sharedWorkspace] iconForFile:string];
		
		[image setSize:NSMakeSize(16.0, 16.0)];
		
		[_filesMenuItem setTitle:[[NSFileManager defaultManager] displayNameAtPath:string]];
		[_filesMenuItem setImage:image];
		[_filesMenuItem setRepresentedObject:string];
	}
	
	string = [_configManager stringForConfigWithName:@"port"];
	
	if(string)
		[_portTextField setStringValue:string];
	
	if([_accountManager hasUserAccountWithName:@"admin" password:&password]) {
		if([password length] == 0 || [password isEqualToString:[@"" SHA1]]) {
			[_accountStatusImageView setImage:_redDropImage];
			[_accountStatusTextField setStringValue:WPLS(@"Account with name \u201cadmin\u201d has no password set", @"Account status")];
		} else {
			[_accountStatusImageView setImage:_greenDropImage];
			[_accountStatusTextField setStringValue:WPLS(@"Account with name \u201cadmin\u201d has a password set", @"Account status")];
		}
	} else {
		[_accountStatusImageView setImage:_grayDropImage];
		[_accountStatusTextField setStringValue:WPLS(@"No account with name \u201cadmin\u201d found", @"Account status")];
	}
}



- (void)_updatePortStatus {
	if(![_wiredManager isInstalled]) {
		[_portStatusImageView setImage:_grayDropImage];
		[_portStatusTextField setStringValue:WPLS(@"Wired Server not found", @"Port status")];
	}
	else if(![_wiredManager isRunning]) {
		[_portStatusImageView setImage:_grayDropImage];
		[_portStatusTextField setStringValue:WPLS(@"Wired Server is not running", @"Port status")];
	}
	else {
		switch(_portCheckerStatus) {
			case WPPortCheckerUnknown:
				[_portStatusImageView setImage:_grayDropImage];
				[_portStatusTextField setStringValue:WPLS(@"Checking port status\u2026", @"Port status")];
				break;

			case WPPortCheckerOpen:
				[_portStatusImageView setImage:_greenDropImage];
				[_portStatusTextField setStringValue:[NSSWF:WPLS(@"Port %u is open", @"Port status"), _portCheckerPort]];
				break;
				
			case WPPortCheckerClosed:
				[_portStatusImageView setImage:_redDropImage];
				[_portStatusTextField setStringValue:[NSSWF:WPLS(@"Port %u is closed", @"Port status"), _portCheckerPort]];
				break;
				
			case WPPortCheckerFiltered:
				[_portStatusImageView setImage:_redDropImage];
				[_portStatusTextField setStringValue:[NSSWF:WPLS(@"Port %u is filtered", @"Port status"), _portCheckerPort]];
				break;
				
			case WPPortCheckerFailed:
				[_portStatusImageView setImage:_redDropImage];
				[_portStatusTextField setStringValue:WPLS(@"Port check failed", @"Port status")];
				break;
		}
	}
}



#pragma mark -

- (void)_install {
	WPError		*error;
	
	[_progressIndicator startAnimation:self];
	
	if([_wiredManager installWithError:&error]) {
		[_installDate release];
		_installDate = [[NSDate date] retain];
		
		[_logManager startReadingFromLog];
	} else {
		[[error alert] beginSheetModalForWindow:[_installButton window]];
	}
	
	[self _updateInstallationStatus];
	[self _updateRunningStatus];
	[self _updatePortStatus];

	[_progressIndicator stopAnimation:self];
}



- (void)_uninstall {
	WPError		*error;
	
	[_progressIndicator startAnimation:self];
	
	if([_wiredManager uninstallWithError:&error])
		[_logManager stopReadingFromLog];
	else
		[[error alert] beginSheetModalForWindow:[_installButton window]];
	
	[self _updateInstallationStatus];
	[self _updateRunningStatus];
	[self _updatePortStatus];

	[_progressIndicator stopAnimation:self];
}

@end



@implementation WPPreferencePane

+ (void)load {
	[WPSettings loadWithIdentifier:[[self bundle] bundleIdentifier]];
}



- (void)mainViewDidLoad {
	_wiredManager	= [[WPWiredManager alloc] init];
	_accountManager	= [[WPAccountManager alloc] initWithUsersPath:[_wiredManager pathForFile:@"users"]
													   groupsPath:[_wiredManager pathForFile:@"groups"]];
	_configManager	= [[WPConfigManager alloc] initWithConfigPath:[_wiredManager pathForFile:@"etc/wired.conf"]];
	_logManager		= [[WPLogManager alloc] initWithLogPath:[_wiredManager pathForFile:@"wired.log"]];
	
	_portChecker	= [[WPPortChecker alloc] initWithDelegate:self];
	
	_updater = [[SUUpdater updaterForBundle:[self bundle]] retain];
	[_updater setDelegate:self];
	[_updater setSendsSystemProfile:YES];
	[_updater setAutomaticallyChecksForUpdates:NO];
	
#ifdef WPConfigurationRelease
	[_updater setFeedURL:[NSURL URLWithString:@"http://www.zankasoftware.com/sparkle/sparkle.pl?file=wiredserverp7.xml"]];
#else
	[_updater setFeedURL:[NSURL URLWithString:@"http://www.zankasoftware.com/sparkle/sparkle.pl?file=wiredserverp7-nightly.xml"]];
#endif
	
	_greenDropImage	= [[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForResource:@"GreenDrop" ofType:@"tiff"]];
	_redDropImage	= [[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForResource:@"RedDrop" ofType:@"tiff"]];
	_grayDropImage	= [[NSImage alloc] initWithContentsOfFile:[[self bundle] pathForResource:@"GrayDrop" ofType:@"tiff"]];

	_dateFormatter = [[WIDateFormatter alloc] init];
	[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[_dateFormatter setNaturalLanguageStyle:WIDateFormatterNormalNaturalLanguageStyle];
	
	_logAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:
		[NSFont fontWithName:@"Monaco" size:9.0],
			NSFontAttributeName,
		NULL];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(wiredStatusDidChange:)
			   name:WPWiredStatusDidChangeNotification];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(logLinesDidChange:)
			   name:WPLogLinesDidChangeNotification];
}



- (void)willSelect {
	if(![_wiredManager isInstalled] || ![[_wiredManager installedVersion] isEqualToString:[_wiredManager packagedVersion]])
		[self _install];
	
	[self _updateInstallationStatus];
	[self _updateRunningStatus];
	[self _updateSettings];
	[self _updatePortStatus];
	
	[_updater resetUpdateCycle];
	[_updater checkForUpdatesInBackground];
	
	[_logManager startReadingFromLog];
}



- (void)willUnselect {
}



#pragma mark -

- (void)wiredStatusDidChange:(NSNotification *)notification {
	[self _updateRunningStatus];
	
	if([_wiredManager isRunning]) {
		_portCheckerStatus = WPPortCheckerUnknown;
		
		[_portChecker checkStatusForPort:[_portTextField intValue]];
	}

	[self _updatePortStatus];
}



- (void)logLinesDidChange:(NSNotification *)notification {
	[_logTableView reloadData];
	[_logTableView scrollRowToVisible:[[_logManager logLines] count] - 1];
}



- (void)portChecker:(WPPortChecker *)portChecker didReceiveStatus:(WPPortCheckerStatus)status forPort:(NSUInteger)port {
	_portCheckerStatus	= status;
	_portCheckerPort	= port;
	
	[self _updatePortStatus];
}



- (BOOL)updaterShouldPromptForPermissionToCheckForUpdates:(SUUpdater *)updater {
	return NO;
}



#pragma mark -

- (IBAction)install:(id)sender {
	[self _install];
}



- (IBAction)uninstall:(id)sender {
	NSAlert		*alert;
	
	alert = [NSAlert alertWithMessageText:WPLS(@"Are you sure you want to uninstall Wired Server?", @"Uninstall dialog title")
							defaultButton:WPLS(@"Cancel", @"Uninstall dialog button title")
						  alternateButton:WPLS(@"Uninstall", @"Uninstall dialog button title")
							  otherButton:NULL
				informativeTextWithFormat:WPLS(@"All your settings, accounts and other server data will be lost.", @"Uninstall dialog description")];
	
	[alert beginSheetModalForWindow:[_installButton window]
					  modalDelegate:self
					 didEndSelector:@selector(uninstallAlertDidEnd:returnCode:contextInfo:)
						contextInfo:NULL];
}



- (void)uninstallAlertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	if(returnCode == NSAlertAlternateReturn)
		[self performSelector:@selector(_uninstall) afterDelay:0.1];
}

	 
	 
- (IBAction)checkForUpdate:(id)sender {
	[_updater checkForUpdates:sender];
}



#pragma mark -

- (IBAction)start:(id)sender {
	WPError		*error;
	
	if(![_wiredManager startWithError:&error])
		[[error alert] beginSheetModalForWindow:[_startButton window]];
	
	[self _updateRunningStatus];
}



- (IBAction)stop:(id)sender {
	WPError		*error;
	
	if(![_wiredManager stopWithError:&error])
		[[error alert] beginSheetModalForWindow:[_startButton window]];
	
	[self _updateRunningStatus];
}



- (IBAction)launchAutomatically:(id)sender {
	[_wiredManager setLaunchesAutomatically:[_launchAutomaticallyButton state]];
	
	[self _updateRunningStatus];
}



#pragma mark -

- (IBAction)openLog:(id)sender {
	[[NSWorkspace sharedWorkspace] openFile:[_wiredManager pathForFile:@"wired.log"]];
}



#pragma mark -

- (IBAction)other:(id)sender {
	NSOpenPanel		*openPanel;
	
	openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:NO];
	[openPanel setCanChooseDirectories:YES];
	[openPanel setTitle:WPLS(@"Select Files", @"Files dialog title")];
	[openPanel setPrompt:WPLS(@"Select", @"Files dialog button title")];
	[openPanel beginSheetForDirectory:[_filesMenuItem representedObject]
								 file:NULL
					   modalForWindow:[_filesPopUpButton window]
						modalDelegate:self
					   didEndSelector:@selector(otherOpenPanelDidEnd:returnCode:contextInfo:)
						  contextInfo:NULL];
}


- (void)otherOpenPanelDidEnd:(NSOpenPanel *)openPanel returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	WPError		*error;
	
	if(returnCode == NSOKButton) {
		if([_configManager setString:[openPanel filename] forConfigWithName:@"files" andWriteWithError:&error])
			[_wiredManager sendServerSIGHUP];
		else
			[[error alert] beginSheetModalForWindow:[_filesPopUpButton window]];
		
		[self _updateSettings];
	}
	
	[_filesPopUpButton selectItem:_filesMenuItem];
}



#pragma mark -

- (IBAction)port:(id)sender {
	WPError		*error;
	
	if(![_configManager setString:[_portTextField stringValue] forConfigWithName:@"port" andWriteWithError:&error])
		[[error alert] beginSheetModalForWindow:[_portTextField window]];
	
	[self _updateSettings];
}



- (IBAction)automaticallyMapPort:(id)sender {
}



#pragma mark -

- (IBAction)setPasswordForAdmin:(id)sender {
	[_newPasswordTextField setStringValue:@""];
	[_verifyPasswordTextField setStringValue:@""];
	[_passwordMismatchTextField setHidden:YES];

	[_passwordPanel makeFirstResponder:_newPasswordTextField];

	[NSApp beginSheet:_passwordPanel
	   modalForWindow:[_setPasswordForAdminButton window]
		modalDelegate:self
	   didEndSelector:@selector(setPasswordForAdminPanelDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}



- (void)setPasswordForAdminPanelDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	WPError		*error;
	
	[_passwordPanel close];

	if(returnCode == NSOKButton) {
		if(![_accountManager setPassword:[_newPasswordTextField stringValue]
				  forUserAccountWithName:@"admin"
					   andWriteWithError:&error]) {
			[[error alert] beginSheetModalForWindow:[_setPasswordForAdminButton window]];
		}
		
		[self _updateSettings];
	}
}



- (IBAction)createNewAdminUser:(id)sender {
	[_newPasswordTextField setStringValue:@""];
	[_verifyPasswordTextField setStringValue:@""];
	[_passwordMismatchTextField setHidden:YES];
	
	[_passwordPanel makeFirstResponder:_newPasswordTextField];
	
	[NSApp beginSheet:_passwordPanel
	   modalForWindow:[_createNewAdminUserButton window]
		modalDelegate:self
	   didEndSelector:@selector(createNewAdminUserPanelDidEnd:returnCode:contextInfo:)
		  contextInfo:NULL];
}



- (void)createNewAdminUserPanelDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
	WPError		*error;
	
	[_passwordPanel close];

	if(returnCode == NSOKButton) {
		if(![_accountManager createNewAdminUserAccountWithName:@"admin"
													  password:[_newPasswordTextField stringValue]
											 andWriteWithError:&error]) {
			[[error alert] beginSheetModalForWindow:[_setPasswordForAdminButton window]];
		}
		
		[self _updateSettings];
	}
}



- (IBAction)submitPasswordSheet:(id)sender {
	NSString		*newPassword, *verifyPassword;
	
	newPassword		= [_newPasswordTextField stringValue];
	verifyPassword	= [_verifyPasswordTextField stringValue];
	
	if([newPassword isEqualToString:verifyPassword]) {
		[self submitSheet:sender];
	} else {
		NSBeep();
		
		[_passwordMismatchTextField setHidden:NO];
	}
}



#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
	return [[_logManager logLines] count];
}



- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
	return [NSAttributedString attributedStringWithString:[[_logManager logLines] objectAtIndex:row]
											   attributes:_logAttributes];
}



- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row {
	NSSize			size;
	NSUInteger		rows = 0;
	
	size = [[[_logManager logLines] objectAtIndex:row] sizeWithAttributes:_logAttributes];
	
	while(size.width > [_logTableColumn width]) {
		size.width -= [_logTableColumn width];
		rows++;
	}
	
	return [tableView rowHeight] + (rows * 12.0);
}

@end
