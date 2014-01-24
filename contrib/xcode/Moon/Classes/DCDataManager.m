//
//  DCDataManager.m
//  Dogecoin
//
//  Created by Casey Fleser on 1/14/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCDataManager.h"
#import "DCAddress.h"
#import "DCBlockInfo.h"
#import "DCBridge.h"
#import "DCClient.h"
#import "DCWallet.h"


static DCDataManager		*sSharedManager = nil;


@interface DCDataManager ()

@property (nonatomic, strong) NSManagedObjectModel			*managedObjectModel;
@property (nonatomic, strong) NSPersistentStoreCoordinator	*persistentStoreCoordinator;
@property (nonatomic, strong) NSManagedObjectContext		*rootContext;
@property (nonatomic, strong) NSTimer						*saveTimer;
@property (nonatomic, assign) BOOL							blocksCanUpdate;
@property (nonatomic, assign) BOOL							blocksUpdating;

@end


@implementation DCDataManager

@synthesize defaultContext = _defaultContext;
@synthesize editContext = _editContext;
@synthesize client = _client;

+ (DCDataManager *) sharedManager
{
	return sSharedManager;
}

- (DCClient *) client
{
	if (_client == nil)
		_client = [DCClient clientInContext: self.defaultContext];

    return _client;
}

- (void) startMonitor
{
	self.saveTimer = [NSTimer scheduledTimerWithTimeInterval: 30.0 target: self selector: @selector(saveAsNeeded:) userInfo: nil repeats: YES];
}

- (void) saveAsNeeded: (NSTimer *) inTimer
{
	[self saveObjectsAsync: YES];
}

- (NSManagedObjectContext *) defaultContext
{
	if (_defaultContext == nil) {
		NSPersistentStoreCoordinator	*coordinator = self.persistentStoreCoordinator;
		
		if (coordinator != nil) {
			dispatch_block_t		contextInitBlock;
			
			contextInitBlock = ^{
				self.rootContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
				self.rootContext.persistentStoreCoordinator = coordinator;
				[self.rootContext setUndoManager: nil];
				
				_defaultContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
				_defaultContext.parentContext = self.rootContext;
				[_defaultContext setUndoManager: nil];
				
				_editContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
				_editContext.parentContext = _defaultContext;
			};
			
			if ([NSThread isMainThread]) {
				contextInitBlock();
			}
			else {
				dispatch_sync(dispatch_get_main_queue(), contextInitBlock);
			}
		}
	}

    return _defaultContext;
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	sSharedManager = self;
	self.blocksCanUpdate = YES;
}

- (NSManagedObjectModel *) managedObjectModel
{

    if (_managedObjectModel == nil) {
		NSURL		*modelURL = [[NSBundle mainBundle] URLForResource: @"Moon" withExtension: @"momd"];

		_managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL: modelURL];
    }
	
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator
{
    if (_persistentStoreCoordinator == nil) {
		NSURL		*storeURL = [self persistentStoreURL];
		NSError		*cdError;
		
		_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
		if (![_persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType configuration: nil URL: storeURL
				options: @{ NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES } error: &cdError]) {
			NSURL		*movedStoreURL = [storeURL URLByAppendingPathExtension: @"bad"];
			
			NSLog(@"Core Data: Error %@, %@", cdError, [cdError userInfo]);
			NSLog(@"Will move old store and create new");
			
			[[NSFileManager defaultManager] removeItemAtURL: movedStoreURL error: nil];
			if (![[NSFileManager defaultManager] moveItemAtURL: storeURL toURL: movedStoreURL error: &cdError]) {
				NSLog(@"Failed with %@ trying to move %@ to %@", cdError, storeURL, movedStoreURL);
			}
			else if (![_persistentStoreCoordinator addPersistentStoreWithType: NSSQLiteStoreType configuration: nil URL: storeURL
				options: @{ NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES } error: &cdError]) {
				NSLog(@"Core Data: removed old store but still...");
				NSLog(@"Core Data: Error %@, %@", cdError, [cdError userInfo]);
			}
		}
    }
    
    return _persistentStoreCoordinator;
}

