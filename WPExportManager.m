/* $Id$ */

/*
 *  Copyright (c) 2009 Axel Andersson
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

#import "WPError.h"
#import "WPExportManager.h"
#import "WPWiredManager.h"

#define WPExportManagerBanlist				@"WPBanlist"
#define WPExportManagerBanner				@"WPBanner"
#define WPExportManagerBoard				@"WPBoard"
#define WPExportManagerConfig				@"WPConfig"
#define WPExportManagerGroups				@"WPGroups"
#define WPExportManagerUsers				@"WPUsers"


@implementation WPExportManager

- (id)initWithWiredManager:(WPWiredManager *)wiredManager {
	self = [super init];
	
	_wiredManager = [wiredManager retain];
	
	return self;
}



- (void)dealloc {
	[_wiredManager release];
	
	[super dealloc];
}



#pragma mark -

- (BOOL)exportToFile:(NSString *)file error:(WPError **)error {
	NSEnumerator			*enumerator;
	NSMutableDictionary		*dictionary, *files;
	NSTask					*task;
	NSData					*data;
	NSString				*string, *key, *value, *zipfile;
	
	dictionary = [NSMutableDictionary dictionary];

	files = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		@"banlist",			WPExportManagerBanlist,
		@"etc/wired.conf",	WPExportManagerConfig,
		@"groups",			WPExportManagerGroups,
		@"users",			WPExportManagerUsers,
		NULL];
	
	enumerator = [files keyEnumerator];
	
	while((key = [enumerator nextObject])) {
		value	= [files objectForKey:key];
		string	= [NSString stringWithContentsOfFile:[_wiredManager pathForFile:value]
											encoding:NSUTF8StringEncoding
											   error:(NSError **) error];
		
		if(!string)
			return NO;
		
		[dictionary setObject:string forKey:key];
	}
	
	if(![[NSFileManager defaultManager] changeCurrentDirectoryPath:[_wiredManager rootPath]]) {
		*error = [WPError errorWithDomain:WPPreferencePaneErrorDomain code:WPPreferencePaneExportFailed];
		
		return NO;
	}
	
	files = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		@"board",			WPExportManagerBoard,
		NULL];
	
	if([[NSFileManager defaultManager] fileExistsAtPath:@"banner.png"])
		[files setObject:@"banner.png" forKey:WPExportManagerBanner];
	
	enumerator = [files keyEnumerator];
	
	while((key = [enumerator nextObject])) {
		value		= [files objectForKey:key];
		zipfile		= [NSFileManager temporaryPathWithPrefix:@"WiredSettings"];
		task		= [NSTask launchedTaskWithLaunchPath:@"/usr/bin/zip"
										 arguments:[NSArray arrayWithObjects:
														@"-r",
														zipfile,
														value,
														NULL]];
		
		[task waitUntilExit];
		
		if([task terminationStatus] != 0) {
			*error = [WPError errorWithDomain:WPPreferencePaneErrorDomain code:WPPreferencePaneExportFailed];
			
			return NO;
		}
		
		data = [NSData dataWithContentsOfFile:[zipfile stringByAppendingPathExtension:@"zip"]
									  options:0
										error:error];
		
		if(!data)
			return NO;
		
		[dictionary setObject:data forKey:key];
	}
	
	if(![dictionary writeToFile:file atomically:YES]) {
		*error = [WPError errorWithDomain:WPPreferencePaneErrorDomain code:WPPreferencePaneExportFailed];
		
		return NO;
	}
	
	return YES;
}



- (BOOL)importFromFile:(NSString *)file error:(WPError **)error {
	NSEnumerator		*enumerator;
	NSDictionary		*dictionary, *files;
	NSTask				*task;
	NSData				*data;
	NSString			*string, *key, *value, *zipfile;
	
	dictionary = [NSDictionary dictionaryWithContentsOfFile:file];
	
	if(!dictionary) {
		*error = [WPError errorWithDomain:WPPreferencePaneErrorDomain code:WPPreferencePaneImportFailed];
		
		return NO;
	}
	
	files = [NSDictionary dictionaryWithObjectsAndKeys:
		@"banlist",			WPExportManagerBanlist,
		@"etc/wired.conf",	WPExportManagerConfig,
		@"groups",			WPExportManagerGroups,
		@"users",			WPExportManagerUsers,
		NULL];
	
	enumerator = [files keyEnumerator];

	while((key = [enumerator nextObject])) {
		value	= [files objectForKey:key];
		string	= [dictionary objectForKey:key];
		
		if(![string writeToFile:[_wiredManager pathForFile:value]
					 atomically:YES
					   encoding:NSUTF8StringEncoding
						  error:(NSError **) error]) {
			return NO;
		}
	}
	
	if(![[NSFileManager defaultManager] changeCurrentDirectoryPath:[_wiredManager rootPath]]) {
		*error = [WPError errorWithDomain:WPPreferencePaneErrorDomain code:WPPreferencePaneImportFailed];
		
		return NO;
	}

	files = [NSDictionary dictionaryWithObjectsAndKeys:
		@"board",			WPExportManagerBoard,
		@"banner.png",		WPExportManagerBanner,
		NULL];
	
	enumerator = [files keyEnumerator];

	while((key = [enumerator nextObject])) {
		value = [files objectForKey:key];
		
		if([[NSFileManager defaultManager] fileExistsAtPath:[_wiredManager pathForFile:value]]) {
			if(![[NSFileManager defaultManager] removeFileAtPath:[_wiredManager pathForFile:value] handler:NULL]) {
				*error = [WPError errorWithDomain:WPPreferencePaneErrorDomain code:WPPreferencePaneImportFailed];
				
				return NO;
			}
		}
		
		data = [dictionary objectForKey:key];
		
		if(!data)
			continue;
		
		zipfile = [NSFileManager temporaryPathWithPrefix:@"WiredSettings"];
		
		if(![data writeToFile:zipfile options:0 error:error])
			return NO;
		
		task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/unzip"
										arguments:[NSArray arrayWithObjects:
													@"-o",
													zipfile,
													NULL]];
		
		[task waitUntilExit];

		if([task terminationStatus] != 0) {
			*error = [WPError errorWithDomain:WPPreferencePaneErrorDomain code:WPPreferencePaneImportFailed];
			
			return NO;
		}
	}
	
	return YES;
}

@end
