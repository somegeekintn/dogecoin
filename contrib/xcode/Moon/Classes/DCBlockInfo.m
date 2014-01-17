//
//  DCBlockInfo.m
//  Dogecoin
//
//  Created by Casey Fleser on 1/14/14.
//  Copyright (c) 2014 Dogecoin Developers. All rights reserved.
//

#import "DCBlockInfo.h"
#import "DCBridge.h"
#import "DCInfo.h"

#define kCoinExp		-8

@implementation DCBlockInfo

@dynamic blockHash;
@dynamic difficulty;
@dynamic fees;
@dynamic height;
@dynamic merkleRoot;
@dynamic minted;
@dynamic nBits;
@dynamic nonce;
@dynamic size;
@dynamic time;
@dynamic txCount;

@dynamic info;

+ (DCBlockInfo *) blockInfoAtHeight: (NSInteger) inHeight
	inContext: (NSManagedObjectContext *) inContext
{
	NSFetchRequest			*fetchRequest = [NSFetchRequest fetchRequestWithEntityName: @"BlockInfo"];
	NSArray					*results = nil;
	DCBlockInfo				*blockInfo = nil;
	
	fetchRequest.predicate = [NSPredicate predicateWithFormat: @"height == %@", @(inHeight)];
	fetchRequest.fetchLimit = 1;
	results = [inContext executeFetchRequest: fetchRequest error: nil];
	blockInfo = [results lastObject];
	if (blockInfo == nil) {
		blockInfo = [NSEntityDescription insertNewObjectForEntityForName: @"BlockInfo" inManagedObjectContext: inContext];
		blockInfo.height = @(inHeight);
		
		[blockInfo updateWithHeight];
	}
	
	return blockInfo;
}

- (BOOL) passesValidation
{
	BOOL		isValid = YES;
	
	if (self.blockHash == nil)
		isValid = NO;
	else {
		NSString	*testHash = [[DCBridge sharedBridge] getBlockHashAtHeight: [self.height integerValue]];
		
		isValid = [self.blockHash isEqualToString: testHash];
	}

NSLog(@"validate %@: %@", self.height, isValid ? @"OK" : @"FAIL");

	return isValid;
}

- (void) updateWithHeight
{
	NSString		*blockHash = [[DCBridge sharedBridge] getBlockHashAtHeight: [self.height integerValue]];
	
	if (blockHash != nil) {
		NSDictionary	*rawBlock = [[DCBridge sharedBridge] getBlockWithHash: blockHash];

		self.blockHash = blockHash;
		self.difficulty = [NSNumber numberWithDouble: [rawBlock[@"difficulty"] doubleValue]];
		self.fees = [NSDecimalNumber decimalNumberWithMantissa: [rawBlock[@"fees"] longLongValue] exponent: kCoinExp isNegative: NO];
		self.nBits = rawBlock[@"bits"];
		self.merkleRoot = rawBlock[@"merkleroot"];
		self.minted = [NSDecimalNumber decimalNumberWithMantissa: [rawBlock[@"minted"] longLongValue] exponent: kCoinExp isNegative: NO];
		self.nonce = [NSNumber numberWithInteger: [rawBlock[@"nonce"] unsignedIntValue]];
		self.size = [NSNumber numberWithInteger: [rawBlock[@"size"] integerValue]];
		self.time = [NSDate dateWithTimeIntervalSince1970: [rawBlock[@"time"] longLongValue]];
		self.txCount = @([rawBlock[@"tx"] count]);
	}
}

@end
