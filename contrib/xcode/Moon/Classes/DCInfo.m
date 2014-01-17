//
//  DCInfo.m
//  Dogecoin
//
//  Created by Casey Fleser on 1/14/14.
//  Copyright (c) 2014 Dogecoin Developers. All rights reserved.
//

#import "DCInfo.h"
#import "DCBlockInfo.h"


@implementation DCInfo

@dynamic difficulty;
@dynamic lastBlockTime;
@dynamic networkHashRate;
@dynamic numConnections;
@dynamic totalMinted;
@dynamic totalTransactions;

@dynamic blockInfo;

+ (DCInfo *) infoInContext: (NSManagedObjectContext *) inContext
{
	NSFetchRequest		*request = [NSFetchRequest fetchRequestWithEntityName: @"Info"];
	NSArray				*results;
	DCInfo				*info = nil;
	
	if ((results = [inContext executeFetchRequest: request error: nil]) != nil)
		info = [results lastObject];
	
	if (info == nil)
		info = [NSEntityDescription insertNewObjectForEntityForName: @"Info" inManagedObjectContext: inContext];
	
	return info;
}

- (void) recalcCumulatives
{
	NSDecimalNumber		*totalMinted = [[NSDecimalNumber alloc] init];
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

@end
