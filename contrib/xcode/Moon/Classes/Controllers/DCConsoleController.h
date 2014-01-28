//
//  DCConsoleController.h
//  Moon
//
//  Created by Casey Fleser on 1/28/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DCConsoleController : NSObject

- (IBAction)				showConsole: (id) inSender;
- (IBAction)				clearOutput: (id) inSender;
- (IBAction)				processCommand: (id) inSender;

@property (nonatomic, strong) IBOutlet NSWindow				*consoleWindow;
@property (nonatomic, strong) IBOutlet NSTextView			*outputView;
@property (nonatomic, strong) IBOutlet NSTextField			*commandField;

@end
