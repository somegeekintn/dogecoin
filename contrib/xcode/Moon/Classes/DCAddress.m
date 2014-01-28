//
//  DCAddress.m
//  Moon
//
//  Created by Casey Fleser on 1/18/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCAddress.h"
#import "DCBridge.h"
#import "DCConsts.h"


@implementation DCAddress

@dynamic address;
@dynamic isMine;
@dynamic label;

+ (DCAddress *) updatedAddressFromRawEntry: (NSDictionary *) inRawAddress
	inContext: (NSManagedObjectContext *) inContext
{
	NSFetchRequest			*request = [NSFetchRequest fetchRequestWithEntityName: @"Address"];
	NSString				*coinAddress = inRawAddress[@"address"];
	NSString				*label = inRawAddress[@"label"];
	NSArray					*results = nil;
	DCAddress				*address = nil;
	
	request.predicate = [NSPredicate predicateWithFormat: @"address == %@", coinAddress];
	request.fetchLimit = 1;
	results = [inContext executeFetchRequest: request error: nil];
	address = [results lastObject];
	if (address == nil) {
		NSNumber		*isMine = inRawAddress[@"isMine"];
		
		address = [NSEntityDescription insertNewObjectForEntityForName: @"Address" inManagedObjectContext: inContext];
		address.address = coinAddress;
		address.label = label;
		address.isMine = isMine;
	}
	else {
		if (address.label == nil || ![address.label isEqualToString: label])
			address.label = label;
	}
	
	return address;
}

- (NSString *) tokenizedAddress
{
	NSString		*tokenizedAddress;
	
	if (self.label != nil && [self.label length]) {
		tokenizedAddress = [NSString stringWithFormat: @"%@ <%@>", self.label, self.address];
	}
	else {
		tokenizedAddress = self.address;
	}
	
	return tokenizedAddress;
}

- (BOOL) validateValue: (id *) ioValue
	forKey: (NSString *) inKey
	error: (NSError **) ioError
{
	BOOL		valid = [super validateValue: ioValue forKey: @"key" error: ioError];

	if (valid && [inKey isEqualToString: @"address"]) {
		if (![[DCBridge sharedBridge] validateAddress: *ioValue]) {
			NSString		*errorDescription = [NSString stringWithFormat: @"%@ is not a valid %@ address", *ioValue, DCCoinName];
            NSDictionary	*userInfoDict = @{ NSLocalizedDescriptionKey : errorDescription };
			
			*ioError = [NSError errorWithDomain: DCError_Domain code: eErrorCode_InvalidAddress userInfo: userInfoDict];
			valid = NO;
		}
	}

	return valid;
}

@end
