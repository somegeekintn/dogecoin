//
//  DCTransformer_NumberToColor.m
//  Dogecoin
//
//  Created by Casey Fleser on 1/19/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCTransformer_NumberToColor.h"

@implementation DCTransformer_NumberToColor

+ (Class) transformedValueClass
{
	return [NSColor class];
}

+ (BOOL) allowsReverseTransformation
{
	return NO;
}

- (id) transformedValue: (id) inNumberValue
{
	return [@(0) compare: inNumberValue] == NSOrderedDescending ? [NSColor redColor] : [NSColor blackColor];
}

@end
