//
//  bridgehelper.cpp
//  Moon
//
//  Created by Casey Fleser on 1/13/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//
//	Obj-C gets a bit stabby about some of the redefinitions in the client
//	code like YES, NO, etc. This collection of functions mostly just
//	forwards function calls on their counterparts in the client

#include "bridgehelper.h"
#include "base58.h"
#include "bitcoinrpc.h"
#include "init.h"
#include "main.h"
#include "ui_interface.h"
#include "DCConsts.h"
#include <map>
#include <boost/random/mersenne_twister.hpp>
#include <boost/random/uniform_int_distribution.hpp>

#undef printf

boost::thread_group		gThreadGroup;

extern void		bridge_sig_WalletTransactionChanged(CFStringRef inWalletTxHash, bool inNotify);
extern void		bridge_sig_WalletTransactionDeleted(CFStringRef inWalletTxHash);
extern void		bridge_sig_AddressChanged(CFDictionaryRef inRawAddress);
extern void		bridge_sig_AddressDeleted(CFDictionaryRef inRawAddress);
extern void		bridge_sig_BlocksChanged();
extern void		bridge_sig_NumConnectionsChanged(int inNewNumConnections);
extern bool		bridge_sig_AskFee(int64 inFee);
extern void		bridge_sig_InitMessage(const char *inMessage);

void bridge_EstablishPrimaryConnections();
void bridge_EstablishSecondaryConnections();
void bridge_DestroyConnections();


#pragma mark - Notifications

static void NotifyTransactionChanged(
	CWallet					*inWallet,
	const uint256			&inHash,
	ChangeType				inStatus)
{
	CFStringRef		walletTxHash = CFStringCreateWithCString(kCFAllocatorDefault, inHash.GetHex().c_str(), kCFStringEncodingASCII);
	
	if (inStatus != CT_DELETED)
		bridge_sig_WalletTransactionChanged(walletTxHash, inStatus == CT_NEW ? true : false);
	else		// does this actually happen?
		bridge_sig_WalletTransactionDeleted(walletTxHash);
}

static void NotifyAddressBookChanged(
	CWallet					*inWallet,
	const CTxDestination	&inAddress,
	const std::string		&inLabel,
	bool					inIsMine,
	ChangeType				inStatus)
{
	CFMutableDictionaryRef	addressEntry = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
	CBitcoinAddress			address;
	int						isMine = inIsMine;
	
	address.Set(inAddress);
	CFDictionaryAddValue(addressEntry, CFSTR("label"), CFStringCreateWithCString(kCFAllocatorDefault, inLabel.c_str(), kCFStringEncodingASCII));
	CFDictionaryAddValue(addressEntry, CFSTR("address"), CFStringCreateWithCString(kCFAllocatorDefault, address.ToString().c_str(), kCFStringEncodingASCII));
	CFDictionaryAddValue(addressEntry, CFSTR("isMine"), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &isMine));

	if (inStatus != CT_DELETED)
		bridge_sig_AddressChanged(addressEntry);
	else
		bridge_sig_AddressDeleted(addressEntry);
}

// NotifyKeyStoreStatusChanged: Called when wallet is locked / unlocked
static void NotifyKeyStoreStatusChanged(
	CCryptoKeyStore			*inWallet)
{
//    OutputDebugStringF("NotifyKeyStoreStatusChanged\n");
}

static void NotifyBlocksChanged()
{
	bridge_sig_BlocksChanged();
}

static void NotifyNumConnectionsChanged(
	int						inNewNumConnections)
{
	bridge_sig_NumConnectionsChanged(inNewNumConnections);
}

// NotifyAlertChanged: alert presented, deleted, expired. inHash is alert identifier
static void NotifyAlertChanged(
	const uint256			&inHash,
	ChangeType				inStatus)
{
}

static bool ThreadSafeMessageBox(
	const std::string		&inMessage,
	const std::string		&inCaption,
	unsigned int			inStyle)
{
	printf("%s: %s\n", inCaption.c_str(), inMessage.c_str());
	
	return false;
}

static bool ThreadSafeAskFee(
	int64					inFeeRequired)
{
	bool	allowFee = false;
	
    if (inFeeRequired < CTransaction::nMinTxFee || inFeeRequired <= nTransactionFee || fDaemon)
		allowFee = true;
	else
		allowFee = bridge_sig_AskFee(inFeeRequired);

	return allowFee;
}

static void ThreadSafeHandleURI(
	const std::string		&inStrURI)
{
}

static void InitMessage(
	const std::string		&inMessage)
{
	bridge_sig_InitMessage(inMessage.c_str());
}

#pragma mark - Client Lifecycle

