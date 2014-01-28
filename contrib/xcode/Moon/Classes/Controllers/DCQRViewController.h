//
//  DCQRViewController.h
//  Moon
//
//  Created by Casey Fleser on 1/26/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DCQRViewController;

@protocol DCQRDelegate <NSObject>

- (void)			didReadCode: (NSString *) inQRCode
						withQRCodeController: (DCQRViewController *) inController;

@end

@interface DCQRViewController : NSViewController <NSPopoverDelegate>

- (void)			presentPopoverFrom: (NSView *) inView
						withQRDelegate: (id <DCQRDelegate>) inQRDelegate;
- (void)			dismissPopover: (id) inSender;

@end
