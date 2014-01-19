//
//  DCBridge.m
//  Dogecoin
//
//  Created by Casey Fleser on 1/13/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//


#import "DCBridge.h"
#import "DCDataManager.h"
#include "bridgehelper.h"
#include "util.h"
#include <boost/filesystem.hpp>


@interface DCBridge ()

@property (nonatomic, assign) BOOL		connected;

@end


void bridge_sig_BlocksChanged()
{
	[[DCDataManager sharedManager] updateBlockInfo: 0];
}

void bridge_sig_NumConnectionsChanged(
	int		inNewNumConnections)
{
	[[DCDataManager sharedManager] setConnectionCount: inNewNumConnections];
}

void bridge_sig_InitMessage(
	const char			*inMessage)
{
	NSLog(@"Init: %s", inMessage);
}

@implementation DCBridge

+ (DCBridge *) sharedBridge
{
	static DCBridge			*sSharedBridge = nil;
	static dispatch_once_t	onceToken;
	
	dispatch_once(&onceToken, ^{
		sSharedBridge = [[DCBridge alloc] init];
	});
	
	return sSharedBridge;
}

- (void) connect
{
	if (boost::filesystem::is_directory(GetDataDir(false))) {
		ReadConfigFile(mapArgs, mapMultiArgs);
//        SoftSetBoolArg("-printtoconsole", true);		// such noise

		if (bridge_Initialize()) {						// probably want to dispatch this so we don't hang
			self.connected = YES;

			[[DCDataManager sharedManager] clientInitializationComplete];
		}
		else {
			NSLog(@"Error: Failed to initialize client");
		}
	}
	else {
        NSLog(@"Error: Specified directory does not exist");
	}
}

- (void) disconnect
{
	self.connected = NO;
	bridge_Shutdown();
}

- (void) runTests
{
}

- (NSInteger) getBlockHeight
{
	return bridge_getBlockHeight();
}

- (NSString *) getBlockHashAtHeight: (NSInteger) inHeight
{
	return (__bridge_transfer NSString *)bridge_getBlockHashAtHeight(inHeight);
}

- (NSDictionary *) getBlockWithHash: (NSString *) inHash
{
	return (__bridge_transfer NSDictionary *)bridge_getBlockWithHash([inHash UTF8String]);
}

- (NSArray *) getWalletTransactions
{
	return (__bridge_transfer NSArray *)bridge_getWalletTransactions();
}

- (NSDictionary *) getMiscInfo
{
	return (__bridge_transfer NSDictionary *)bridge_getMiscInfo();
}


@end
