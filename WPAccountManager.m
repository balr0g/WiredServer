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
#import "WPError.h"

@implementation WPAccountManager

- (id)initWithUsersPath:(NSString *)usersPath groupsPath:(NSString *)groupsPath {
	self = [super init];
	
	_usersPath		= [usersPath retain];
	_groupsPath		= [groupsPath retain];
	
	_dateFormatter = [[WIDateFormatter alloc] init];
	[_dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[_dateFormatter setDateStyle:NSDateFormatterShortStyle];

	return self;
}



- (void)dealloc {
	[_usersPath release];
	[_groupsPath release];
	
	[_dateFormatter release];
	
	[super dealloc];
}



#pragma mark -

- (WPAccountStatus)hasUserAccountWithName:(NSString *)name password:(NSString **)password {
	NSEnumerator		*enumerator;
	NSArray				*accounts;
	NSDictionary		*account;
	NSString			*string;
	
	accounts = [NSArray arrayWithContentsOfFile:_usersPath];
	
	if(!accounts) {
		string = [NSString stringWithContentsOfFile:_usersPath];
		
		if(!string)
			return WPAccountFailed;
		
		return WPAccountOldStyle;
	}
	
	enumerator = [accounts objectEnumerator];
	
	while((account = [enumerator nextObject])) {
		if([[account objectForKey:@"wired.account.name"] isEqualToString:name]) {
			*password = [account objectForKey:@"wired.account.password"];
			
			return WPAccountOK;
		}
	}
	
	return WPAccountNotFound;
}



#pragma mark -

- (BOOL)setPassword:(NSString *)password forUserAccountWithName:(NSString *)name andWriteWithError:(WPError **)error {
	NSEnumerator			*enumerator;
	NSMutableArray			*newAccounts;
	NSArray					*accounts;
	NSMutableDictionary		*newAccount;
	NSDictionary			*account;
	
	accounts = [NSArray arrayWithContentsOfFile:_usersPath];
	
	if(!accounts || [accounts count] == 0) {
		*error = [WPError errorWithDomain:WPPreferencePaneErrorDomain code:WPPreferencePaneUsersReadFailed];
		
		return NO;
	}
	
	newAccounts	= [NSMutableArray array];
	enumerator	= [accounts objectEnumerator];
	
	while((account = [enumerator nextObject])) {
		if([[account objectForKey:@"wired.account.name"] isEqualToString:name]) {
			newAccount = [[account mutableCopy] autorelease];
			
			[newAccount setObject:[password SHA1] forKey:@"wired.account.password"];
			[newAccounts addObject:newAccount];
		} else {
			[newAccounts addObject:account];
		}
	}
	
	if(![newAccounts writeToFile:_usersPath atomically:YES]) {
		*error = [WPError errorWithDomain:WPPreferencePaneErrorDomain code:WPPreferencePaneUsersWriteFailed];
		
		return NO;
	}
	
	return YES;
}



- (BOOL)createNewAdminUserAccountWithName:(NSString *)name password:(NSString *)password andWriteWithError:(WPError **)error {
	NSEnumerator		*enumerator;
	NSMutableArray		*newAccounts;
	NSArray				*accounts;
	NSDictionary		*account, *newAccount;
	
	accounts = [NSArray arrayWithContentsOfFile:_usersPath];
	
	if(!accounts || [accounts count] == 0) {
		*error = [WPError errorWithDomain:WPPreferencePaneErrorDomain code:WPPreferencePaneUsersReadFailed];
		
		return NO;
	}

	newAccounts			= [NSMutableArray array];
	enumerator			= [accounts objectEnumerator];
	newAccount			= [NSDictionary dictionaryWithObjectsAndKeys:
		name,								@"wired.account.name",
		[password SHA1],					@"wired.account.password",
		@"",								@"wired.account.files",
		@"Administrator",					@"wired.account.full_name",
		@"",								@"wired.account.group",
		[NSArray array],					@"wired.account.groups",
		[NSNumber numberWithBool:YES],		@"wired.account.account.change_password",
		[NSNumber numberWithBool:YES],		@"wired.account.account.create_users",
		[NSNumber numberWithBool:YES],		@"wired.account.account.delete_users",
		[NSNumber numberWithBool:YES],		@"wired.account.account.edit_users",
		[NSNumber numberWithBool:YES],		@"wired.account.account.create_groups",
		[NSNumber numberWithBool:YES],		@"wired.account.account.delete_groups",
		[NSNumber numberWithBool:YES],		@"wired.account.account.edit_groups",
		[NSNumber numberWithBool:YES],		@"wired.account.account.list_accounts",
		[NSNumber numberWithBool:YES],		@"wired.account.account.raise_account_privileges",
		[NSNumber numberWithBool:YES],		@"wired.account.account.read_accounts",
		[NSNumber numberWithBool:YES],		@"wired.account.banlist.add_bans",
		[NSNumber numberWithBool:YES],		@"wired.account.banlist.delete_bans",
		[NSNumber numberWithBool:YES],		@"wired.account.banlist.get_bans",
		[NSNumber numberWithBool:YES],		@"wired.account.board.add_boards",
		[NSNumber numberWithBool:YES],		@"wired.account.board.add_posts",
		[NSNumber numberWithBool:YES],		@"wired.account.board.add_threads",
		[NSNumber numberWithBool:YES],		@"wired.account.board.delete_boards",
		[NSNumber numberWithBool:YES],		@"wired.account.board.delete_posts",
		[NSNumber numberWithBool:YES],		@"wired.account.board.delete_threads",
		[NSNumber numberWithBool:YES],		@"wired.account.board.edit_all_posts",
		[NSNumber numberWithBool:YES],		@"wired.account.board.edit_own_posts",
		[NSNumber numberWithBool:YES],		@"wired.account.board.move_boards",
		[NSNumber numberWithBool:YES],		@"wired.account.board.move_threads",
		[NSNumber numberWithBool:YES],		@"wired.account.board.read_boards",
		[NSNumber numberWithBool:YES],		@"wired.account.board.rename_boards",
		[NSNumber numberWithBool:YES],		@"wired.account.board.set_permissions",
		[NSNumber numberWithBool:YES],		@"wired.account.chat.create_chats",
		[NSNumber numberWithBool:YES],		@"wired.account.chat.set_topic",
		[NSNumber numberWithBool:YES],		@"wired.account.file.access_all_dropboxes",
		[NSNumber numberWithBool:YES],		@"wired.account.file.create_directories",
		[NSNumber numberWithBool:YES],		@"wired.account.file.create_links",
		[NSNumber numberWithBool:YES],		@"wired.account.file.delete_files",
		[NSNumber numberWithBool:YES],		@"wired.account.file.get_info",
		[NSNumber numberWithBool:YES],		@"wired.account.file.list_files",
		[NSNumber numberWithBool:YES],		@"wired.account.file.move_files",
		[NSNumber numberWithBool:YES],		@"wired.account.file.rename_files",
		[NSNumber numberWithBool:YES],		@"wired.account.file.set_comment",
		[NSNumber numberWithBool:YES],		@"wired.account.file.set_executable",
		[NSNumber numberWithBool:YES],		@"wired.account.file.set_permissions",
		[NSNumber numberWithBool:YES],		@"wired.account.file.set_type",
		[NSNumber numberWithBool:YES],		@"wired.account.log.view_log",
		[NSNumber numberWithBool:YES],		@"wired.account.message.broadcast",
		[NSNumber numberWithBool:YES],		@"wired.account.message.send_messages",
		[NSNumber numberWithBool:YES],		@"wired.account.settings.get_settings",
		[NSNumber numberWithBool:YES],		@"wired.account.settings.set_settings",
		[NSNumber numberWithBool:YES],		@"wired.account.tracker.list_servers",
		[NSNumber numberWithBool:YES],		@"wired.account.tracker.register_servers",
		[NSNumber numberWithBool:YES],		@"wired.account.transfer.download_files",
		[NSNumber numberWithBool:YES],		@"wired.account.transfer.upload_anywhere",
		[NSNumber numberWithBool:YES],		@"wired.account.transfer.upload_directories",
		[NSNumber numberWithBool:YES],		@"wired.account.transfer.upload_files",
		[NSNumber numberWithBool:YES],		@"wired.account.user.ban_users",
		[NSNumber numberWithBool:YES],		@"wired.account.user.cannot_be_disconnected",
		[NSNumber numberWithBool:NO],		@"wired.account.user.cannot_set_nick",
		[NSNumber numberWithBool:YES],		@"wired.account.user.get_info",
		[NSNumber numberWithBool:YES],		@"wired.account.user.get_users",
		[NSNumber numberWithBool:YES],		@"wired.account.user.kick_users",
		NULL];
		
	while((account = [enumerator nextObject])) {
		if(![[account objectForKey:@"wired.account.name"] isEqualToString:name])
			[newAccounts addObject:account];
	}
	
	[newAccounts addObject:newAccount];
	
	if(![newAccounts writeToFile:_usersPath atomically:YES]) {
		*error = [WPError errorWithDomain:WPPreferencePaneErrorDomain code:WPPreferencePaneUsersWriteFailed];
		
		return NO;
	}
	
	return YES;
}

@end
