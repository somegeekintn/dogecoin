//
//  bridgehelper.h
//  Dogecoin
//
//  Created by Casey Fleser on 1/13/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#ifndef Dogecoin_bridgehelper_h
#define Dogecoin_bridgehelper_h

#include <CoreFoundation/CoreFoundation.h>
#include <string>
#include <list>

bool					bridge_Initialize();
void					bridge_Shutdown();

void					bridge_testAddrBook();

int32_t					bridge_getBlockHeight();
CFStringRef				bridge_getBlockHashAtHeight(
							int32_t				inHeight);
CFDictionaryRef			bridge_getBlockWithHash(
							const char			*inHash);
CFArrayRef				bridge_getWalletTransactions();		// will add filtering at some point
CFArrayRef				bridge_getWalletTransactionsWithHash(
							const char			*inHash);
CFDictionaryRef			bridge_sendCoins(
							CFArrayRef				inRecipients,
							double					amount);
CFArrayRef				bridge_getAddressBook();
bool					bridge_validateAddress(
							const char			*inAddress);
CFDictionaryRef			bridge_getMiscInfo();

#endif
