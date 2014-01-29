//
//  DCAddrTableView.m
//  Moon
//
//  Created by Casey Fleser on 1/27/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCAddrTableView.h"
#import "DCAddressBook.h"

@implementation DCAddrTableView

- (void) copy: (id) inSender
{
	[self.addrBookController copySelection];
}

- (void) delete: (id) inSender
{
	[self.addrBookController deleteSelection];
}

- (void) keyDown: (NSEvent *) inEvent
{
	unichar		firstChar = [[inEvent characters] characterAtIndex: 0];

	if (firstChar == NSDeleteCharacter)
		[self delete: nil];
}
@end
