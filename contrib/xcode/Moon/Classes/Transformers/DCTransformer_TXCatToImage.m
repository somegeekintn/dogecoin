//
//  DCTransformer_TXCatToImage.m
//  Moon
//
//  Created by Casey Fleser on 2/9/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCTransformer_TXCatToImage.h"
#import "DCConsts.h"

@implementation DCTransformer_TXCatToImage

+ (Class) transformedValueClass
{
	return [NSImage class];
}

+ (BOOL) allowsReverseTransformation
{
	return NO;
}

- (id) transformedValue: (id) inNumberValue
{
	NSInteger		txCat = [inNumberValue integerValue];
	NSImage			*txCatImage = nil;
	
	switch (txCat) {
		case eCoinWalletCategory_Send:			txCatImage = [NSImage imageNamed: @"tx_icon_tx"];		break;
		case eCoinWalletCategory_Receive:		txCatImage = [NSImage imageNamed: @"tx_icon_rx"];		break;
		case eCoinWalletCategory_Generated:		txCatImage = [NSImage imageNamed: @"tx_icon_mine"];		break;
		case eCoinWalletCategory_Orphan:		txCatImage = [NSImage imageNamed: @"tx_icon_orphan"];	break;
		case eCoinWalletCategory_Move:			txCatImage = [NSImage imageNamed: @"tx_icon_move"];		break;

		case eCoinWalletCategory_Unknown:
		case eCoinWalletCategory_Immature:
		default:
			txCatImage = [NSImage imageNamed: @"tx_icon_unknown"];	break;
	}
	
	return txCatImage;
}

@end