bool bridge_Initialize()
{
	bool					didInit;
	
	bridge_EstablishPrimaryConnections();
	didInit = AppInit2(gThreadGroup);
	if (didInit)
		bridge_EstablishSecondaryConnections();

	return didInit;
}

void bridge_Shutdown()
{
	bridge_DestroyConnections();
	
	gThreadGroup.interrupt_all();
	gThreadGroup.join_all();
	Shutdown();
}

void bridge_EstablishPrimaryConnections()
{
	// connect to all boost::signals2::signal

    uiInterface.NotifyBlocksChanged.connect(boost::bind(NotifyBlocksChanged));
	uiInterface.NotifyNumConnectionsChanged.connect(boost::bind(NotifyNumConnectionsChanged, _1));
	uiInterface.NotifyAlertChanged.connect(boost::bind(NotifyAlertChanged, _1, _2));
	
	uiInterface.ThreadSafeMessageBox.connect(ThreadSafeMessageBox);
    uiInterface.ThreadSafeAskFee.connect(ThreadSafeAskFee);
    uiInterface.ThreadSafeHandleURI.connect(ThreadSafeHandleURI);
    uiInterface.InitMessage.connect(InitMessage);
//	uiInterface.Translate.connect(Translate);
}

void bridge_EstablishSecondaryConnections()
{
    pwalletMain->NotifyTransactionChanged.connect(boost::bind(NotifyTransactionChanged, _1, _2, _3));
    pwalletMain->NotifyStatusChanged.connect(boost::bind(NotifyKeyStoreStatusChanged, _1));
    pwalletMain->NotifyAddressBookChanged.connect(boost::bind(NotifyAddressBookChanged, _1, _2, _3, _4, _5));
}

void bridge_DestroyConnections()
{
    uiInterface.ThreadSafeMessageBox.disconnect(ThreadSafeMessageBox);
    uiInterface.ThreadSafeAskFee.disconnect(ThreadSafeAskFee);
    uiInterface.ThreadSafeHandleURI.disconnect(ThreadSafeHandleURI);
    uiInterface.InitMessage.disconnect(InitMessage);

    uiInterface.NotifyBlocksChanged.disconnect(boost::bind(NotifyBlocksChanged));
    uiInterface.NotifyNumConnectionsChanged.disconnect(boost::bind(NotifyNumConnectionsChanged, _1));
    uiInterface.NotifyAlertChanged.disconnect(boost::bind(NotifyAlertChanged, _1, _2));

    pwalletMain->NotifyTransactionChanged.disconnect(boost::bind(NotifyTransactionChanged, _1, _2, _3));
    pwalletMain->NotifyStatusChanged.disconnect(boost::bind(NotifyKeyStoreStatusChanged, _1));
    pwalletMain->NotifyAddressBookChanged.disconnect(boost::bind(NotifyAddressBookChanged, _1, _2, _3, _4, _5));
}

#pragma mark - Utility

double bridge_getDifficultyForBlockIndex(
	const CBlockIndex		*inBlockindex)
{
	int		nShift = (inBlockindex->nBits >> 24) & 0xff;
	double	dDiff = (double)0x0000ffff / (double)(inBlockindex->nBits & 0x00ffffff);

	while (nShift < 29) {
		dDiff *= 256.0;
		nShift++;
	}
	while (nShift > 29) {
		dDiff /= 256.0;
		nShift--;
	}

	return dDiff;
}

double bridge_getNetworkHashesPerSecond()
{
	double		hashesPerSec = 0.0;
	
	if (pindexBest != NULL) {
		CBlockIndex		*pindexPrev = pindexBest;
		double			timeDiff;
		double			timePerBlock;
		int32_t			lookup = 120;
		
		if (lookup > pindexBest->nHeight)
			lookup = pindexBest->nHeight;
		for (int32_t idx=0; idx<lookup; idx++)
			pindexPrev = pindexPrev->pprev;

		timeDiff = pindexBest->GetBlockTime() - pindexPrev->GetBlockTime();
		timePerBlock = timeDiff / lookup;
		
		hashesPerSec = bridge_getDifficultyForBlockIndex(pindexBest) * pow(2.0, 32) / timePerBlock;
	}
	
    return hashesPerSec;
}

int bridge_generateMTRandom(
	unsigned int		inSeed,
	int					inRange)
{
	boost::random::mt19937						gen(inSeed);
    boost::random::uniform_int_distribution<>	dist(1, inRange);
	
    return dist(gen);
}

// Note: This function should mirror GetBlockValue in main.cpp which I would
// use directly but it's declared static and I don't want to alter the base
// source in any way. In any case it's only used to total the number of minted
// coins so it's not truly critical.

