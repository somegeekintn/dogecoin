//
//  DCClient.h
//  Moon
//
//  Created by Casey Fleser on 1/14/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DCAddress;
@class DCBlockInfo;
@class DCWallet;

@interface DCClient : NSManagedObject

+ (DCClient *)			clientInContext: (NSManagedObjectContext *) inContext;

- (void)				recalcCumulatives;
- (void)				addToCumulatives: (DCBlockInfo *) inBlockInfo;
- (DCBlockInfo *)		blockInfoAtHeight: (NSInteger) inBlockHeight;
- (DCBlockInfo *)		lastBlockInfo;
- (DCAddress *)			addressWithCoinAddress: (NSString *) inCoinAddress;
- (DCAddress *)			addressWithCoinAddressOrLabel: (NSString *) inFragment;
- (NSSet *)				addressesContaining: (NSString *) inAddressFragment
							mine: (BOOL) inMine;

@property (nonatomic, strong) NSNumber			*difficulty;
@property (nonatomic, strong) NSDate			*lastBlockTime;
@property (nonatomic, strong) NSNumber			*networkMHS;
@property (nonatomic, strong) NSNumber			*numConnections;
@property (nonatomic, strong) NSDecimalNumber	*totalMinted;
@property (nonatomic, strong) NSNumber			*totalTransactions;
@property (nonatomic, strong) NSString			*warnings;

@property (nonatomic, strong) NSSet				*addresses;
@property (nonatomic, strong) NSSet				*blockInfo;
@property (nonatomic, strong) NSSet				*wallets;

@property (nonatomic, readonly) DCWallet		*activeWallet;

@end

@interface DCClient (CoreDataGeneratedAccessors)

- (void)		addAddressesObject: (DCAddress *) inValue;
- (void)		removeAddressesObject: (DCAddress *) inValue;
- (void)		addAddresses: (NSSet *) inValues;
- (void)		removeAddresses: (NSSet *) inValues;
- (void)		addBlockInfoObject: (DCBlockInfo *) inValue;
- (void)		removeBlockInfoObject: (DCBlockInfo *) inValue;
- (void)		addBlockInfo: (NSSet *) inValues;
- (void)		removeBlockInfo: (NSSet *) inValues;
- (void)		addWalletsObject: (DCWallet *) inValue;
- (void)		removeWalletsObject: (DCWallet *) inValue;
- (void)		addWallets: (NSSet *) inValues;
- (void)		removeWallets: (NSSet *) inValues;

@end
