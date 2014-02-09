//
//  DCTXInfoViewControlller.h
//  Moon
//
//  Created by Casey Fleser on 2/9/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DCWalletTX;

@interface DCTXInfoViewControlller : NSViewController <NSPopoverDelegate>

- (void)				presentPopoverFrom: (NSView *) inView
							withFrame: (NSRect) inFrame
							forWalletTX: (DCWalletTX *) inWalletTX;

- (void)				dismissPopover: (id) inSender;

@property (nonatomic, strong) DCWalletTX		*walletTX;

@end

