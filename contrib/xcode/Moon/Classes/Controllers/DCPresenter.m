//
//  DCPresenter.m
//  Moon
//
//  Created by Casey Fleser on 1/25/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCPresenter.h"
#import "DCConsts.h"

@implementation DCPresenter

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	[self.mainWindow visualizeConstraints: nil];
	self.overlayView.hidden = NO;
	self.overlayView.layer.backgroundColor = [[[NSColor blackColor] colorWithAlphaComponent: 0.8] CGColor];
	[self.progressLabel setStringValue: @"Starting up..."];
	[self.progressIndicator setControlTint: NSGraphiteControlTint];
	[self.progressIndicator startAnimation: self];
	
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(initMessageNotification:) name: DCNotification_InitMessage object: nil];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(initCompleteNotification:) name: DCNotification_InitComplete object: nil];
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void) initMessageNotification: (NSNotification *) inNotification
{
	dispatch_async(dispatch_get_main_queue(), ^{
		NSDictionary		*userInfo = [inNotification userInfo];
		
		[self.progressLabel setStringValue: userInfo[@"message"]];
	});
}

- (void) initCompleteNotification: (NSNotification *) inNotification
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[NSAnimationContext runAnimationGroup: ^(NSAnimationContext *inContext){
			[inContext setDuration: 0.25];
			[[self.overlayView animator] setAlphaValue: 0.0];
		} completionHandler:^{
			// not much point keeping this stuff around anymore
			[self.overlayView removeFromSuperview];
			
			self.overlayView = nil;
			self.moonView = nil;
			self.progressLabel = nil;
			self.progressIndicator = nil;
			[self.toolbar setVisible: YES];
		}];
	});
}

@end