- (NSURL *) documentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory: NSApplicationSupportDirectory inDomains: NSUserDomainMask] lastObject];
}

- (NSURL *) persistentStoreURL
{
	NSURL		*appSupportURL = [[self documentsDirectory] URLByAppendingPathComponent: @"Moon" isDirectory: YES];
	
	[[NSFileManager defaultManager] createDirectoryAtURL: appSupportURL withIntermediateDirectories: YES attributes: nil error: nil];
	
	return [appSupportURL URLByAppendingPathComponent: @"Moon.sqlite"];
}

- (BOOL) persistentStoreExists
{
	return [[NSFileManager defaultManager] fileExistsAtPath: [[self persistentStoreURL] path]];
}

- (void) saveObjectsAsync: (BOOL) inAsync
{
    NSManagedObjectContext	*managedObjectContext = self.defaultContext;

	if (managedObjectContext != nil) {
		[managedObjectContext performBlockAndWait: ^() {
			if ([managedObjectContext hasChanges]) {
				NSError			*childError = nil;
				void			(^saveBlock)(void);
				
				if (![managedObjectContext save: &childError]) {
					[self handleCoreDataError: childError withMessage: @"Error saving default context"];
				}
				else {
					saveBlock = ^() {
						NSError			*rootError = nil;
						
						if (![self.rootContext save: &rootError]) {
							[self handleCoreDataError: rootError withMessage: @"Error saving root context"];
						}
					};
					
					if (inAsync)
						[self.rootContext performBlock: saveBlock];
					else
						[self.rootContext performBlockAndWait: saveBlock];
				}
			}
		}];
	}
}

- (void) handleCoreDataError: (NSError *) inError
	withMessage: (NSString *) inMessage
{
	NSDictionary		*errorInfo = [inError userInfo];
	
	if (inMessage != nil)
		NSLog(@"%@", inMessage);
	
	switch (inError.code) {
		case NSManagedObjectValidationError: {
				NSString			*validationObject = [errorInfo objectForKey: NSValidationObjectErrorKey];
				NSString			*validationKey = [errorInfo objectForKey: NSValidationKeyErrorKey];
				NSString			*validationValue = [errorInfo objectForKey: NSValidationValueErrorKey];

				NSLog(@"%@ failed validation for %@", NSStringFromClass([validationObject class]), validationKey);
				NSLog(@"---------------------------");
				NSLog(@"obj: %@", validationObject);
				NSLog(@"val: %@", validationValue);
				NSLog(@"---------------------------");
			}
			break;
		
		case NSValidationMissingMandatoryPropertyError: {
				NSString			*validationObject = [errorInfo objectForKey: NSValidationObjectErrorKey];
				NSString			*validationKey = [errorInfo objectForKey: NSValidationKeyErrorKey];

				NSLog(@"%@ missing mandatory property: %@", NSStringFromClass([validationObject class]), validationKey);
			}
			break;
		
		case NSValidationMultipleErrorsError:
			for (NSError *subError in [[inError userInfo] objectForKey: NSDetailedErrorsKey])
				[self handleCoreDataError: subError withMessage: nil];
			break;
		
		default:
			NSLog(@"error: %@", inError);
			break;
	}
}

