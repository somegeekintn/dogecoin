//
//  DCWalletTXTableView.h
//  Moon
//
//  Created by Casey Fleser on 2/9/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DCWalletTXController;

@interface DCWalletTXTableView : NSTableView

@property (nonatomic, strong) IBOutlet DCWalletTXController		*walletTXController;

@end
