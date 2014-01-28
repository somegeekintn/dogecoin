//
//  DCAddressBook.m
//  Moon
//
//  Created by Casey Fleser on 1/26/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCAddressBook.h"
#import "DCAddress.h"
#import "DCBridge.h"
#import "DCWalletTX.h"

@interface DCAddressBook ()

@property (nonatomic, assign) BOOL		showMine;

@end

@implementation DCAddressBook

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	[self setSortDescriptors: @[ [NSSortDescriptor sortDescriptorWithKey: @"label" ascending: YES]]];
}

- (void) updateFilterPredicate
{
	[self setFilterPredicate: [NSPredicate predicateWithFormat: @"isMine == %@", @(self.showMine)]];
}

- (void) objectDidEndEditing:(id)editor
{
	[super objectDidEndEditing: editor];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleDataModelChange:) name: NSManagedObjectContextObjectsDidChangeNotification object: self.managedObjectContext];
}

- (BOOL) commitEditing
{
	BOOL		didCommit = [super commitEditing];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];

	return didCommit;
}

- (void) copySelection
{
	NSPasteboard		*pasteBoard = [NSPasteboard generalPasteboard];
	NSMutableArray		*tokenizedAddresses = [NSMutableArray array];
	NSString			*pboardAddresses;
	
	for (DCAddress *address in self.selectedObjects) {
		[tokenizedAddresses addObject: [address tokenizedAddress]];
	}
	pboardAddresses = [tokenizedAddresses componentsJoinedByString: @", "];
	
    [pasteBoard clearContents];
	[pasteBoard writeObjects: @[pboardAddresses]];
}

- (void) dirtyTransactionsWithAddress: (NSString *) inAddress
{
	[self.managedObjectContext performBlock:^{
		NSFetchRequest	*txRequest = [NSFetchRequest fetchRequestWithEntityName: @"WalletTX"];
		NSArray			*matchingTXs;
		
		txRequest.predicate = [NSPredicate predicateWithFormat: @"address == %@", inAddress];
		matchingTXs = [self.managedObjectContext executeFetchRequest: txRequest error: nil];
		for (DCWalletTX *tx in matchingTXs) {
			[tx willChangeValueForKey: @"label"];
			[tx didChangeValueForKey: @"label"];
		}
	}];
}

#pragma mark - Setters / Getters

- (void) setShowMine: (BOOL) inShowMine
{
	if (_showMine != inShowMine) {
		_showMine = inShowMine;
		
		[self updateFilterPredicate];
	}
}

#pragma mark - Handlers

- (void) showAddressBook: (id) inSender
{
	[self updateFilterPredicate];
	[self.whichSegmentControl setSelectedSegment: self.showMine ? 1 : 0];
	[self.addrBookWindow makeKeyAndOrderFront: self];
}

- (void) handleAddressSegment: (id) inSender
{
	self.showMine = self.whichSegmentControl.selectedSegment ? YES : NO;
}

- (void) handleNewAddress: (id) inSender
{
	if (self.showMine) {
		[[DCBridge sharedBridge] createNewAddress: nil];
		
		// need to figure out how to select new address
//		NSMutableArray	*newAddrList;
//		NSArray			*startAddrList = [self.content copy];
//
//		[[DCBridge sharedBridge] createNewAddress: nil];
//		newAddrList = [self.content mutableCopy];
//		[newAddrList removeObjectsInArray: startAddrList];
//		[self setSelectedObjects: newAddrList];
	}
	else {
		[self.managedObjectContext performBlock: ^{
			DCAddress		*newAddress = [NSEntityDescription insertNewObjectForEntityForName: @"Address" inManagedObjectContext: self.managedObjectContext];
			
			newAddress.label = @"";
			newAddress.isMine = @(NO);
			newAddress.address = @"- missing -";
			[self addObject: newAddress];
		}];
	}
}

- (void) handleDataModelChange: (NSNotification *) inNotification
{
	NSDictionary	*userInfo = [inNotification userInfo];
	
//	NSLog(@"NSInsertedObjectsKey %@", userInfo[NSInsertedObjectsKey]);
//	NSLog(@"NSUpdatedObjectsKey %@", userInfo[NSUpdatedObjectsKey]);
//	NSLog(@"NSDeletedObjectsKey %@", userInfo[NSDeletedObjectsKey]);
	
	for (id obj in userInfo[NSUpdatedObjectsKey]) {
		if ([obj isKindOfClass: [DCAddress class]]) {
			NSDictionary	*changedValues = [obj changedValuesForCurrentEvent];
			NSArray			*changedKeys = [changedValues allKeys];
			
			if ([changedKeys containsObject: @"address"]) {
				NSDictionary		*oldValues = [obj committedValuesForKeys: @[@"address"]];
				NSString			*oldAddress = [oldValues valueForKey: @"address"];
				NSString			*newAddress = [obj valueForKey: @"address"];
				
				if (oldAddress == nil || ![oldAddress length]) {
NSLog(@"create a new address: %@", newAddress);
				}
				else {
NSLog(@"change %@ to %@", oldAddress, newAddress);
				}
			}
			if ([changedKeys containsObject: @"label"]) {
				NSString		*address = [obj valueForKey: @"address"];
				NSString		*label = [obj valueForKey: @"label"];
				
				[[DCBridge sharedBridge] setLabel: label forAddress: address];
				[self dirtyTransactionsWithAddress: address];
			}
		}
	}
}
@end