- (BOOL) prepareToQuit: (NSApplication *) inSender
{
    NSManagedObjectContext	*managedObjectContext = self.defaultContext;
	BOOL					shouldQuit = YES;
	
	[self.saveTimer invalidate];
	self.saveTimer = nil;
	self.blocksCanUpdate = NO;
	
    if (managedObjectContext != nil) {
		if (![managedObjectContext commitEditing]) {
			shouldQuit = NO;
			NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
		}
		
		if ([managedObjectContext hasChanges]) {
			__block NSError		*error = nil;
			
			[managedObjectContext performBlockAndWait: ^() {
				if (![managedObjectContext save: &error]) {
					[self handleCoreDataError: error withMessage: @"Error saving default context"];
				}
				else {
					[self.rootContext performBlockAndWait: ^{
						if (![self.rootContext save: &error]) {
							[self handleCoreDataError: error withMessage: @"Error saving root context"];
						}
					}];
				}
			}];

			if (error != nil) {
				BOOL		result = [inSender presentError: error];
				
				if (result) {
					shouldQuit = NO;
				}
				else {
					NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
					NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
					NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
					NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
					NSAlert *alert = [[NSAlert alloc] init];
					[alert setMessageText:question];
					[alert setInformativeText:info];
					[alert addButtonWithTitle:quitButton];
					[alert addButtonWithTitle:cancelButton];

					NSInteger answer = [alert runModal];
					
					if (answer == NSAlertAlternateReturn) {
						shouldQuit = NO;
					}
				}
			}
		}
	}

    return shouldQuit;
}

#pragma mark - Client Interaction

- (void) clientInitializationComplete
{
	dispatch_async(dispatch_get_main_queue(), ^{
		[self updateBlockInfo: 1000];		// validate the last N blocks upon connect
		[self reconcileAddressBook];
		[self reconcileWallet];
	});
}

- (void) reconcileBlockInfoWithDepth: (NSInteger) inReconcileDepth
	withInfoObjectID: (NSManagedObjectID *) inInfoObjectID
{
	NSManagedObjectContext	*reconcileContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];

	reconcileContext.parentContext = self.defaultContext;
	[reconcileContext setUndoManager: nil];
	[reconcileContext performBlockAndWait: ^{
		DCClient				*info = (DCClient *)[reconcileContext objectWithID: inInfoObjectID];
		DCBlockInfo			*blockInfo;
		NSInteger			curBlockHeight = [info.blockInfo count] - 1;
		NSInteger			testHeight = curBlockHeight;

		for (;testHeight >= 0 && testHeight > curBlockHeight - inReconcileDepth; testHeight--) {
			blockInfo = [info blockInfoAtHeight: testHeight];
			if ([blockInfo passesValidation])
				break;
		}
		
		if (testHeight < curBlockHeight) {		// a fork or something like it. update as needed
			for (;testHeight<=curBlockHeight; curBlockHeight++) {
				[blockInfo updateWithHeight];
			}

			[info recalcCumulatives];
		}

		if ([reconcileContext hasChanges]) {
			NSError		*error;
			
			if (![reconcileContext save: &error]) {
				[self handleCoreDataError: error withMessage: [NSString stringWithFormat: @"Error saving context in %s", __PRETTY_FUNCTION__]];
			}
		}
	}];
}

- (NSInteger) updateBlockInfoFor: (NSTimeInterval) inUpdateTime
	withInfoObjectID: (NSManagedObjectID *) inInfoObjectID
{
	NSManagedObjectContext	*updateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
	__block NSInteger		blockInfoCount;
	
	updateContext.parentContext = self.defaultContext;
	[updateContext setUndoManager: nil];
	[updateContext performBlockAndWait: ^{
		DCClient				*info = (DCClient *)[updateContext objectWithID: inInfoObjectID];
		DCBlockInfo			*blockInfo;
		NSDate				*endTime;
		
		blockInfoCount = [info.blockInfo count];	// count should equal height + 1
		endTime = [NSDate dateWithTimeIntervalSinceNow: inUpdateTime];
		while ([endTime timeIntervalSinceNow] > 0.0 && blockInfoCount <= [[DCBridge sharedBridge] getBlockHeight] && self.blocksCanUpdate) {
			blockInfo = [DCBlockInfo blockInfoAtHeight: blockInfoCount inContext: updateContext];
			[info addBlockInfoObject: blockInfo];
			[info addToCumulatives: blockInfo];
			
			blockInfoCount++;
		}

		if ([updateContext hasChanges]) {
			NSError		*error;
			
			if (![updateContext save: &error]) {
				[self handleCoreDataError: error withMessage: [NSString stringWithFormat: @"Error saving context in %s", __PRETTY_FUNCTION__]];
			}
		}
	}];
	
	return blockInfoCount;
}

