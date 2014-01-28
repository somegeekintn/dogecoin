//
//  NSAlert+Moon.h
//  Moon
//
//  Created by Casey Fleser on 1/24/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSAlert (Moon)

+ (NSInteger)			presentModalAlertWithTitle: (NSString *) inTitle
							defaultButton: (NSString *) inDefaultText
							alternateButton: (NSString *) inAlternateText
							infoText: (NSString *) inInfoText
							style: (NSAlertStyle) inStyle;

@end
