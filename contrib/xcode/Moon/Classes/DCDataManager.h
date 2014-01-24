//
//  DCDataManager.h
//  Dogecoin
//
//  Created by Casey Fleser on 1/14/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DCClient;
@class DCWallet;

@interface DCDataManager : NSObject

+ (DCDataManager *)		sharedManager;

- (void)				startMonitor;
- (BOOL)				prepareToQuit: (NSApplication *) inSender;
- (void)				clientInitializationComplete;
- (void)				updateBlockInfo: (NSInteger) inReconcileDepth;
- (void)				updateWalletTrasactionWithHash: (NSString *) inWalletTxHash
							notify: (BOOL) inNotify;
- (void)				deleteWalletTrasactionWithHash: (NSString *) inWalletTxHash;
- (void)				updateAddressEntry: (NSDictionary *) inRawAddress;
- (void)				deleteAddressEntry: (NSDictionary *) inRawAddress;
- (void)				setConnectionCount: (NSInteger) inNumConnections;

@property (nonatomic, readonly) NSManagedObjectContext		*defaultContext;
@property (nonatomic, readonly) NSManagedObjectContext		*editContext;
@property (nonatomic, readonly) DCClient					*client;

@end
