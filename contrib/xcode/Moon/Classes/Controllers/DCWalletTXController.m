//
//  DCWalletTXController.m
//  Moon
//
//  Created by Casey Fleser on 1/19/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCWalletTXController.h"
#import "DCTXInfoViewControlller.h"

@implementation DCWalletTXController

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	[self setSortDescriptors: @[ [NSSortDescriptor sortDescriptorWithKey: @"time" ascending: NO]]];
}

- (void) presentInfoFromView: (NSView *) inView
	withFrame: (NSRect) inFrame
	forArrangedItemIndex: (NSInteger) inIndex
{
	DCWalletTX		*walletTXItem = [[self arrangedObjects] objectAtIndex: inIndex];
	
	NSLog(@"%s", __PRETTY_FUNCTION__);
	if (walletTXItem != nil)
		[self.infoPopoverController presentPopoverFrom: inView withFrame: inFrame forWalletTX: walletTXItem];
}

- (NSImage *) infoImage
{
	return [NSImage imageNamed: @"tx_icon_info"];
}

@end
