//
//  NSString+Moon.m
//  Moon
//
//  Created by Casey Fleser on 1/22/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "NSString+Moon.h"

@implementation NSString (Moon)

- (NSString *) stringByExtractingCoinAddress
{
	NSScanner	*scanner = [NSScanner scannerWithString: self];
	NSString	*coinAddress = nil;
	
    [scanner scanUpToString: @"<" intoString: nil];
    [scanner scanString: @"<" intoString: nil];
    [scanner scanUpToString: @">" intoString: &coinAddress];
	
	return coinAddress;
}

@end
