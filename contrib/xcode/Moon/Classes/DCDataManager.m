//
//  DCDataManager.m
//  Dogecoin
//
//  Created by Casey Fleser on 1/14/14.
//  Copyright (c) 2014 Dogecoin Developers. All rights reserved.
//

#import "DCDataManager.h"
#import "DCBlockInfo.h"
#import "DCBridge.h"
#import "DCInfo.h"


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
@synthesize info = _info;

+ (DCDataManager *) sharedManager
{
	return sSharedManager;
}

- (DCInfo *) info
{
	if (_info == nil)
		_info = [DCInfo infoInContext: self.defaultContext];

    return _info;
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
			self.rootContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
			self.rootContext.persistentStoreCoordinator = coordinator;
			[self.rootContext setUndoManager: nil];
			
			_defaultContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
			_defaultContext.parentContext = self.rootContext;
			[_defaultContext setUndoManager: nil];
			
			_editContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSMainQueueConcurrencyType];
			_editContext.parentContext = _defaultContext;
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
				
NSLog(@"--->%s", __PRETTY_FUNCTION__);
				if (![managedObjectContext save: &childError]) {
					[self handleCoreDataError: childError withMessage: @"Error saving default context"];
				}
				else {
					saveBlock = ^() {
						NSError			*rootError = nil;
						
						if (![self.rootContext save: &rootError]) {
							[self handleCoreDataError: rootError withMessage: @"Error saving root context"];
						}
						else {
							// root context is only for saving so it can safely reset after save
							[self.rootContext reset];
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

				NSLog(@"%@ failed validation for %@", NSStringFromClass([validationObject class]), validationKey);
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

#pragma mark - Data Gathering

- (void) reconcileBlockInfoWithDepth: (NSInteger) inReconcileDepth
	withInfoObjectID: (NSManagedObjectID *) inInfoObjectID
{
	NSManagedObjectContext	*reconcileContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];

	reconcileContext.parentContext = self.defaultContext;
	[reconcileContext setUndoManager: nil];
	[reconcileContext performBlockAndWait: ^{
		DCInfo				*info = (DCInfo *)[reconcileContext objectWithID: inInfoObjectID];
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

- (NSInteger) updateBlockInfoUntil: (NSDate *) inEndDate
	withInfoObjectID: (NSManagedObjectID *) inInfoObjectID
{
	NSManagedObjectContext	*updateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
	__block NSInteger		blockInfoCount;
	
	updateContext.parentContext = self.defaultContext;
	[updateContext setUndoManager: nil];
	[updateContext performBlockAndWait: ^{
		DCInfo				*info = (DCInfo *)[updateContext objectWithID: inInfoObjectID];
		DCBlockInfo			*blockInfo;

		blockInfoCount = [info.blockInfo count];
		while ([inEndDate timeIntervalSinceNow] > 0.0 && blockInfoCount < [[DCBridge sharedBridge] getBlockHeight] && self.blocksCanUpdate) {
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
			NSManagedObjectID		*infoID = [self.info objectID];
			NSInteger				startBlockInfoCount = [self.info.blockInfo count];

			self.blocksUpdating = YES;
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
				NSInteger		blockInfoCount = startBlockInfoCount;
				
				if (inReconcileDepth)
					[self reconcileBlockInfoWithDepth: inReconcileDepth withInfoObjectID: infoID];

				while (blockInfoCount < [[DCBridge sharedBridge] getBlockHeight] && self.blocksCanUpdate) {
					// the less time we allow to update the less efficient this is
					//	50mS: ~90 seconds per 1000 blocks
					//	100mS: ~60 seconds per 1000 blocks
					//	250mS: ~30 seconds per 1000 blocks
					//	400mS: ~25 seconds per 1000 blocks
					// chose 250mS to balance between updating and allowing the interface to update
					blockInfoCount = [self updateBlockInfoUntil: [NSDate dateWithTimeIntervalSinceNow: 0.25] withInfoObjectID: infoID];
NSLog(@"update %ld (best %ld)", blockInfoCount, [[DCBridge sharedBridge] getBlockHeight]);
				}
				
				self.blocksUpdating = NO;
NSLog(@"finished updating blocks");
			});
		}
	}
}

@end
