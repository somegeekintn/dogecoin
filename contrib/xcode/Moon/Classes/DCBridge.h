//
//  DCBridge.h
//  Dogecoin
//
//  Created by Casey Fleser on 1/13/14.
//  Copyright (c) 2014 Dogecoin Developers. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DCBridge : NSObject

+ (DCBridge *)			sharedBridge;

- (void)				connect;
- (void)				disconnect;

- (NSInteger)			getBlockHeight;
- (NSString *)			getBlockHashAtHeight: (NSInteger) inHeight;
- (NSDictionary *)		getBlockWithHash: (NSString *) inHash;

@end
