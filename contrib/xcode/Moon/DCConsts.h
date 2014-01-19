//
//  DCConsts.h
//  Dogecoin
//
//  Created by Casey Fleser on 1/17/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#ifndef Dogecoin_DCConsts_h
#define Dogecoin_DCConsts_h

#define kCoinExp		-8

enum {
	eCoinWalletCategory_Unknown = 0,
	eCoinWalletCategory_Send,
	eCoinWalletCategory_Receive,
	eCoinWalletCategory_Generated,
	eCoinWalletCategory_Immature,
	eCoinWalletCategory_Orphan,
	eCoinWalletCategory_Move,
};

#endif