int64 bridge_getBlockMintedValue(
	int					inHeight,
	uint256				inPrevHash)
{
	int64			nSubsidy = 10000 * COIN;
	std::string		cseed_str = inPrevHash.ToString().substr(7,7);
	const char		*cseed = cseed_str.c_str();
	long			seed = hex2long(cseed);
	int				rand = bridge_generateMTRandom(seed, 999999);

	if (!inHeight) {			// the genesis block actual has a value of 88
		nSubsidy = 88 * COIN;
	}
	else if (inHeight < 100000) {
		nSubsidy = (1 + rand) * COIN;
	}
	else if (inHeight < 200000) {
		rand = bridge_generateMTRandom(seed, 499999);
		nSubsidy = (1 + rand) * COIN;
	}
	else if (inHeight < 300000) {
		cseed_str = inPrevHash.ToString().substr(6,7);
		cseed = cseed_str.c_str();
		seed = hex2long(cseed);
		rand = bridge_generateMTRandom(seed, 249999);
		nSubsidy = (1 + rand) * COIN;
	}
	else if (inHeight < 400000) {
		rand = bridge_generateMTRandom(seed, 124999);
		nSubsidy = (1 + rand) * COIN;
	}
	else if (inHeight < 500000) {
		rand = bridge_generateMTRandom(seed, 62499);
		nSubsidy = (1 + rand) * COIN;
	}
	else if (inHeight < 600000) {
		cseed_str = inPrevHash.ToString().substr(6,7);
		cseed = cseed_str.c_str();
		seed = hex2long(cseed);
		rand = bridge_generateMTRandom(seed, 31249);
		nSubsidy = (1 + rand) * COIN;
	}

	return nSubsidy;
}

