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

#import "WSLogController.h"
#import "WSConfigController.h"
#import "WSSettings.h"

static WSLogController		*sharedLogController;


@interface WSLogController(Private)

- (void)_flush;
- (void)_openLog;
- (void)_closeLog;

@end


@implementation WSLogController(Private)

- (void)_flush {
	[_buffer removeSurroundingWhitespace];
	[[[_textView textStorage] mutableString] appendString:_buffer];
	[_buffer setString:@""];
	
	[_textView scrollToBottom];
}



- (void)_openLog {
	NSPipe		*pipe;
	NSString	*path, *mark;

	[self _closeLog];
	
	switch([WSSettings intForKey:WSLogMethod]) {
		case WSLogMethodSyslog:
		default:
			[_filter release];
			_filter = [@"wired[" retain];

			path = [WSSettings objectForKey:WSSyslogFile];
			break;
			
		case WSLogMethodFile:
			[_filter release];
			_filter = NULL;
			
			path = WSExpandWiredPath([WSSettings objectForKey:WSLogFile]);
			break;
	}

	mark = [NSSWF:WSLS(@"===== Displaying %@ =====", @"Log header (log)"), path];
	mark = [mark stringByAppendingString:@"\n"];
	[_textView setString:mark];
	[_textView setFont:[NSFont fontWithName:@"Monaco" size:9.0]];
	
	pipe = [NSPipe pipe];
	_fileHandle = [pipe fileHandleForReading];
	
	if(fcntl([_fileHandle fileDescriptor], F_SETFL, O_NONBLOCK) < 0)
		NSLog(@"fnctl: %s", strerror(errno));
	
	_tail = [[NSTask alloc] init];
	[_tail setLaunchPath:@"/usr/bin/tail"];
	[_tail setArguments:[NSArray arrayWithObjects:@"-100", @"-f", path, NULL]];
	[_tail setStandardOutput:pipe];
	[_tail setStandardError:pipe];
	[_tail launch];
}



- (void)_closeLog {
	[_tail terminate];
	[_tail release];
	_tail = NULL;
}

@end


@implementation WSLogController

+ (WSLogController *)logController {
	return sharedLogController;
}




- (id)init {
	self = [super init];
	
	sharedLogController = self;
	_buffer = [[NSMutableString alloc] initWithCapacity:10000];
	
	_dateFormatter = [[WIDateFormatter alloc] init];
	[_dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
	[_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	
	return self;
}



- (void)awakeFromNib {
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(applicationWillTerminate:)
			   name:NSApplicationWillTerminateNotification
			 object:NULL];
	
	[[NSNotificationCenter defaultCenter]
		addObserver:self
		   selector:@selector(logConfigDidChange:)
			   name:WSLogConfigDidChange
			 object:NULL];
}



- (void)awakeFromController {
	_timer = [NSTimer scheduledTimerWithTimeInterval:0.33
											  target:self
											selector:@selector(logTimer:)
											userInfo:NULL
											 repeats:YES];
	[_timer retain];

	[self _openLog];
}



- (void)closeFromController {
	[_timer invalidate];
	[_timer release];
	
	[self _closeLog];
}



- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[_path release];
	[_filter release];
	[_userFilter release];
	
	[_dateFormatter release];
	
	[super dealloc];
}
	


#pragma mark -

- (void)applicationWillTerminate:(NSNotification *)notification {
	[self _closeLog];
}



- (void)logConfigDidChange:(NSNotification *)notification {
	[self _openLog];
}



#pragma mark -

- (void)logTimer:(NSTimer *)timer {
	NSString		*string;
	FILE			*fp;
	char			buffer[BUFSIZ];
	
	if(_fileHandle) {
		fp = fdopen([_fileHandle fileDescriptor], "r");
		
		if(fp) {
			while(fgets(buffer, sizeof(buffer), fp) != NULL) {
				string = [NSString stringWithUTF8String:buffer];

				if([_filter length] == 0 && [_userFilter length] == 0) {
					[_buffer appendString:string];
				} else {
					if([_filter length] > 0) {
						if([string rangeOfString:_filter options:NSCaseInsensitiveSearch].location == NSNotFound)
							continue;
					}
					
					if([_userFilter length] > 0) {
						if([string rangeOfString:_userFilter options:NSCaseInsensitiveSearch].location == NSNotFound)
							continue;
					}
						
					[_buffer appendString:string];
				}
			}
			
			if([_buffer length] > 0)
				[self _flush];
		}
	}
}



#pragma mark -

- (void)log:(NSString *)string {
	[_buffer appendString:string];
	
	[self _flush];
}

@end
