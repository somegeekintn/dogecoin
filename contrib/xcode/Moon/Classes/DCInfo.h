//
//  DCInfo.h
//  Dogecoin
//
//  Created by Casey Fleser on 1/14/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class DCBlockInfo;

@interface DCInfo : NSManagedObject

+ (DCInfo *)			infoInContext: (NSManagedObjectContext *) inContext;

- (void)				recalcCumulatives;
- (void)				addToCumulatives: (DCBlockInfo *) inBlockInfo;
- (DCBlockInfo *)		blockInfoAtHeight: (NSInteger) inBlockHeight;
- (DCBlockInfo *)		lastBlockInfo;

@property (nonatomic, strong) NSNumber			*difficulty;
@property (nonatomic, strong) NSDate			*lastBlockTime;
@property (nonatomic, strong) NSNumber			*networkMHS;
@property (nonatomic, strong) NSNumber			*numConnections;
@property (nonatomic, strong) NSDecimalNumber	*totalMinted;
@property (nonatomic, strong) NSNumber			*totalTransactions;
@property (nonatomic, strong) NSString			*warnings;

@property (nonatomic, strong) NSSet				*blockInfo;

@end

@interface DCInfo (CoreDataGeneratedAccessors)

- (void)		addBlockInfoObject: (DCBlockInfo *) inValue;
- (void)		removeBlockInfoObject: (DCBlockInfo *) inValue;
- (void)		addBlockInfo: (NSSet *) inValues;
- (void)		removeBlockInfo: (NSSet *) inValues;

@end
