//
//  DCBridge.m
//  Dogecoin
//
//  Created by Casey Fleser on 1/13/14.
//  Copyright (c) 2014 Dogecoin Developers. All rights reserved.
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
	NSLog(@"%s: %d", __PRETTY_FUNCTION__, inNewNumConnections);
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

			[[DCDataManager sharedManager] updateBlockInfo: 1000];		// validate the last N blocks upon connect
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

- (NSInteger) getBlockHeight
{
	return bridge_getBlockHeight();
}

- (NSString *) getBlockHashAtHeight: (NSInteger) inHeight
{
	NSString		*blockHash = nil;
	std::string		hashStr = bridge_getBlockHashAtHeight(inHeight);
	
	if (!hashStr.empty())
		blockHash = [NSString stringWithUTF8String: hashStr.c_str()];
	
	return blockHash;
}

- (NSDictionary *) getBlockWithHash: (NSString *) inHash
{
	NSMutableDictionary	*rawBlock = nil;
	NSData				*responseData;
	NSError				*jsonError;
	std::string			response;
	
	response = bridge_getBlockWithHash([inHash UTF8String]);
	responseData = [NSData dataWithBytes: response.c_str() length: response.length()];
	rawBlock = [NSJSONSerialization JSONObjectWithData: responseData options: NSJSONReadingMutableContainers error: &jsonError];

	return rawBlock;
}

@end