void bridge_populateWalletTXListWithWalletTX(
	CFMutableArrayRef		ioWalletTXList,
	const CWalletTx			&inWalletTX)
{
	std::string										walletTXHash = inWalletTX.GetHash().GetHex();
	int64_t											walletTXTime = inWalletTX.GetTxTime();
	int64_t											nFee;
	std::string										sentAccountStr;
	std::list<std::pair<CTxDestination, int64> >	listReceived;
	std::list<std::pair<CTxDestination, int64> >	listSent;
	CBlockIndex										*txBlockIndex = NULL;
	int												depth = inWalletTX.GetDepthInMainChain(txBlockIndex);
	int												confirmed = inWalletTX.IsConfirmed();
	bool											allFromMe = true;
	bool											allToMe = true;

	inWalletTX.GetAmounts(listReceived, listSent, nFee, sentAccountStr);

	// test for special case where coins are sent to self
	BOOST_FOREACH(const CTxOut& txout, inWalletTX.vout)
		allToMe = allToMe && pwalletMain->IsMine(txout);
	BOOST_FOREACH(const CTxIn& txin, inWalletTX.vin)
		allFromMe = allFromMe && pwalletMain->IsMine(txin);

	if (allFromMe && allToMe) {
		BOOST_FOREACH(const PAIRTYPE(CTxDestination, int64)& s, listSent) {
			CFMutableDictionaryRef	walletTX = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
			int						walletCategory = eCoinWalletCategory_Move;
			int64_t					amount = 0;
			
			CFDictionaryAddValue(walletTX, CFSTR("account"), CFStringCreateWithCString(kCFAllocatorDefault, sentAccountStr.c_str(), kCFStringEncodingASCII));
			CFDictionaryAddValue(walletTX, CFSTR("address"), CFStringCreateWithCString(kCFAllocatorDefault, CBitcoinAddress(s.first).ToString().c_str(), kCFStringEncodingASCII));
			CFDictionaryAddValue(walletTX, CFSTR("category"), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &walletCategory));
			CFDictionaryAddValue(walletTX, CFSTR("amount"), CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &amount));
			CFDictionaryAddValue(walletTX, CFSTR("fee"), CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &nFee));
			CFDictionaryAddValue(walletTX, CFSTR("txid"), CFStringCreateWithCString(kCFAllocatorDefault, walletTXHash.c_str(), kCFStringEncodingASCII));
			CFDictionaryAddValue(walletTX, CFSTR("time"), CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &walletTXTime));
			CFDictionaryAddValue(walletTX, CFSTR("confirmed"), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &confirmed));
			CFDictionaryAddValue(walletTX, CFSTR("depth"), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &depth));
			if (txBlockIndex != NULL)
				CFDictionaryAddValue(walletTX, CFSTR("block"), CFStringCreateWithCString(kCFAllocatorDefault, txBlockIndex->phashBlock->GetHex().c_str(), kCFStringEncodingASCII));
			CFArrayAppendValue(ioWalletTXList, walletTX);
		}
	}
	else {
		// Sent
		if (!listSent.empty() || nFee != 0) {					// sent
			BOOST_FOREACH(const PAIRTYPE(CTxDestination, int64)& s, listSent) {
				CFMutableDictionaryRef	walletTX = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
				int						walletCategory = eCoinWalletCategory_Send;
				int64_t					amount = s.second;
				
				CFDictionaryAddValue(walletTX, CFSTR("account"), CFStringCreateWithCString(kCFAllocatorDefault, sentAccountStr.c_str(), kCFStringEncodingASCII));
				CFDictionaryAddValue(walletTX, CFSTR("address"), CFStringCreateWithCString(kCFAllocatorDefault, CBitcoinAddress(s.first).ToString().c_str(), kCFStringEncodingASCII));
				CFDictionaryAddValue(walletTX, CFSTR("category"), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &walletCategory));
				CFDictionaryAddValue(walletTX, CFSTR("amount"), CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &amount));
				CFDictionaryAddValue(walletTX, CFSTR("fee"), CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &nFee));
				CFDictionaryAddValue(walletTX, CFSTR("txid"), CFStringCreateWithCString(kCFAllocatorDefault, walletTXHash.c_str(), kCFStringEncodingASCII));
				CFDictionaryAddValue(walletTX, CFSTR("time"), CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &walletTXTime));
				CFDictionaryAddValue(walletTX, CFSTR("confirmed"), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &confirmed));
				CFDictionaryAddValue(walletTX, CFSTR("depth"), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &depth));
				if (txBlockIndex != NULL)
					CFDictionaryAddValue(walletTX, CFSTR("block"), CFStringCreateWithCString(kCFAllocatorDefault, txBlockIndex->phashBlock->GetHex().c_str(), kCFStringEncodingASCII));
				CFArrayAppendValue(ioWalletTXList, walletTX);
			}
		}

		if (listReceived.size() > 0) {							// received
			BOOST_FOREACH(const PAIRTYPE(CTxDestination, int64)& r, listReceived) {
				CFMutableDictionaryRef	walletTX = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
				int						walletCategory = eCoinWalletCategory_Receive;
				int64_t					amount = r.second;
				std::string				receiveAccountStr;
				
				if (pwalletMain->mapAddressBook.count(r.first))
					receiveAccountStr = pwalletMain->mapAddressBook[r.first];
			
				if (inWalletTX.IsCoinBase()) {
					if (depth < 1)
						walletCategory = eCoinWalletCategory_Orphan;
					else if (inWalletTX.GetBlocksToMaturity() > 0)
						walletCategory = eCoinWalletCategory_Immature;
					else
						walletCategory = eCoinWalletCategory_Generated;
				}

				CFDictionaryAddValue(walletTX, CFSTR("account"), CFStringCreateWithCString(kCFAllocatorDefault, receiveAccountStr.c_str(), kCFStringEncodingASCII));
				CFDictionaryAddValue(walletTX, CFSTR("address"), CFStringCreateWithCString(kCFAllocatorDefault, CBitcoinAddress(r.first).ToString().c_str(), kCFStringEncodingASCII));
				CFDictionaryAddValue(walletTX, CFSTR("category"), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &walletCategory));
				CFDictionaryAddValue(walletTX, CFSTR("amount"), CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &amount));
				CFDictionaryAddValue(walletTX, CFSTR("txid"), CFStringCreateWithCString(kCFAllocatorDefault, walletTXHash.c_str(), kCFStringEncodingASCII));
				CFDictionaryAddValue(walletTX, CFSTR("time"), CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &walletTXTime));
				CFDictionaryAddValue(walletTX, CFSTR("confirmed"), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &confirmed));
				CFDictionaryAddValue(walletTX, CFSTR("depth"), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &depth));
				if (txBlockIndex != NULL)
					CFDictionaryAddValue(walletTX, CFSTR("block"), CFStringCreateWithCString(kCFAllocatorDefault, txBlockIndex->phashBlock->GetHex().c_str(), kCFStringEncodingASCII));
				CFArrayAppendValue(ioWalletTXList, walletTX);
			}
		}
	}
}

#pragma mark - Bridge functions

int32_t bridge_getBlockHeight()
{
	return nBestHeight;
}

CFStringRef bridge_getBlockHashAtHeight(
	int32_t		inHeight)
{
	CFStringRef		hash = NULL;
	
    if (inHeight >= 0 && inHeight <= nBestHeight) {
		CBlockIndex		*pblockindex = pindexBest;
		
		while (pblockindex != NULL && pblockindex->nHeight > inHeight)
			pblockindex = pblockindex->pprev;
		
		if (pblockindex != NULL) {
			hash = CFStringCreateWithCString(kCFAllocatorDefault, pblockindex->phashBlock->GetHex().c_str(), kCFStringEncodingASCII);
		}
	}
	
    return hash;
}

