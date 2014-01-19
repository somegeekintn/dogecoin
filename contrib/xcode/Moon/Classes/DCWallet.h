//
//  DCWallet.h
//  Dogecoin
//
//  Created by Casey Fleser on 1/18/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//
//	Note: at this point we don't support multiple wallets, but
//	we've added this in case we decide to some day

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@class DCWalletTX;

@interface DCWallet : NSManagedObject

+ (DCWallet *)				walletNamed: (NSString *) inName
								inContext: (NSManagedObjectContext *) inContext;

- (void)					reconcile;

@property (nonatomic, strong) NSString				*name;
@property (nonatomic, strong) NSSet					*transactions;
@property (nonatomic, readonly) NSDecimalNumber		*balance;

@end

@interface DCWallet (CoreDataGeneratedAccessors)

- (void)		addTransactionsObject: (DCWalletTX *) inValue;
- (void)		removeTransactionsObject: (DCWalletTX *) inValue;
- (void)		addTransactions: (NSSet *) inValues;
- (void)		removeTransactions: (NSSet *) inValues;

@end
