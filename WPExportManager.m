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

// TODO: serialize boards/ directory in some way

#define WPExportManagerBanlist				@"WPBanlist"
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
	NSMutableDictionary		*dictionary;
	NSDictionary			*files;
	NSString				*string, *key, *value;
	
	dictionary = [NSMutableDictionary dictionary];

	files = [NSDictionary dictionaryWithObjectsAndKeys:
		@"banlist",			WPExportManagerBanlist,
		@"etc/wired.conf",	WPExportManagerConfig,
		@"groups",			WPExportManagerGroups,
		@"users",			WPExportManagerUsers,
		NULL];
	
	enumerator	= [files keyEnumerator];
	
	while((key = [enumerator nextObject])) {
		value	= [files objectForKey:key];
		string	= [NSString stringWithContentsOfFile:[_wiredManager pathForFile:value]
											encoding:NSUTF8StringEncoding
											   error:(NSError **) error];
		
		if(!string)
			return NO;
		
		[dictionary setObject:string forKey:key];
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
	NSString			*string, *key, *value;
	
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
	
	return YES;
}

@end