CFDictionaryRef bridge_getBlockWithHash(
	const char			*inHash)
{
	CFMutableDictionaryRef	blockInfo = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
	CFMutableArrayRef		txList = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
    std::string				strHash = inHash;
    uint256					blockHash(strHash);
    CBlock					block;
    CBlockIndex				*blockIndex;
	int64_t					mintedValue = 0;
	int64_t					int64Val;
	double					doubleVal;
	uint256					prevHash = 0;
	
	// --- similar to getblock in bitcoinrpc.cpp
	
	blockIndex = mapBlockIndex[blockHash];
	block.ReadFromDisk(blockIndex);

	if (blockIndex->pprev)
		prevHash = blockIndex->pprev->GetBlockHash();
	mintedValue = bridge_getBlockMintedValue(blockIndex->nHeight, prevHash);

	CFDictionaryAddValue(blockInfo, CFSTR("hash"), CFStringCreateWithCString(kCFAllocatorDefault, block.GetHash().GetHex().c_str(), kCFStringEncodingASCII));
	
	int64Val = ::GetSerializeSize(block, SER_NETWORK, PROTOCOL_VERSION);
	CFDictionaryAddValue(blockInfo, CFSTR("size"), CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &int64Val));
	CFDictionaryAddValue(blockInfo, CFSTR("height"), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &blockIndex->nHeight));
	CFDictionaryAddValue(blockInfo, CFSTR("merkleroot"), CFStringCreateWithCString(kCFAllocatorDefault, block.hashMerkleRoot.GetHex().c_str(), kCFStringEncodingASCII));
    BOOST_FOREACH(const CTransaction&tx, block.vtx) {
		CFArrayAppendValue(txList, CFStringCreateWithCString(kCFAllocatorDefault, tx.GetHash().GetHex().c_str(), kCFStringEncodingASCII));
	}
	CFDictionaryAddValue(blockInfo, CFSTR("tx"), txList);

	int64Val = block.GetBlockTime();
	CFDictionaryAddValue(blockInfo, CFSTR("time"), CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &int64Val));
	CFDictionaryAddValue(blockInfo, CFSTR("nonce"), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &block.nNonce));
	CFDictionaryAddValue(blockInfo, CFSTR("bits"), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &block.nBits));
	
	doubleVal = bridge_getDifficultyForBlockIndex(blockIndex);
	CFDictionaryAddValue(blockInfo, CFSTR("difficulty"), CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &doubleVal));
	CFDictionaryAddValue(blockInfo, CFSTR("minted"), CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &mintedValue));

	return blockInfo;
}

CFArrayRef bridge_getWalletTransactions()	// See ListTransactions
{
	CFMutableArrayRef		walletTXList = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);

    for (std::map<uint256, CWalletTx>::iterator it = pwalletMain->mapWallet.begin(); it != pwalletMain->mapWallet.end(); ++it) {
		const CWalletTx									&wtx = (*it).second;

		bridge_populateWalletTXListWithWalletTX(walletTXList, wtx);
    }
	
	return walletTXList;
}

CFArrayRef bridge_getWalletTransactionsWithHash(
	const char				*inTransactionHash)
{
	CFMutableArrayRef		walletTXList = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
	uint256					txHash(inTransactionHash);
	const CWalletTx			&wtx = pwalletMain->mapWallet[txHash];

	bridge_populateWalletTXListWithWalletTX(walletTXList, wtx);

	return walletTXList;
}

