//
//  DCAppDelegate.m
//  Moon
//
//  Created by Casey Fleser on 1/13/14.
//  Copyright (c) 2014 Dogecoin Developers. All rights reserved.
//

#import "DCAppDelegate.h"
#import "DCBridge.h"
#import "DCDataManager.h"

@implementation DCAppDelegate

- (void) applicationDidFinishLaunching: (NSNotification *) inNotification
{
	[[DCBridge sharedBridge] connect];
	[[DCDataManager sharedManager] startMonitor];

//	NSLog(@"block: %@", [[DCBridge sharedBridge] getBlockWithHash: @"01b01af74de2dee13dffd9b8d83372365072c971143a98d620cb033425f115a0"]);
//	
//	NSLog(@"applicationDidFinishLaunching");
//	NSLog(@"defaultContext %@", [DCDataManager sharedManager].defaultContext);
//	NSLog(@"info %@", [DCDataManager sharedManager].info);
}

- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication *) inSender
{
	NSApplicationTerminateReply		terminationReply = NSTerminateNow;
	
	if (![[DCDataManager sharedManager] prepareToQuit: inSender])
		terminationReply = NSTerminateCancel;

	if (terminationReply == NSTerminateNow)
		[[DCBridge sharedBridge] disconnect];

    return terminationReply;
}

@end
