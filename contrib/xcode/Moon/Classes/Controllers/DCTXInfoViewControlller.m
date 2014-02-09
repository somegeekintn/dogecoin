//
//  DCTXInfoViewControlller.m
//  Moon
//
//  Created by Casey Fleser on 2/9/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCTXInfoViewControlller.h"

@interface DCTXInfoViewControlller ()

@property (nonatomic, strong) NSPopover			*infoPopover;

@end

@implementation DCTXInfoViewControlller

- (void) presentPopoverFrom: (NSView *) inView
	withFrame: (NSRect) inFrame
	forWalletTX: (DCWalletTX *) inWalletTX;
{
	self.walletTX = inWalletTX;
    [self.infoPopover showRelativeToRect: inFrame ofView: inView preferredEdge: CGRectMaxYEdge];
}

- (void) dismissPopover: (id) inSender
{
	[self.infoPopover performClose: inSender];
}

#pragma mark - NSPopoverDelegate

- (void) popoverWillShow: (NSNotification *) inNotification
{
}

- (void) popoverDidClose: (NSNotification *) inNotification
{
}

#pragma mark - Setters / Getters

- (NSPopover *) infoPopover
{
    if (_infoPopover == nil) {
        // create and setup our popover
        _infoPopover = [[NSPopover alloc] init];
		_infoPopover.contentViewController = self;
        _infoPopover.animates = YES;
        _infoPopover.behavior = NSPopoverBehaviorTransient;
        _infoPopover.delegate = self;
    }

	return _infoPopover;
}

@end