CFDictionaryRef bridge_sendCoins(
	CFArrayRef				inRecipients,
	double					amount)
{
	CFMutableDictionaryRef						response = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
	CFStringRef									rxAddressRef;
	CFIndex										rxCount = CFArrayGetCount(inRecipients);
	int64_t										fixedPointAmount = amount * COIN;
	int64_t										totalAmount = 0;
	std::vector<std::pair<CScript, int64> >		vecSend;
	char										addrBuffer[64];
	int											result = eCoinSendResponse_Error_Unknown;
	
	for (CFIndex rxIdx=0; rxIdx<rxCount; rxIdx++) {
		rxAddressRef = (CFStringRef)CFArrayGetValueAtIndex(inRecipients, rxIdx);
		if (CFStringGetCString(rxAddressRef, addrBuffer, 64, kCFStringEncodingASCII)) {
			if (bridge_validateAddress(addrBuffer)) {
				CScript				scriptPubKey;
				CBitcoinAddress		coinAddress;
				
				coinAddress.SetString(addrBuffer);
				scriptPubKey.SetDestination(coinAddress.Get());
				vecSend.push_back(make_pair(scriptPubKey, fixedPointAmount));
				totalAmount += fixedPointAmount;
			}
		}
	}

	if (totalAmount > 0) {
		int64		walletBalance = pwalletMain->GetBalance();
		
		if (totalAmount <= walletBalance) {
			if (totalAmount + nTransactionFee <= walletBalance) {
				LOCK2(cs_main, pwalletMain->cs_wallet);

				CWalletTx		wtx;
				CReserveKey		keyChange(pwalletMain);
				int64			nFeeRequired = 0;
				std::string		strFailReason;
				bool			fCreated = pwalletMain->CreateTransaction(vecSend, wtx, keyChange, nFeeRequired, strFailReason);
				
				if (fCreated) {
					if (ThreadSafeAskFee(nFeeRequired)) {
						if (pwalletMain->CommitTransaction(wtx, keyChange)) {
							result = eCoinSendResponse_Success;
						}
						else {
							result = eCoinSendResponse_Error_TransactionCommitFailed;
						}
					}
					else {
						result = eCoinSendResponse_Canceled;
					}
				}
				else {
					if (totalAmount + nFeeRequired > walletBalance) {
						CFDictionaryAddValue(response, CFSTR("fee"), CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &nFeeRequired));
						result = eCoinSendResponse_Error_NSF_WithFees;
					}
					else {
						result = eCoinSendResponse_Error_TransactionCreateFailed;
					}
				}
			}
			else {
				CFDictionaryAddValue(response, CFSTR("fee"), CFNumberCreate(kCFAllocatorDefault, kCFNumberLongLongType, &nTransactionFee));
				result = eCoinSendResponse_Error_NSF_WithFees;
			}
		}
		else {
			result = eCoinSendResponse_Error_NSF;
		}
	}
	else {
		result = eCoinSendResponse_Error_InvalidAmount;
	}
	
	CFDictionaryAddValue(response, CFSTR("result"), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &result));

	return response;
}

CFArrayRef bridge_getAddressBook()
{
	CFMutableArrayRef		addressList = CFArrayCreateMutable(kCFAllocatorDefault, 0, NULL);
	CBitcoinAddress			address;
	int						isMine;

    BOOST_FOREACH(const PAIRTYPE(CTxDestination, std::string)& entry, pwalletMain->mapAddressBook) {
		CFMutableDictionaryRef	addressEntry = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
		
		address.Set(entry.first);
		isMine = IsMine(*pwalletMain, entry.first);
		CFDictionaryAddValue(addressEntry, CFSTR("label"), CFStringCreateWithCString(kCFAllocatorDefault, entry.second.c_str(), kCFStringEncodingASCII));
		CFDictionaryAddValue(addressEntry, CFSTR("address"), CFStringCreateWithCString(kCFAllocatorDefault, address.ToString().c_str(), kCFStringEncodingASCII));
		CFDictionaryAddValue(addressEntry, CFSTR("isMine"), CFNumberCreate(kCFAllocatorDefault, kCFNumberIntType, &isMine));
		CFArrayAppendValue(addressList, addressEntry);
   }

	return addressList;
}

bool bridge_validateAddress(
	const char			*inAddress)
{
    CBitcoinAddress		address(inAddress);

	return address.IsValid();
}

CFStringRef bridge_createNewRxAddress(
	const char			*inLabel)
{
	CFStringRef		address = NULL;
    CPubKey			newKey;

    if (!pwalletMain->IsLocked())
        pwalletMain->TopUpKeyPool();

	if (pwalletMain->GetKeyFromPool(newKey, false)) {
		CKeyID			keyID = newKey.GetID();
		std::string		strAccount(inLabel != NULL ? inLabel : "");

		pwalletMain->SetAddressBookName(keyID, strAccount);
		address = CFStringCreateWithCString(kCFAllocatorDefault, CBitcoinAddress(keyID).ToString().c_str(), kCFStringEncodingASCII);
	}

    return address;
}

bool bridge_createNewTxAddress(
	const char			*inAddress,
	const char			*inLabel)
{
	bool			didCreate = false;
	
	if (inAddress != NULL) {
		CBitcoinAddress	address(inAddress);

		if (address.IsValid()) {
			std::string		strLabel(inLabel != NULL ? inLabel : "");

			didCreate = pwalletMain->SetAddressBookName(address.Get(), strLabel);
		}
	}
	
    return didCreate;
}

bool bridge_setLabelForAddress(
	const char			*inLabel,
	const char			*inAddress)
{
	CBitcoinAddress		address(inAddress);
	bool				didChange = false;
	
    if (pwalletMain->mapAddressBook.count(address.Get())) {
		std::string		strLabel(inLabel != NULL ? inLabel : "");

		didChange = pwalletMain->SetAddressBookName(address.Get(), strLabel);
	}
	
	return didChange;
}

