//
//  DCAddress.h
//  Dogecoin
//
//  Created by Casey Fleser on 1/18/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface DCAddress : NSManagedObject

@property (nonatomic, strong) NSString		*address;
@property (nonatomic, strong) NSNumber		*isMine;
@property (nonatomic, strong) NSString		*label;

@end
