//
//  DCBridge.h
//  Moon
//
//  Created by Casey Fleser on 1/13/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^RPCCompletion)(NSString *response, BOOL succeeded);

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
- (NSString *)			createNewRxAddress: (NSString *) inLabel;
- (BOOL)				createNewTxAddress: (NSString *) inAddress
							withLabel: (NSString *) inLabel;
- (BOOL)				setLabel: (NSString *) inLabel
							forAddress: (NSString *) inAddress;
- (NSDictionary *)		getMiscInfo;
- (void)				executeRPCRequest: (NSString *) inRequest
							completion: (RPCCompletion) inCompletion;
@end
