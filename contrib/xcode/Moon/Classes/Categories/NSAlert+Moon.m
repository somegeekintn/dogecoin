//
//  NSAlert+Moon.m
//  Dogecoin
//
//  Created by Casey Fleser on 1/24/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "NSAlert+Moon.h"

@implementation NSAlert (Moon)

+ (NSInteger) presentModalAlertWithTitle: (NSString *) inTitle
	defaultButton: (NSString *) inDefaultText
	alternateButton: (NSString *) inAlternateText
	infoText: (NSString *) inInfoText
	style: (NSAlertStyle) inStyle
{
	__block NSInteger		result;
	dispatch_block_t		alertBlock;
	
	alertBlock = ^{
		NSAlert		*alert = [[NSAlert alloc] init];
		
		[alert setMessageText: inTitle];
		[alert setInformativeText: inInfoText];
		[alert addButtonWithTitle: inDefaultText];
		if (inAlternateText != nil)
			[alert addButtonWithTitle: inAlternateText];
		[alert setAlertStyle: inStyle];
		result = [alert runModal];
	};
	
	if ([NSThread isMainThread]) {
		alertBlock();
	}
	else {
		dispatch_sync(dispatch_get_main_queue(), alertBlock);
	}
	
	return result;
}

@end
