//
//  DCBackgroundView.m
//  Dogecoin
//
//  Created by Casey Fleser on 1/19/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCBackgroundView.h"

@implementation DCBackgroundView

- (void) drawRect: (NSRect) inFrame
{
	NSImage		*backgroundImage = [NSImage imageNamed: @"moon"];
	NSRect		imageRect = [backgroundImage alignmentRect];
	NSPoint		destPoint;
	
	[[NSColor colorWithDeviceHue: 0.61 saturation: 0.04 brightness: 0.93 alpha: 1.0] set];
	NSRectFill(inFrame);

	destPoint = NSMakePoint(CGRectGetMaxX(self.bounds) - CGRectGetWidth(imageRect), 0.0);
	[backgroundImage drawAtPoint: destPoint fromRect: imageRect operation: NSCompositeSourceOver fraction: 0.25];
}

@end
