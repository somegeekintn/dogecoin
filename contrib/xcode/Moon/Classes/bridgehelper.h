//
//  bridgehelper.h
//  Moon
//
//  Created by Casey Fleser on 1/13/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#ifndef Dogecoin_bridgehelper_h
#define Dogecoin_bridgehelper_h

#include <CoreFoundation/CoreFoundation.h>
#include <string>
#include <list>

typedef void (^bridge_RPCCompletion)(const char *response, bool succeeded);

void					bridge_testBlockValues();
void					bridge_testTXScan();

bool					bridge_Initialize();
void					bridge_Shutdown();

int32_t					bridge_getBlockHeight();
CFStringRef				bridge_getBlockHashAtHeight(
							int32_t					inHeight);
CFDictionaryRef			bridge_getBlockWithHash(
							const char				*inHash);
CFArrayRef				bridge_getWalletTransactions();		// will add filtering at some point
CFArrayRef				bridge_getWalletTransactionsWithHash(
							const char				*inHash);
CFDictionaryRef			bridge_sendCoins(
							CFArrayRef				inRecipients,
							double					amount);
CFArrayRef				bridge_getAddressBook();
bool					bridge_validateAddress(
							const char				*inAddress);
CFStringRef				bridge_createNewRxAddress(
							const char				*inLabel);
bool					bridge_createNewTxAddress(
							const char				*inAddress,
							const char				*inLabel);
bool					bridge_setLabelForAddress(
							const char				*inLabel,
							const char				*inAddress);
CFDictionaryRef			bridge_getMiscInfo();

void					bridge_executeRPCRequest(
							const char				*inRawCommand,
							bridge_RPCCompletion	inCompletion);
#endif
