//
//  DCWalletTX.m
//  Moon
//
//  Created by Casey Fleser on 1/18/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCWalletTX.h"
#import "DCAddress.h"
#import "DCBridge.h"
#import "DCClient.h"
#import "DCWallet.h"
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
	NSString		*label = nil;
	
	switch ([self.category integerValue]) {
		case eCoinWalletCategory_Send:
		case eCoinWalletCategory_Receive: {
				DCAddress		*bookAddress;
				
				label = self.address;
				bookAddress = [self.wallet.client addressWithCoinAddress: label];
				if (bookAddress != nil)
					label = bookAddress.label;
			}
			break;
			
		case eCoinWalletCategory_Generated:		label = @"Mined";			break;
		case eCoinWalletCategory_Immature:		label = @"Immature";		break;
		case eCoinWalletCategory_Orphan:		label = @"Orphaned";		break;
		case eCoinWalletCategory_Move:			label = @"Moved";			break;
		default:								label = @"Unknown";			break;
	}

	return label;
}

- (NSString *) status
{
	NSString		*statusString = nil;
	
	if (self.txID != nil) {
		NSArray		*walletTXList = [[DCBridge sharedBridge] getWalletTransactionsWithHash: self.txID];
		
		if (walletTXList != nil && [walletTXList count]) {
			NSDictionary		*walletTXInfo = [walletTXList objectAtIndex: 0];
			NSNumber			*confirmations = [walletTXInfo objectForKey: @"depth"];
			
			if (confirmations != nil && [confirmations integerValue])
				statusString = [NSString stringWithFormat: @"%ld confirmations", [confirmations integerValue]];
			else
				statusString = [NSString stringWithFormat: @"unconfirmed"];
		}
	}

	if (statusString == nil)
		statusString = @"Unknown transaction status";

	return statusString;
}

- (NSString *) blockHash
{
	NSString		*blockHash = nil;
	
	if (self.txID != nil) {
		NSArray		*walletTXList = [[DCBridge sharedBridge] getWalletTransactionsWithHash: self.txID];
		
		if (walletTXList != nil && [walletTXList count]) {
			NSDictionary		*walletTXInfo = [walletTXList objectAtIndex: 0];
			
			blockHash = [walletTXInfo objectForKey: @"block"];
		}
	}

	if (blockHash == nil)
		blockHash = @"Unknown block";

	return blockHash;
}

@end
