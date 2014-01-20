//
//  DCWallet.m
//  Dogecoin
//
//  Created by Casey Fleser on 1/18/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCWallet.h"
#import "DCWalletTX.h"
#import "DCConsts.h"


@implementation DCWallet

@dynamic name;
@dynamic transactions;

+ (DCWallet *) walletNamed: (NSString *) inName
	inContext: (NSManagedObjectContext *) inContext
{
	NSFetchRequest		*request = [NSFetchRequest fetchRequestWithEntityName: @"Wallet"];
	NSArray				*results;
	DCWallet			*wallet = nil;
	
	request.predicate = [NSPredicate predicateWithFormat: @"name == %@", inName];
	if ((results = [inContext executeFetchRequest: request error: nil]) != nil)
		wallet = [results lastObject];
	
	if (wallet == nil) {
		wallet = [NSEntityDescription insertNewObjectForEntityForName: @"Wallet" inManagedObjectContext: inContext];
		wallet.name = inName;
	}
	
	return wallet;
}

- (void) awakeFromFetch
{
	[super awakeFromFetch];

	[self monitorTransactions];
}

- (void) awakeFromInsert
{
	[super awakeFromInsert];
	
	[self monitorTransactions];
}

- (void) didTurnIntoFault
{
	[super didTurnIntoFault];
	
	[[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void) monitorTransactions
{
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(handleDataModelChange:) name: NSManagedObjectContextObjectsDidChangeNotification object: self.managedObjectContext];
}

- (void) reconcileWalletTransactions: (NSArray *) inRawTransactions
{
	for (NSDictionary *rawTransaction in inRawTransactions) {
		[self updateFromRawTransaction: rawTransaction];
	}
}

- (DCWalletTX *) updateFromRawTransaction: (NSDictionary *) inRawTransaction
{
	DCWalletTX		*transaction;
		
	transaction = [self findOrCreateTransactionFromRawTransaction: inRawTransaction];
	[transaction updateFromRawTransaction: inRawTransaction];
	
	return transaction;
}

- (DCWalletTX *) findOrCreateTransactionFromRawTransaction: (NSDictionary *) inTransaction
{
	NSPredicate				*txPredicate;
	NSString				*txID = inTransaction[@"txid"];
	NSString				*address = inTransaction[@"address"];
	DCWalletTX				*walletTX = nil;
	
	if (address == nil) {
		// some transactions don't specify an address (generation transactions)
		// there should only be one of this type of transaction per hash id so
		// we should be able to uniquely identify it using the hash and
		// category != eCoinWalletCategory_Send && category != eCoinWalletCategory_Receive
		txPredicate = [NSPredicate predicateWithFormat: @"txID == %@ && category != %@ && category != %@", txID, @(eCoinWalletCategory_Send), @(eCoinWalletCategory_Receive)];
	}
	else {
		txPredicate = [NSPredicate predicateWithFormat: @"txID == %@ && address == %@", txID, address];
	}

	walletTX = [[self.transactions filteredSetUsingPredicate: txPredicate] anyObject];
	if (walletTX == nil) {
		walletTX = [NSEntityDescription insertNewObjectForEntityForName: @"WalletTX" inManagedObjectContext: self.managedObjectContext];
		walletTX.txID = txID;
		[self addTransactionsObject: walletTX];
	}

	return walletTX;
}

#pragma mark - Setters / Getters

- (NSDecimalNumber *) balance
{
	NSDecimalNumber		*balance = [NSDecimalNumber zero];
	
	// Note: transactions.amount.@sum doesn't work
	for (DCWalletTX *walletTX in self.transactions) {
		balance = [balance decimalNumberByAdding: walletTX.amount];
		balance = [balance decimalNumberByAdding: walletTX.fee];
	}
	
	return balance;
}

- (void) handleDataModelChange: (NSNotification *) inNotification
{
	NSDictionary	*userInfo = [inNotification userInfo];
	NSSet			*changedItems;
	Class			walletTXClass = [DCWalletTX class];
	
	changedItems = userInfo[NSInsertedObjectsKey];
	changedItems = [changedItems setByAddingObjectsFromSet: userInfo[NSUpdatedObjectsKey]];
	changedItems = [changedItems setByAddingObjectsFromSet: userInfo[NSDeletedObjectsKey]];

	for (id item in changedItems) {
		if ([item isKindOfClass: walletTXClass]) {
			DCWalletTX		*walletTX = item;
			
			if (walletTX.wallet == self) {
				// mark balance dirty
				[self willChangeValueForKey: @"balance"];
				[self didChangeValueForKey: @"balance"];
				break;
			}
		}
	}
}

@end
