//
//  DCPresenter.h
//  Moon
//
//  Created by Casey Fleser on 1/25/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DCPresenter : NSObject

@property (nonatomic, weak) IBOutlet NSWindow				*mainWindow;
@property (nonatomic, weak) IBOutlet NSToolbar				*toolbar;
@property (nonatomic, weak) IBOutlet NSView					*overlayView;
@property (nonatomic, weak) IBOutlet NSImageView			*moonView;
@property (nonatomic, weak) IBOutlet NSTextField			*progressLabel;
@property (nonatomic, weak) IBOutlet NSProgressIndicator	*progressIndicator;

@end
