//
//  DCWalletTXController.h
//  Moon
//
//  Created by Casey Fleser on 1/19/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@class DCTXInfoViewControlller;

@interface DCWalletTXController : NSArrayController

@property (nonatomic, strong) IBOutlet DCTXInfoViewControlller	*infoPopoverController;
@property (nonatomic, readonly) NSImage							*infoImage;

- (void)			presentInfoFromView: (NSView *) inView
						withFrame: (NSRect) inFrame
						forArrangedItemIndex: (NSInteger) inIndex;

@end
