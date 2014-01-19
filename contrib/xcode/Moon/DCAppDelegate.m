//
//  DCAppDelegate.m
//  Moon
//
//  Created by Casey Fleser on 1/13/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCAppDelegate.h"
#import "DCBridge.h"
#import "DCDataManager.h"

@implementation DCAppDelegate

- (void) applicationDidFinishLaunching: (NSNotification *) inNotification
{
	[[DCBridge sharedBridge] connect];
	[[DCDataManager sharedManager] startMonitor];
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
