//
//  DCConsoleController.m
//  Moon
//
//  Created by Casey Fleser on 1/28/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCConsoleController.h"
#import "DCBridge.h"

@implementation DCConsoleController

- (void) appendConsoleText: (NSString *) inText
	withColor: (NSColor *) inColor
{
	NSAttributedString	*attrText;
	NSDictionary		*attributes;
	
	attributes = @{
		NSFontAttributeName : [NSFont fontWithName: @"Monaco" size: 9.0],
		NSForegroundColorAttributeName : inColor
	};
	attrText = [[NSAttributedString alloc] initWithString: [inText stringByAppendingString: @"\n"] attributes: attributes];
	[[self.outputView textStorage] appendAttributedString: attrText];
	[self.outputView scrollRangeToVisible: NSMakeRange([[self.outputView string] length], 0)];
}

- (void) showConsole: (id) inSender
{
	[self.consoleWindow makeKeyAndOrderFront: self];
}

- (IBAction) clearOutput: (id) inSender
{
	[self.outputView setString: @""];
}

- (IBAction) processCommand: (id) inSender
{
	NSString		*rpcCommand = [self.commandField stringValue];
	
	[self appendConsoleText: rpcCommand withColor: [NSColor whiteColor]];
	[[DCBridge sharedBridge] executeRPCRequest: rpcCommand completion: ^(NSString *inResponse, BOOL inSucceeded) {
		[self appendConsoleText: inResponse withColor: inSucceeded ? [NSColor greenColor] : [NSColor redColor]];
	}];
	[self.commandField setStringValue: @""];
}

@end
