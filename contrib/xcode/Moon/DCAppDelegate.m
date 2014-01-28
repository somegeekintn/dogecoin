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
#import "DCConsts.h"

#define	CORE_CONNECT	1

@implementation DCAppDelegate

- (void) applicationDidFinishLaunching: (NSNotification *) inNotification
{
#if CORE_CONNECT
	[[DCBridge sharedBridge] connect];
	[[DCDataManager sharedManager] startMonitor];
#else
	// useful for testing UI changes without actually firing up the core code
	double delayInSeconds = 0.5;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[[NSNotificationCenter defaultCenter] postNotificationName: DCNotification_InitComplete object: nil];
	});
#endif
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
