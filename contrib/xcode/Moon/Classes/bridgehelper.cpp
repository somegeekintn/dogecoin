//
//  bridgehelper.cpp
//  Dogecoin
//
//  Created by Casey Fleser on 1/13/14.
//  Copyright (c) 2014 Dogecoin Developers. All rights reserved.
//
//	Obj-C gets a bit stabby about some of the redefinitions in the client
//	code like YES, NO, etc. This collection of functions mostly just
//	forwards function calls on their counterparts in the client

#include "bitcoinrpc.h"
#include "init.h"
#include "main.h"
#include "ui_interface.h"
#include <map>

extern void		bridge_sig_BlocksChanged();
extern void		bridge_sig_NumConnectionsChanged(int newNumConnections);

void bridge_EstablishConnections();
void bridge_DestroyConnections();

static void NotifyBlocksChanged()
{
	bridge_sig_BlocksChanged();
}

static void NotifyNumConnectionsChanged(int newNumConnections)
{
	bridge_sig_NumConnectionsChanged(newNumConnections);
}

static void NotifyAlertChanged(const uint256 &hash, ChangeType status)
{
//	bridgesig_NumConnectionsChanged(newNumConnections);
}

static void ThreadSafeMessageBox(const std::string& message, const std::string& caption, int style)
{
	printf("%s: %s\n", caption.c_str(), message.c_str());
}

static bool ThreadSafeAskFee(int64 nFeeRequired, const std::string& strCaption)
{
	return false;
}

static void ThreadSafeHandleURI(const std::string& strURI)
{
}

static void InitMessage(const std::string &message)
{
	printf("--->>> InitMessage %s: %s\n", message.c_str());
}

static void QueueShutdown()
{
}

bool bridge_Initialize()
{
	bool	didInit = AppInit2();
	
	if (didInit)
		bridge_EstablishConnections();

	return didInit;
}

void bridge_Shutdown()
{
	bridge_DestroyConnections();
	
	Shutdown(NULL);
}

void bridge_EstablishConnections()
{
    uiInterface.NotifyBlocksChanged.connect(boost::bind(NotifyBlocksChanged));
    uiInterface.NotifyNumConnectionsChanged.connect(boost::bind(NotifyNumConnectionsChanged, _1));
    uiInterface.NotifyAlertChanged.connect(boost::bind(NotifyAlertChanged, _1, _2));
	
    uiInterface.ThreadSafeMessageBox.connect(ThreadSafeMessageBox);
    uiInterface.ThreadSafeAskFee.connect(ThreadSafeAskFee);
    uiInterface.ThreadSafeHandleURI.connect(ThreadSafeHandleURI);
    uiInterface.InitMessage.connect(InitMessage);
    uiInterface.QueueShutdown.connect(QueueShutdown);
//    uiInterface.Translate.connect(Translate);
}

void bridge_DestroyConnections()
{
    uiInterface.ThreadSafeMessageBox.disconnect(ThreadSafeMessageBox);
    uiInterface.ThreadSafeAskFee.disconnect(ThreadSafeAskFee);
    uiInterface.ThreadSafeHandleURI.disconnect(ThreadSafeHandleURI);
    uiInterface.InitMessage.disconnect(InitMessage);
    uiInterface.QueueShutdown.disconnect(QueueShutdown);

    uiInterface.NotifyBlocksChanged.disconnect(boost::bind(NotifyBlocksChanged));
    uiInterface.NotifyNumConnectionsChanged.disconnect(boost::bind(NotifyNumConnectionsChanged, _1));
    uiInterface.NotifyAlertChanged.disconnect(boost::bind(NotifyAlertChanged, _1, _2));

}

double bridge_nBitsToDifficulty(
	unsigned int		inNBits)
{
	int		nShift = (inNBits >> 24) & 0xff;
	double	dDiff = (double)0x0000ffff / (double)(inNBits & 0x00ffffff);

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

#pragma mark -

int32_t bridge_getBlockHeight()
{
	return nBestHeight;
}

std::string bridge_getBlockHashAtHeight(
	int32_t		inHeight)
{
	std::string		hash;
	
    if (inHeight >= 0 && inHeight <= nBestHeight) {
		CBlockIndex		*pblockindex = pindexBest;
		
		while (pblockindex != NULL && pblockindex->nHeight > inHeight)
			pblockindex = pblockindex->pprev;
		
		hash = pblockindex->phashBlock->GetHex();
	}
	
    return hash;
}

std::string bridge_getBlockWithHash(
	const char			*inHash)
{
    json_spirit::Object result;
    json_spirit::Array	txs;
	CTxDB				txdb("r");
    CBlock				block;
    CBlockIndex			*blockIndex;
    std::string			strHash = inHash;
	std::string			response;
    uint256				blockHash(strHash);
	int64_t				mintedValue = 0;
	int64_t				txFees = 0;
	
	// --- similar to getblock in bitcoinrpc.cpp
	
	blockIndex = mapBlockIndex[blockHash];
	block.ReadFromDisk(blockIndex, true);

    BOOST_FOREACH(CTransaction &transaction, block.vtx) {
		int64_t		valueOut = transaction.GetValueOut();
		
		if (transaction.IsCoinBase()) {
			mintedValue = valueOut;
		}
		else {
			MapPrevTx					mapInputs;
			std::map<uint256, CTxIndex>	mapUnused;
			bool						fInvalid = false;

			if (transaction.FetchInputs(txdb, mapUnused, false, false, mapInputs, fInvalid)) {
				txFees += transaction.GetValueIn(mapInputs) - valueOut;
			}
		}
	}

    result.push_back(json_spirit::Pair("hash", block.GetHash().GetHex()));
    result.push_back(json_spirit::Pair("size", (int)::GetSerializeSize(block, SER_NETWORK, PROTOCOL_VERSION)));
    result.push_back(json_spirit::Pair("height", blockIndex->nHeight));
    result.push_back(json_spirit::Pair("merkleroot", block.hashMerkleRoot.GetHex()));
    BOOST_FOREACH(const CTransaction&tx, block.vtx)
        txs.push_back(tx.GetHash().GetHex());
    result.push_back(json_spirit::Pair("tx", txs));
    result.push_back(json_spirit::Pair("time", (boost::int64_t)block.GetBlockTime()));
    result.push_back(json_spirit::Pair("nonce", (boost::uint64_t)block.nNonce));
    result.push_back(json_spirit::Pair("bits", (boost::uint64_t)block.nBits));
    result.push_back(json_spirit::Pair("difficulty", bridge_nBitsToDifficulty(block.nBits)));
    result.push_back(json_spirit::Pair("minted", mintedValue));
    result.push_back(json_spirit::Pair("fees", txFees));

	response = write_string((json_spirit::Value)result, false);

	return response;
}
