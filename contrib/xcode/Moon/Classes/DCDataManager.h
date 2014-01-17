//
//  DCDataManager.h
//  Dogecoin
//
//  Created by Casey Fleser on 1/14/14.
//  Copyright (c) 2014 Dogecoin Developers. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DCInfo;

@interface DCDataManager : NSObject

+ (DCDataManager *)		sharedManager;

- (void)				startMonitor;
- (BOOL)				prepareToQuit: (NSApplication *) inSender;
- (void)				updateBlockInfo: (NSInteger) inReconcileDepth;

@property (nonatomic, readonly) NSManagedObjectContext		*defaultContext;
@property (nonatomic, readonly) NSManagedObjectContext		*editContext;
@property (nonatomic, readonly) DCInfo						*info;

@end
