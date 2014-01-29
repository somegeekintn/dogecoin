//
//  DCConsts.h
//  Moon
//
//  Created by Casey Fleser on 1/17/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#ifndef Dogecoin_DCConsts_h
#define Dogecoin_DCConsts_h

#define kCoinExp			-8
#define kCoinMultiplier		100000000		// see COIN in util.h

enum {
	eCoinWalletCategory_Unknown = 0,
	eCoinWalletCategory_Send,
	eCoinWalletCategory_Receive,
	eCoinWalletCategory_Generated,
	eCoinWalletCategory_Immature,
	eCoinWalletCategory_Orphan,
	eCoinWalletCategory_Move,
};

enum {
	eCoinSendResponse_Success = 0,
	eCoinSendResponse_Canceled,
	eCoinSendResponse_Error_NSF,
	eCoinSendResponse_Error_NSF_WithFees,
	eCoinSendResponse_Error_InvalidAmount,
	eCoinSendResponse_Error_TransactionCreateFailed,
	eCoinSendResponse_Error_TransactionCommitFailed,
	eCoinSendResponse_Error_Unknown,
};

enum {
	eErrorCode_Unknown = -1,
	eErrorCode_NoError = 0,
	eErrorCode_InvalidAddress,
	eErrorCode_DuplicateAddress,
};

#ifdef __OBJC__
extern NSString * const		DCCoinName;

extern NSString * const		DCNotification_InitMessage;
extern NSString * const		DCNotification_InitComplete;

extern NSString * const		DCError_Domain;
#endif


#endif
