//
//  DCTXSender.h
//  Moon
//
//  Created by Casey Fleser on 1/22/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCQRViewController.h"
#import <Foundation/Foundation.h>

@class DCQRViewController;

@interface DCTXSender : NSObject <NSTokenFieldDelegate, NSTextFieldDelegate, DCQRDelegate>

- (IBAction)		handleSendButton: (id) inSender;
- (IBAction)		handleCancelSendButton: (id) inSender;
- (IBAction)		handleActivateSendButton: (id) inSender;
- (IBAction)		handleQRButton: (id) inSender;

@property (nonatomic, strong) IBOutlet DCQRViewController	*qrViewController;
@property (nonatomic, strong) IBOutlet NSWindow				*mainWindow;
@property (nonatomic, strong) IBOutlet NSWindow				*sendWindow;
@property (nonatomic, strong) IBOutlet NSTokenField			*addressField;
@property (nonatomic, strong) IBOutlet NSTextField			*amountField;
@property (nonatomic, strong) IBOutlet NSButton				*qrButton;
@property (nonatomic, readonly) BOOL						canSend;

@end
