//
//  DCAddrTableView.h
//  Moon
//
//  Created by Casey Fleser on 1/27/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DCAddressBook;

@interface DCAddrTableView : NSTableView

@property (nonatomic, weak) IBOutlet DCAddressBook	*addrBookController;

@end
