//
//  DCWalletTX.h
//  Dogecoin
//
//  Created by Casey Fleser on 1/18/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DCWallet;

@interface DCWalletTX : NSManagedObject

- (void)			updateFromRawTransaction: (NSDictionary *) inTransaction;

@property (nonatomic, strong) NSString			*address;
@property (nonatomic, strong) NSDecimalNumber	*amount;
@property (nonatomic, strong) NSNumber			*category;
@property (nonatomic, strong) NSNumber			*confirmed;
@property (nonatomic, strong) NSDecimalNumber	*fee;
@property (nonatomic, strong) NSDate			*time;
@property (nonatomic, strong) NSString			*txID;
@property (nonatomic, strong) DCWallet			*wallet;

@property (nonatomic, readonly) NSString		*label;

@end
