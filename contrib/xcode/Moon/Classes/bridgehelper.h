//
//  bridgehelper.h
//  Dogecoin
//
//  Created by Casey Fleser on 1/13/14.
//  Copyright (c) 2014 Dogecoin Developers. All rights reserved.
//

#ifndef Dogecoin_bridgehelper_h
#define Dogecoin_bridgehelper_h

#include <string>
#include <list>

bool				bridge_Initialize();
bool				bridge_Shutdown();

int32_t				bridge_getBlockHeight();
std::string			bridge_getBlockHashAtHeight(
						int32_t				inHeight);
std::string			bridge_getBlockWithHash(
						const char			*inHash);

#endif