CFDictionaryRef bridge_getMiscInfo()
{
	CFMutableDictionaryRef	miscInfo = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, NULL, NULL);
	std::string				warnings = GetWarnings("statusbar");
	double					networkHPS = bridge_getNetworkHashesPerSecond();
	
	CFDictionaryAddValue(miscInfo, CFSTR("warnings"), CFStringCreateWithCString(kCFAllocatorDefault, warnings.c_str(), kCFStringEncodingASCII));
	CFDictionaryAddValue(miscInfo, CFSTR("networkhps"), CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &networkHPS));

	return miscInfo;
}

#pragma mark - RPC related

bool bridge_parseCommandLine(
	std::vector<std::string>	&outArgs,
	const std::string			&inStrCommand)
{
    enum CmdParseState
    {
        STATE_EATING_SPACES,
        STATE_ARGUMENT,
        STATE_SINGLEQUOTED,
        STATE_DOUBLEQUOTED,
        STATE_ESCAPE_OUTER,
        STATE_ESCAPE_DOUBLEQUOTED
    } state = STATE_EATING_SPACES;
    std::string curarg;
    BOOST_FOREACH(char ch, inStrCommand)
    {
        switch(state)
        {
        case STATE_ARGUMENT: // In or after argument
        case STATE_EATING_SPACES: // Handle runs of whitespace
            switch(ch)
            {
            case '"': state = STATE_DOUBLEQUOTED; break;
            case '\'': state = STATE_SINGLEQUOTED; break;
            case '\\': state = STATE_ESCAPE_OUTER; break;
            case ' ': case '\n': case '\t':
                if(state == STATE_ARGUMENT) // Space ends argument
                {
                    outArgs.push_back(curarg);
                    curarg.clear();
                }
                state = STATE_EATING_SPACES;
                break;
            default: curarg += ch; state = STATE_ARGUMENT;
            }
            break;
        case STATE_SINGLEQUOTED: // Single-quoted string
            switch(ch)
            {
            case '\'': state = STATE_ARGUMENT; break;
            default: curarg += ch;
            }
            break;
        case STATE_DOUBLEQUOTED: // Double-quoted string
            switch(ch)
            {
            case '"': state = STATE_ARGUMENT; break;
            case '\\': state = STATE_ESCAPE_DOUBLEQUOTED; break;
            default: curarg += ch;
            }
            break;
        case STATE_ESCAPE_OUTER: // '\' outside quotes
            curarg += ch; state = STATE_ARGUMENT;
            break;
        case STATE_ESCAPE_DOUBLEQUOTED: // '\' in double-quoted text
            if(ch != '"' && ch != '\\') curarg += '\\'; // keep '\' for everything but the quote and '\' itself
            curarg += ch; state = STATE_DOUBLEQUOTED;
            break;
        }
    }
    switch(state) // final state
    {
    case STATE_EATING_SPACES:
        return true;
    case STATE_ARGUMENT:
        outArgs.push_back(curarg);
        return true;
    default: // ERROR to end in one of the other states
        return false;
    }
}

void bridge_executeRPCRequest(
	const char				*inRawCommand,
	bridge_RPCCompletion	inCompletion)
{
	std::string					commandString(inRawCommand);
    std::vector<std::string>	args;
	
    if (bridge_parseCommandLine(args, commandString)) {
        json_spirit::Value		result;
        std::string				strPrint;
		
		try {
			result = tableRPC.execute(args[0], RPCConvertValues(args[0], std::vector<std::string>(args.begin() + 1, args.end())));

			if (result.type() == json_spirit::null_type)
				strPrint = "";
			else if (result.type() == json_spirit::str_type)
				strPrint = result.get_str();
			else
				strPrint = write_string(result, true);

			inCompletion(strPrint.c_str(), true);
		}
		catch (json_spirit::Object& objError) {
			try {	// Nice formatting for standard-format error
				int			code = find_value(objError, "code").get_int();
				std::string	message = find_value(objError, "message").get_str();
				char		errorBuf[1024];
				
				sprintf(errorBuf, "%s (code %d)", message.c_str(), code);
				inCompletion(errorBuf, false);
			}
			catch(std::runtime_error &) { // raised when converting to invalid type, i.e. missing code or message
				// Show raw JSON object
				inCompletion(write_string(json_spirit::Value(objError), false).c_str(), false);
			}
		}
		catch (std::exception& e) {
			char		errorBuf[1024];

			sprintf(errorBuf, "Error: %s", e.what());
			inCompletion(errorBuf, false);
		}
	}
	else {
		inCompletion("Parse error: unbalanced ' or \"", false);
	}
}

#pragma mark - Testing functions

