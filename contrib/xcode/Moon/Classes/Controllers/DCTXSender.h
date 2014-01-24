//
//  DCTXSender.h
//  Dogecoin
//
//  Created by Casey Fleser on 1/22/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DCTXSender : NSObject <NSTokenFieldDelegate, NSTextFieldDelegate>

- (IBAction)		handleSendButton: (id) inSender;

@property (nonatomic, strong) IBOutlet NSTokenField		*addressField;
@property (nonatomic, strong) IBOutlet NSTextField		*amountField;
@property (nonatomic, readonly) BOOL					canSend;

@end
