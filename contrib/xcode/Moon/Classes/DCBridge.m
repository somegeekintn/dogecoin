//
//  DCBridge.m
//  Moon
//
//  Created by Casey Fleser on 1/13/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//
//	Note: This "class" may appear to be an unecessary extra step of indirection
//	between DCDataManger and bridge_helper, but it's mostly so we don't have
//	compile DCDataManager as an Obj-C++ file. This could in turn lead to other
//	files needing to be compiled this way (at least from past experience). So
//	DCBridge is a dividing line between Obj-C and Obj-C++ while bridgehelper
//	is a dividing line between the client and the core code.

#import "DCBridge.h"
#import "DCDataManager.h"
#import "DCConsts.h"
#import "NSAlert+Moon.h"
#import "NSNumberFormatter+Moon.h"

#include "bridgehelper.h"
#include "util.h"
#include <boost/filesystem.hpp>

@interface DCBridge ()

@property (nonatomic, assign) BOOL		connected;

@end


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

		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			if (bridge_Initialize()) {						// probably want to dispatch this so we don't hang
				self.connected = YES;

				[[DCDataManager sharedManager] clientInitializationComplete];
				[[NSNotificationCenter defaultCenter] postNotificationName: DCNotification_InitComplete object: nil];
			}
			else {
				[[NSNotificationCenter defaultCenter] postNotificationName: DCNotification_InitMessage object: nil userInfo: @{ @"message" : @"Error: Failed to initialize client"}];
			}
		});
	}
	else {
		[[NSNotificationCenter defaultCenter] postNotificationName: DCNotification_InitMessage object: nil userInfo: @{ @"message" : @"Error: Data directory does not exist"}];
	}
}

- (void) disconnect
{
	if (self.connected) {
		self.connected = NO;
		bridge_Shutdown();
	}
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

- (NSArray *) getWalletTransactionsWithHash:(NSString *)inHash
{
	return (__bridge_transfer NSArray *)bridge_getWalletTransactionsWithHash([inHash UTF8String]);
}

- (BOOL) sendCoins: (double) inAmount
	to: (NSArray *) inRecipients
{
	NSDictionary		*sendResponse = (__bridge_transfer NSDictionary *)bridge_sendCoins((__bridge CFArrayRef)inRecipients, inAmount);
	NSNumber			*response = sendResponse[@"result"];
	BOOL				didSend;
	
	didSend = response != nil && [response integerValue] == eCoinSendResponse_Success;

NSLog(@"response %@", response);
//    WalletModel::SendCoinsReturn sendstatus = model->sendCoins(recipients);
//    switch(sendstatus.status)
//    {
//    case WalletModel::InvalidAddress:
//        QMessageBox::warning(this, tr("Send Coins"),
//            tr("The recepient address is not valid, please recheck."),
//            QMessageBox::Ok, QMessageBox::Ok);
//        break;
//    case WalletModel::InvalidAmount:
//        QMessageBox::warning(this, tr("Send Coins"),
//            tr("The amount to pay must be larger than 0."),
//            QMessageBox::Ok, QMessageBox::Ok);
//        break;
//    case WalletModel::AmountExceedsBalance:
//        QMessageBox::warning(this, tr("Send Coins"),
//            tr("The amount exceeds your balance."),
//            QMessageBox::Ok, QMessageBox::Ok);
//        break;
//    case WalletModel::AmountWithFeeExceedsBalance:
//        QMessageBox::warning(this, tr("Send Coins"),
//            tr("The total exceeds your balance when the %1 transaction fee is included.").
//            arg(BitcoinUnits::formatWithUnit(BitcoinUnits::BTC, sendstatus.fee)),
//            QMessageBox::Ok, QMessageBox::Ok);
//        break;
//    case WalletModel::DuplicateAddress:
//        QMessageBox::warning(this, tr("Send Coins"),
//            tr("Duplicate address found, can only send to each address once per send operation."),
//            QMessageBox::Ok, QMessageBox::Ok);
//        break;
//    case WalletModel::TransactionCreationFailed:
//        QMessageBox::warning(this, tr("Send Coins"),
//            tr("Error: Transaction creation failed."),
//            QMessageBox::Ok, QMessageBox::Ok);
//        break;
//    case WalletModel::TransactionCommitFailed:
//        QMessageBox::warning(this, tr("Send Coins"),
//            tr("Error: The transaction was rejected. This might happen if some of the coins in your wallet were already spent, such as if you used a copy of wallet.dat and coins were spent in the copy but not marked as spent here."),
//            QMessageBox::Ok, QMessageBox::Ok);
//        break;
//    case WalletModel::Aborted: // User aborted, nothing to do
//        break;
//    case WalletModel::OK:
//        accept();
//        break;
//    }
//    fNewRecipientAllowed = true;

	return didSend;
}

- (NSArray *) getAddressBook
{
	return (__bridge_transfer NSArray *)bridge_getAddressBook();
}

- (BOOL) validateAddress: (NSString *) inAddress
{
	return bridge_validateAddress([inAddress UTF8String]);
}

- (NSString *) createNewRxAddress: (NSString *) inLabel
{
	return (__bridge_transfer NSString *)bridge_createNewRxAddress(inLabel != nil ? [inLabel UTF8String] : NULL);
}

- (BOOL) createNewTxAddress: (NSString *) inAddress
	withLabel: (NSString *) inLabel
{
	return bridge_createNewTxAddress([inAddress UTF8String], inLabel != nil ? [inLabel UTF8String] : NULL);
}

- (BOOL) setLabel: (NSString *) inLabel
	forAddress: (NSString *) inAddress
{
	return bridge_setLabelForAddress([inLabel UTF8String], [inAddress UTF8String]);
}

- (NSDictionary *) getMiscInfo
{
	return (__bridge_transfer NSDictionary *)bridge_getMiscInfo();
}

- (void) executeRPCRequest: (NSString *) inRequest
	completion: (RPCCompletion) inCompletion
{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		bridge_executeRPCRequest([inRequest UTF8String], ^(const char *inResponse, bool inSucceeded) {
			NSString		*response = [NSString stringWithUTF8String: inResponse];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				inCompletion(response, inSucceeded);
			});
		});
	});
}

