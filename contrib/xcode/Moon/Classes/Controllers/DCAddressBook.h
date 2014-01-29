//
//  DCAddressBook.h
//  Moon
//
//  Created by Casey Fleser on 1/26/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DCAddressBook : NSArrayController

- (void)					copySelection;
- (void)					deleteSelection;

- (IBAction)				showAddressBook: (id) inSender;
- (IBAction)				handleAddressSegment: (id) inSender;
- (IBAction)				handleNewAddress: (id) inSender;

@property (nonatomic, weak) IBOutlet NSWindow				*addrBookWindow;
@property (nonatomic, weak) IBOutlet NSSegmentedControl		*whichSegmentControl;
@property (nonatomic, weak) IBOutlet NSTableView			*walletTXTableView;

@end
