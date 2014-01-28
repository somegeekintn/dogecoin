//
//  DCClient.m
//  Moon
//
//  Created by Casey Fleser on 1/14/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCClient.h"
#import "DCBlockInfo.h"
#import "DCWallet.h"


@implementation DCClient

@dynamic difficulty;
@dynamic lastBlockTime;
@dynamic networkMHS;
@dynamic numConnections;
@dynamic totalMinted;
@dynamic totalTransactions;
@dynamic warnings;

@dynamic addresses;
@dynamic blockInfo;
@dynamic wallets;

+ (DCClient *) clientInContext: (NSManagedObjectContext *) inContext
{
	NSFetchRequest		*request = [NSFetchRequest fetchRequestWithEntityName: @"Client"];
	NSArray				*results;
	DCClient			*client = nil;
	
	if ((results = [inContext executeFetchRequest: request error: nil]) != nil)
		client = [results lastObject];
	
	if (client == nil) {
		DCWallet		*defaultWallet = [DCWallet walletNamed: @"default" inContext: inContext];

		client = [NSEntityDescription insertNewObjectForEntityForName: @"Client" inManagedObjectContext: inContext];
		[client addWalletsObject: defaultWallet];
	}
	
	return client;
}

- (void) recalcCumulatives
{
	NSDecimalNumber		*totalMinted = [NSDecimalNumber zero];
	int64_t				totalTransactions = 0;
	DCBlockInfo			*lastBlock;

	for (DCBlockInfo *blockInfo in self.blockInfo) {
		totalMinted = [totalMinted decimalNumberByAdding: blockInfo.minted];
		totalTransactions += [blockInfo.txCount integerValue];
	}
	
	self.totalMinted = totalMinted;
	self.totalTransactions = @(totalTransactions);
	if ((lastBlock = [self lastBlockInfo]) != nil) {
		self.difficulty = lastBlock.difficulty;
		self.lastBlockTime = lastBlock.time;
	}
}

- (void) addToCumulatives: (DCBlockInfo *) inBlockInfo
{
	self.totalMinted = [self.totalMinted decimalNumberByAdding: inBlockInfo.minted];
	self.totalTransactions = @([self.totalTransactions longLongValue] + [inBlockInfo.txCount integerValue]);
	self.difficulty = inBlockInfo.difficulty;
	self.lastBlockTime = inBlockInfo.time;
}

- (DCBlockInfo *) lastBlockInfo
{
	NSFetchRequest		*blockInfoRequest = [NSFetchRequest fetchRequestWithEntityName: @"BlockInfo"];
	NSArray				*results;
	
	blockInfoRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey: @"height" ascending: NO]];
	blockInfoRequest.fetchLimit = 1;
	results = [self.managedObjectContext executeFetchRequest: blockInfoRequest error: nil];
	
	return [results lastObject];
}

- (DCBlockInfo *) blockInfoAtHeight: (NSInteger) inBlockHeight
{
	NSFetchRequest		*blockInfoRequest = [NSFetchRequest fetchRequestWithEntityName: @"BlockInfo"];
	NSArray				*results;
	
	blockInfoRequest.predicate = [NSPredicate predicateWithFormat: @"height == %@", @(inBlockHeight)];
	results = [self.managedObjectContext executeFetchRequest: blockInfoRequest error: nil];
	
	return [results lastObject];
}

- (DCAddress *) addressWithCoinAddress: (NSString *) inCoinAddress
{
	NSPredicate		*predicate = [NSPredicate predicateWithFormat: @"address == %@", inCoinAddress];
	NSSet			*matchingAddresses = [self.addresses filteredSetUsingPredicate: predicate];
	
	return [matchingAddresses anyObject];
}

- (DCAddress *) addressWithCoinAddressOrLabel: (NSString *) inFragment
{
	NSPredicate		*predicate = [NSPredicate predicateWithFormat: @"address like[cd] %@ || label like[cd] %@", inFragment, inFragment];
	
	return [[self.addresses filteredSetUsingPredicate: predicate] anyObject];
}

- (NSSet *) addressesContaining: (NSString *) inAddressFragment
	mine: (BOOL) inMine
{
	NSPredicate		*predicate = [NSPredicate predicateWithFormat: @"(address contains[cd] %@ || label contains[cd] %@) && isMine == %@", inAddressFragment, inAddressFragment, @(inMine)];
	
	return [self.addresses filteredSetUsingPredicate: predicate];
}

#pragma mark - Setters / Getters

- (DCWallet *) activeWallet
{
	// for the time being there is only one wallet
	
	return [self.wallets anyObject];
}

@end
