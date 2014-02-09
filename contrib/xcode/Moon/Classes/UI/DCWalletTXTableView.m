//
//  DCWalletTXTableView.m
//  Moon
//
//  Created by Casey Fleser on 2/9/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCWalletTXTableView.h"
#import "DCWalletTXController.h"

@implementation DCWalletTXTableView

- (void) mouseDown: (NSEvent *) inEvent
{
	NSPoint			mouseLoc = [self convertPoint: [inEvent locationInWindow] fromView: nil];
	NSInteger		columnIndex = [self columnAtPoint: mouseLoc];
	BOOL			handled = NO;
	
	if (columnIndex != -1) {
		NSTableColumn		*selectedColumn = [[self tableColumns] objectAtIndex: columnIndex];
		
		if ([[selectedColumn identifier] isEqualToString: @"info"]) {
			NSInteger		rowIndex = [self rowAtPoint: mouseLoc];

			[self.walletTXController presentInfoFromView: self withFrame: [self frameOfCellAtColumn: columnIndex row: rowIndex] forArrangedItemIndex: rowIndex];
			handled = YES;
		}
	}

	if (!handled) {
		[super mouseDown: inEvent];
	}
}

@end
