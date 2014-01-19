//
//  DCWalletTX.m
//  Dogecoin
//
//  Created by Casey Fleser on 1/18/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCWalletTX.h"
#import "DCConsts.h"


@implementation DCWalletTX

@dynamic address;
@dynamic amount;
@dynamic category;
@dynamic confirmed;
@dynamic fee;
@dynamic time;
@dynamic txID;
@dynamic wallet;

- (void) updateFromRawTransaction: (NSDictionary *) inTransaction
{
	if (![self.confirmed boolValue]) {											// confirmed transactions should not change
		NSNumber			*category = inTransaction[@"category"];
		NSString			*address = inTransaction[@"address"];
		NSDate				*time = [NSDate dateWithTimeIntervalSince1970: [inTransaction[@"time"] longLongValue]];
		NSNumber			*mantissa;
		BOOL				negativeAmount;
		
		negativeAmount = ([category integerValue] == eCoinWalletCategory_Send) ? YES : NO;
		if (address == nil)
			address = @"";
			
		[self testAndSetValue: address withKey: @"address"];
		[self testAndSetValue: category withKey: @"category"];
		[self testAndSetValue: inTransaction[@"txid"] withKey: @"txID"];
		[self testAndSetValue: time withKey: @"time"];
		[self testAndSetValue: inTransaction[@"confirmed"] withKey: @"confirmed"];
		if ((mantissa = inTransaction[@"amount"]) != nil) {
			NSDecimalNumber		*decimalAmount;
			
			if ([mantissa longLongValue])
				decimalAmount = [NSDecimalNumber decimalNumberWithMantissa: [mantissa longLongValue] exponent: kCoinExp isNegative: negativeAmount];
			else
				decimalAmount = [NSDecimalNumber zero];
			[self testAndSetValue: decimalAmount withKey: @"amount"];
		}
		if ((mantissa = inTransaction[@"fee"]) != nil) {
			NSDecimalNumber		*decimalAmount;
			
			if ([mantissa longLongValue])
				decimalAmount = [NSDecimalNumber decimalNumberWithMantissa: [mantissa longLongValue] exponent: kCoinExp isNegative: YES];
			else
				decimalAmount = [NSDecimalNumber zero];
			[self testAndSetValue: decimalAmount withKey: @"fee"];
		}
	}
	else if ([self.category integerValue] == eCoinWalletCategory_Immature) {	// is it actually possible to be confirmed and immature?
		NSNumber				*category = inTransaction[@"category"];

		if (![category isEqualToNumber: self.category]) {
			self.category = category;
		}
	}
}

#pragma mark - Getters / Setters

// Core Data just blindly sets things which generates updates, dirties up the
// managed object context, etc. I wish it didn't do this :/

- (void) testAndSetValue: (id) inValue
	withKey: (NSString *) inKey
{
	if (inValue != nil) {
		id		testValue = [self valueForKey: inKey];
		
		if (testValue == nil || ![testValue isEqual: inValue]) {
			[self setValue: inValue forKey: inKey];
		}
	}
}

- (NSString *) label
{
	return self.address;
}

@end
