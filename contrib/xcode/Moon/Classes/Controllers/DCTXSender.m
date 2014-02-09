//
//  DCTXSender.m
//  Moon
//
//  Created by Casey Fleser on 1/22/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCTXSender.h"
#import "DCAddress.h"
#import "DCBridge.h"
#import "DCClient.h"
#import "DCDataManager.h"
#import "DCQRViewController.h"
#import "DCConsts.h"
#import "NSAlert+Moon.h"
#import "NSNumberFormatter+Moon.h"
#import "NSString+Moon.h"

@interface DCTXSender()

@property (nonatomic, assign) BOOL		canSend;

@end


@implementation DCTXSender

@synthesize canSend = _canSend;

- (void) updateCanSend
{
	BOOL	canSend = NO;
	
	if ([[self.addressField objectValue] count] && [self.amountField doubleValue] > 0.0) {
		canSend = YES;
	}
	
	self.canSend = canSend;
}

- (void) clearFields
{
	[self.addressField setStringValue: @""];
	[self.amountField setStringValue: @""];
}

#pragma mark - NSTextFieldDelegate

- (BOOL) control: (NSControl *) inControl
	textShouldEndEditing: (NSText *) inFieldEditor
{
	[self updateCanSend];
	
	return YES;
}

#pragma mark - NSTokenFieldDelegate

- (NSArray *) tokenField: (NSTokenField *) inTokenField
	completionsForSubstring: (NSString *) inSubstring
	indexOfToken: (NSInteger) inTokenIndex
	indexOfSelectedItem: (NSInteger *) inSelectedIndex
{
	NSMutableSet	*matches = [[[DCDataManager sharedManager].client addressesContaining: inSubstring mine: NO] mutableCopy];
	NSSet			*refinedMatches;
	NSMutableArray	*sortedMatches = [NSMutableArray array];
	NSMutableArray	*tokenizedMatches = [NSMutableArray array];
	NSArray			*workingMatches;
	
	refinedMatches = [matches filteredSetUsingPredicate: [NSPredicate predicateWithFormat: @"label beginswith[cd] %@", inSubstring]];
	workingMatches = [refinedMatches allObjects];
	workingMatches = [workingMatches sortedArrayUsingDescriptors: @[[NSSortDescriptor sortDescriptorWithKey: @"label" ascending: YES]]];
	[sortedMatches addObjectsFromArray: workingMatches];
	[matches minusSet: refinedMatches];

	refinedMatches = [matches filteredSetUsingPredicate: [NSPredicate predicateWithFormat: @"address beginswith[cd] %@", inSubstring]];
	workingMatches = [refinedMatches allObjects];
	workingMatches = [workingMatches sortedArrayUsingDescriptors: @[[NSSortDescriptor sortDescriptorWithKey: @"address" ascending: YES]]];
	[sortedMatches addObjectsFromArray: workingMatches];
	[matches minusSet: refinedMatches];
	
	workingMatches = [matches allObjects];
	workingMatches = [workingMatches sortedArrayUsingDescriptors: @[
		[NSSortDescriptor sortDescriptorWithKey: @"address" ascending: YES],
		[NSSortDescriptor sortDescriptorWithKey: @"address" ascending: YES]]
	];
	[sortedMatches addObjectsFromArray: workingMatches];

	for (DCAddress *address in sortedMatches) {
		[tokenizedMatches addObject: [address tokenizedAddress]];
	}
	
	// until we figure out how to set the completion like Mail.app we'll just not select an item
	*inSelectedIndex = -1;
	
	return tokenizedMatches;
}