//int64_t bridge_getActualMintedValue(
//	CBlock				&inBlock)
//{
//	CTxDB				txdb("r");
//	int64_t				mintedValue = 0;
//	int64_t				txFees = 0;
//	
//    BOOST_FOREACH(CTransaction &transaction, inBlock.vtx) {
//		int64_t		valueOut = transaction.GetValueOut();
//		
//		if (transaction.IsCoinBase()) {
//			mintedValue = valueOut;
//		}
//		else {
//			MapPrevTx					mapInputs;
//			std::map<uint256, CTxIndex>	mapUnused;
//			bool						fInvalid = false;
//
//			if (transaction.FetchInputs(txdb, mapUnused, false, false, mapInputs, fInvalid)) {
//				txFees += transaction.GetValueIn(mapInputs) - valueOut;
//			}
//		}
//	}
//
//	mintedValue -= txFees;
//
//	return mintedValue;
//}

//void bridge_testBlockValues()
//{
//	CBlockIndex		*blockIndex = pindexGenesisBlock;
//    CBlock			block;
//	uint256			prevHash = 0;
//	int64_t			expectedMintValue, actualMintValue;
//	int32_t			blockCount = 0;
//	int32_t			badBlockCount = 0;
//	
//	printf("--->>>Begin block value test\n");
//	
//	do {
//		if (blockIndex->pprev)
//			prevHash = blockIndex->pprev->GetBlockHash();
//			
//		block.ReadFromDisk(blockIndex, true);
//		expectedMintValue = bridge_getBlockMintedValue(blockIndex->nHeight, prevHash);
//		actualMintValue = bridge_getActualMintedValue(block);
//		blockCount++;
//		
//		if (expectedMintValue == actualMintValue) {
//			if (!(blockIndex->nHeight % 1000))
//				printf("%d okay\n", blockIndex->nHeight);
//		}
//		else {
//			printf("%d expected %lld actual %lld - %s\n", blockIndex->nHeight, expectedMintValue, actualMintValue, blockIndex->phashBlock->GetHex().c_str());
//			badBlockCount++;
//		}
//		blockIndex = blockIndex->pnext;
//	} while (blockIndex != NULL);
//
//	printf("--->>>End block value test\n");
//	printf("--->>>Tested %d blocks\n", blockCount);
//	printf("--->>>%d blocks incorrect\n", badBlockCount);
//}

void bridgetest_dumpBlocks()
{
	CBlockIndex		*blockIndex = pindexGenesisBlock;
	uint256			prevHash = 0;
	int64_t			expectedMintValue;
	int32_t			blockCount = 0;
	int32_t			badBlockCount = 0;
	time_t			lastBlockTime, thisBlockTime;
	int32_t			totalTime[10][10];
	int32_t			timeCount[10][10];
	
	lastBlockTime = 0;
	thisBlockTime = 0;
	memset(totalTime, 0, sizeof(int32_t)*10*10);
	memset(timeCount, 0, sizeof(int32_t)*10*10);
	
	printf("--->>>Begin block value test\n");
	
	do {
		if (blockIndex->pprev) {
			prevHash = blockIndex->pprev->GetBlockHash();
			
			expectedMintValue = bridge_getBlockMintedValue(blockIndex->nHeight, prevHash);
			thisBlockTime = blockIndex->nTime;

			if (lastBlockTime) {
				time_t		timeDiff = thisBlockTime - lastBlockTime;
				int32_t		truncVal = expectedMintValue / COIN;
				int32_t		valSection = truncVal / 100000;
				int32_t		blockSection = blockCount / 20000;
				
				if (timeDiff > 0 && timeDiff < 900) {
					if (valSection > 10)
						valSection = 9;
						
					totalTime[blockSection][valSection] += timeDiff;
					timeCount[blockSection][valSection]++;
				}
				else {
printf("time to %d: %ld\n", blockCount, timeDiff);
				}
			}
			
printf("%d\n", blockCount);
			lastBlockTime = thisBlockTime;
		}
		blockCount++;
		blockIndex = blockIndex->pnext;
	} while (blockIndex != NULL);

	for (int32_t blockSection=0; blockSection<5; blockSection++) {
		printf("--------------------------\n");
		printf("blocks %d - %d\n", blockSection * 20000, (blockSection * 20000) + 19999);
		for (int32_t valSection=0; valSection<10; valSection++) {
			printf("\tval %06d - %06d: %f secs (%d)\n", valSection * 100000, (valSection * 100000) + 99999, (double)totalTime[blockSection][valSection] / (double)timeCount[blockSection][valSection], timeCount[blockSection][valSection]);
		}
	}
	
	printf("--->>>End block value test\n");
	printf("--->>>Tested %d blocks\n", blockCount);
	printf("--->>>%d blocks incorrect\n", badBlockCount);
}


