//
//  DCBridge.h
//  Dogecoin
//
//  Created by Casey Fleser on 1/13/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DCBridge : NSObject

+ (DCBridge *)			sharedBridge;

- (void)				connect;
- (void)				disconnect;

- (NSInteger)			getBlockHeight;
- (NSString *)			getBlockHashAtHeight: (NSInteger) inHeight;
- (NSDictionary *)		getBlockWithHash: (NSString *) inHash;
- (NSArray *)			getWalletTransactions;
- (NSArray *)			getWalletTransactionsWithHash: (NSString *) inHash;
- (BOOL)				sendCoins: (double) inAmount
							to: (NSArray *) inRecipients;
- (NSArray *)			getAddressBook;
- (BOOL)				validateAddress: (NSString *) inAddress;
- (NSDictionary *)		getMiscInfo;

@end