- (NSArray *) tokenField: (NSTokenField *) inTokenField
	shouldAddObjects: (NSArray *) inTokens
	atIndex: (NSUInteger) inIndex
{
	NSMutableArray		*acceptableTokens = [NSMutableArray array];
	NSString			*coinAddress, *tokenizedAddress;
	
	for (NSString *testAddress in inTokens) {
		tokenizedAddress = testAddress;
		coinAddress = [tokenizedAddress stringByExtractingCoinAddress];
		
		if (coinAddress == nil) {				// not an tokenized addressbook string, see if we can match one
			DCAddress		*address = [[DCDataManager sharedManager].client addressWithCoinAddressOrLabel: tokenizedAddress];

			if (address != nil) {
				tokenizedAddress = [address tokenizedAddress];
			}
			else {								// perhaps just a plan coin address then?
				if (![[DCBridge sharedBridge] validateAddress: tokenizedAddress]) {
					tokenizedAddress = nil;		// nope
				}
			}
		}
		
		if (tokenizedAddress != nil) {
			[acceptableTokens addObject: tokenizedAddress];
		}
	}
	
	return acceptableTokens;
}

#pragma mark - Getters / Setters

- (BOOL) canSend
{
	return _canSend;
}

- (void) setCanSend: (BOOL) inCanSend
{
	if (_canSend != inCanSend) {
		[self willChangeValueForKey: @"canSend"];
		_canSend = inCanSend;
		[self didChangeValueForKey: @"canSend"];
	}
}

#pragma mark - Sheet Delegate

- (void) didEndSheet: (NSWindow *) inWindow
	returnCode: (NSInteger) inReturnCode
	contextInfo: (void *) inContextInfo
{
	[inWindow orderOut: nil];
}

#pragma mark - DCQRDelegate

- (void) didReadCode: (NSString *) inQRCode
	withQRCodeController: (DCQRViewController *) inController
{
	NSMutableArray			*tokens = [[self.addressField objectValue] mutableCopy];
	
	[self.qrViewController dismissPopover: self];

	[tokens addObject: inQRCode];
	[self.addressField setObjectValue: tokens];
}

#pragma mark - Handlers

- (void) handleSendButton: (id) inSender
{
	NSArray			*tokens = [self.addressField objectValue];
	NSMutableSet	*recipients = [NSMutableSet set];
	NSString		*coinAddress;
	int64_t			fixedPtTotal = 0;
	double			amount = [self.amountField doubleValue];
	
	for (NSString *tokenAddress in tokens) {
		coinAddress = [tokenAddress stringByExtractingCoinAddress];
		if (coinAddress == nil)
			coinAddress = tokenAddress;
		
		[recipients addObject: coinAddress];
		fixedPtTotal += (amount * kCoinMultiplier);
	}
	
	if ([recipients count]) {
		NSString		*displayList = [tokens componentsJoinedByString: @", "];
		NSDecimalNumber	*total = [NSDecimalNumber decimalNumberWithMantissa: fixedPtTotal exponent: kCoinExp isNegative: NO];
		NSString		*infoText = [NSString stringWithFormat: @"Are you sure you want to send a total of %@ to %@?",
										[[NSNumberFormatter coinFormatter] stringFromNumber: total], displayList];
		NSInteger		alertResult;
		
		alertResult = [NSAlert presentModalAlertWithTitle: @"Confirm transaction" defaultButton: @"Cancel" alternateButton: @"Yes" infoText: infoText style: NSInformationalAlertStyle];
		if (alertResult == NSAlertSecondButtonReturn) {
			[[DCBridge sharedBridge] sendCoins: amount to: [recipients allObjects]];
			[self clearFields];
			[NSApp endSheet: self.sendWindow];
		}
	}
}

- (void) handleCancelSendButton: (id) inSender
{
	[NSApp endSheet: self.sendWindow];
}

- (void) handleActivateSendButton: (id) inSender
{
	[NSApp beginSheet: self.sendWindow modalForWindow: self.mainWindow modalDelegate: self didEndSelector: @selector(didEndSheet:returnCode:contextInfo:) contextInfo: nil];
}

- (void) handleQRButton: (id) inSender
{
	[self.qrViewController presentPopoverFrom: self.qrButton withQRDelegate: self];
}

@end