@end

#pragma mark - Notication callbacks

void bridge_sig_AddressChanged(CFDictionaryRef inRawAddress)
{
	@autoreleasepool {
		NSDictionary		*addressEntry = (__bridge_transfer NSDictionary *)inRawAddress;
	
		[[DCDataManager sharedManager] updateAddressEntry: addressEntry];
	}
}

void bridge_sig_AddressDeleted(CFDictionaryRef inRawAddress)
{
	@autoreleasepool {
		NSDictionary		*addressEntry = (__bridge_transfer NSDictionary *)inRawAddress;
	
		[[DCDataManager sharedManager] deleteAddressEntry: addressEntry];
	}
}

void bridge_sig_WalletTransactionChanged(
	CFStringRef			inWalletTxHash,
	bool				inNotify)
{
	@autoreleasepool {
		NSString		*walletTXHash = (__bridge_transfer NSString *)inWalletTxHash;
	
		[[DCDataManager sharedManager] updateWalletTrasactionWithHash: walletTXHash notify: inNotify];
	}
}

void bridge_sig_WalletTransactionDeleted(
	CFStringRef			inWalletTxHash)
{
	@autoreleasepool {
		NSString		*walletTXHash = (__bridge_transfer NSString *)inWalletTxHash;
	
		[[DCDataManager sharedManager] deleteWalletTrasactionWithHash: walletTXHash];
	}
}

void bridge_sig_BlocksChanged()
{
	[[DCDataManager sharedManager] updateBlockInfo: 0];
}

void bridge_sig_NumConnectionsChanged(
	int					inNewNumConnections)
{
	[[DCDataManager sharedManager] setConnectionCount: inNewNumConnections];
}

bool bridge_sig_AskFee(
	int64				inFee)
{
	NSDecimalNumber	*fee = [NSDecimalNumber decimalNumberWithMantissa: inFee exponent: kCoinExp isNegative: NO];
	NSString		*infoText = [NSString stringWithFormat: @"This transaction is over the size limit. You can still send it for a fee of %@, "
									"which goes to the nodes that process your transaction and helps to support the network. "
									"Do you want to pay the fee?", [[NSNumberFormatter coinFormatter] stringFromNumber: fee]];
	NSInteger		alertResult;
	bool			feeAccepted = false;

	alertResult = [NSAlert presentModalAlertWithTitle: @"Confirm transaction fee" defaultButton: @"Cancel" alternateButton: @"Yes" infoText: infoText style: NSWarningAlertStyle];
	if (alertResult == NSAlertSecondButtonReturn)
		feeAccepted = true;

	return feeAccepted;
}

void bridge_sig_InitMessage(
	const char			*inMessage)
{
	[[NSNotificationCenter defaultCenter] postNotificationName: DCNotification_InitMessage object: nil userInfo: @{ @"message" : [NSString stringWithUTF8String: inMessage]}];
}

