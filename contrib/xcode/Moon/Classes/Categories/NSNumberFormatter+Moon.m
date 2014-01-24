//
//  NSNumberFormatter+Moon.m
//  Dogecoin
//
//  Created by Casey Fleser on 1/24/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "NSNumberFormatter+Moon.h"

@implementation NSNumberFormatter (Moon)

+ (NSNumberFormatter *) coinFormatter
{
	NSNumberFormatter	*coinFormatter = [[NSNumberFormatter alloc] init];

	[coinFormatter setFormat: @"Ɖ#,##0.00######;Ɖ-#,##0.00######"];
	[coinFormatter setMinimumFractionDigits: 2];
	[coinFormatter setMaximumFractionDigits: 8];

	return coinFormatter;
}

@end
