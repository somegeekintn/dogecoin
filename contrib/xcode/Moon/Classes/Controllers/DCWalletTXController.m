//
//  DCWalletTXController.m
//  Moon
//
//  Created by Casey Fleser on 1/19/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCWalletTXController.h"

@implementation DCWalletTXController

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	[self setSortDescriptors: @[ [NSSortDescriptor sortDescriptorWithKey: @"time" ascending: NO]]];
}

@end