- (void) updateBlockInfo: (NSInteger) inReconcileDepth
{
	@synchronized(self) {
		if (!self.blocksUpdating) {
			@autoreleasepool {
				NSManagedObjectID		*infoID = [self.client objectID];
				NSInteger				startBlockInfoCount = [self.client.blockInfo count];

				self.blocksUpdating = YES;
				dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
					NSInteger				blockInfoCount = startBlockInfoCount;
					
					if (inReconcileDepth)
						[self reconcileBlockInfoWithDepth: inReconcileDepth withInfoObjectID: infoID];

					while (blockInfoCount <= [[DCBridge sharedBridge] getBlockHeight] && self.blocksCanUpdate) {
						blockInfoCount = [self updateBlockInfoFor: 0.10 withInfoObjectID: infoID];
NSLog(@"update %ld (best %ld)", blockInfoCount, [[DCBridge sharedBridge] getBlockHeight]);
					}
					
					self.blocksUpdating = NO;
				});
			}
		}
	}
	
	[self updateMiscInfo];
}

- (void) reconcileWallet
{
	NSArray			*walletTransactions = [[DCBridge sharedBridge] getWalletTransactions];
	
	[self.defaultContext performBlock: ^{
		[self.client.activeWallet reconcileWalletTransactions: walletTransactions];
	}];
}

- (void) updateWalletTrasactionWithHash: (NSString *) inWalletTxHash
{
	NSArray			*walletTransactions = [[DCBridge sharedBridge] getWalletTransactionsWithHash: inWalletTxHash];

	[self.defaultContext performBlock: ^{
		[self.client.activeWallet reconcileWalletTransactions: walletTransactions];
	}];
}

- (void) deleteWalletTrasactionWithHash: (NSString *) inWalletTxHash
{
	NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (void) reconcileAddressBook
{
	NSArray			*addressList = [[DCBridge sharedBridge] getAddressBook];
	
	[self.defaultContext performBlock: ^{
		DCAddress		*address;
#warning "todo: remove missing?"
// need to remove any addresses that are no longer found in the address
// book. since this should just be called at launch should we just nuke
// and reset the address book? bleh.
		for (NSDictionary *rawAddress in addressList) {
			address = [DCAddress updatedAddressFromRawEntry: rawAddress inContext: self.defaultContext];
			[self.client addAddressesObject: address];
		}
	}];
}

- (void) updateAddressEntry: (NSDictionary *) inRawAddress
{
	[self.defaultContext performBlock: ^{
		DCAddress		*address;
		
		address = [DCAddress updatedAddressFromRawEntry: inRawAddress inContext: self.defaultContext];
		[self.client addAddressesObject: address];
	}];
}

- (void) deleteAddressEntry: (NSDictionary *) inRawAddress
{
	[self.defaultContext performBlock: ^{
		DCAddress		*address = [DCAddress updatedAddressFromRawEntry: inRawAddress inContext: self.defaultContext];
		
		[self.defaultContext deleteObject: address];
	}];
}

- (void) updateMiscInfo
{
	NSDictionary		*miscInfo = [[DCBridge sharedBridge] getMiscInfo];
	NSNumber			*networkHPS = miscInfo[@"networkhps"];
	NSString			*warnings = miscInfo[@"warnings"];
	
	if (warnings == nil || ![warnings length])
		warnings = @"- none -";
	
	[self.defaultContext performBlock:^{
		self.client.networkMHS = @([networkHPS doubleValue] / 1000000.0);
		self.client.warnings = warnings;
	}];
}

- (void) setConnectionCount: (NSInteger) inNumConnections
{
	[self.defaultContext performBlock:^{
		self.client.numConnections = @(inNumConnections);
	}];
}

@end
