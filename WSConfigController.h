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

@class WSConfig;

@interface WSConfigController : NSObject {
	IBOutlet NSPanel				*_certificatePanel;
	IBOutlet NSProgressIndicator	*_certificateProgressIndicator;

	IBOutlet NSTextField			*_nameTextField;
	IBOutlet NSTextField			*_portTextField;
	IBOutlet NSTextField			*_descriptionTextField;
	IBOutlet NSImageView			*_bannerImageView;
	IBOutlet NSButton				*_selectBannerButton;
	IBOutlet NSButton				*_clearBannerButton;

	IBOutlet NSTextField			*_totalDownloadsTextField;
	IBOutlet NSTextField			*_downloadSpeedTextField;
	IBOutlet NSTextField			*_totalUploadsTextField;
	IBOutlet NSTextField			*_uploadSpeedTextField;
	
	IBOutlet NSTextField			*_filesTextField;
	IBOutlet NSButton				*_selectFilesButton;

	IBOutlet NSButton				*_registerWithTrackersButton;
	IBOutlet NSTableView			*_trackersTableView;
	IBOutlet NSTableColumn			*_trackerTableColumn;
	IBOutlet NSTableColumn			*_categoryTableColumn;
	IBOutlet NSButton				*_addTrackerButton;
	IBOutlet NSButton				*_deleteTrackerButton;
	
	IBOutlet NSPopUpButton			*_indexPopUpButton;
	IBOutlet NSButton				*_limitNewsButton;
	IBOutlet NSTextField			*_limitNewsTextField;
	
	IBOutlet NSPopUpButton			*_userPopUpButton;
	IBOutlet NSPopUpButton			*_groupPopUpButton;
	
	IBOutlet NSButton				*_launchAtBootButton;

	IBOutlet NSMatrix				*_logMethodMatrix;
	IBOutlet NSPopUpButton			*_syslogPopUpButton;
	IBOutlet NSTextField			*_logFileTextField;
	IBOutlet NSButton				*_selectLogFileButton;
	IBOutlet NSButton				*_limitLogFileButton;
	IBOutlet NSTextField			*_limitLogFileTextField;
	
	WSConfig						*_config;
	
	NSImage							*_okImage, *_errorImage;

	BOOL							_requiresAuthorization;
	BOOL							_authorized;
	BOOL							_touched;
	BOOL							_logTouched;
}


#define WSServerPort				2000

#define WSConfigDidChange			@"WSConfigDidChange"
#define WSLogConfigDidChange		@"WSLogConfigDidChange"


+ (WSConfigController *)configController;

- (void)awakeFromController;
- (BOOL)saveFromController;
- (void)closeFromController;

- (WSConfig *)config;

- (IBAction)touch:(id)sender;
- (IBAction)banner:(id)sender;
- (IBAction)setBanner:(id)sender;
- (IBAction)clearBanner:(id)sender;
- (IBAction)selectFiles:(id)sender;
- (IBAction)addTracker:(id)sender;
- (IBAction)deleteTracker:(id)sender;
- (IBAction)selectLogFile:(id)sender;

@end
