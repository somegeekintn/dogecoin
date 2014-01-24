//
//  DCBlockInfo.h
//  Dogecoin
//
//  Created by Casey Fleser on 1/14/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DCClient;

@interface DCBlockInfo : NSManagedObject

+ (DCBlockInfo *)		blockInfoAtHeight: (NSInteger) inHeight
							inContext: (NSManagedObjectContext *) inContext;

- (BOOL)				passesValidation;
- (void)				updateWithHeight;

@property (nonatomic, strong) NSString			*blockHash;
@property (nonatomic, strong) NSNumber			*difficulty;
@property (nonatomic, strong) NSNumber			*height;
@property (nonatomic, strong) NSString			*merkleRoot;
@property (nonatomic, strong) NSDecimalNumber	*minted;
@property (nonatomic, strong) NSNumber			*nBits;
@property (nonatomic, strong) NSNumber			*nonce;
@property (nonatomic, strong) NSNumber			*size;
@property (nonatomic, strong) NSDate			*time;
@property (nonatomic, strong) NSNumber			*txCount;

@property (nonatomic, strong) DCClient			*info;

@end
