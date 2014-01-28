//
//  DCQRViewController.m
//  Moon
//
//  Created by Casey Fleser on 1/26/14.
//  Copyright (c) 2014 Casey Fleser / @somegeekintn. All rights reserved.
//

#import "DCQRViewController.h"
#import <ZXingObjC/ZXingObjC.h>

@interface DCQRViewController () <ZXCaptureDelegate>

@property (nonatomic, strong) IBOutlet NSView	*captureView;
@property (nonatomic, strong) NSPopover			*qrPopover;
@property (nonatomic, strong) ZXCapture			*capture;
@property (nonatomic, weak) id <DCQRDelegate>	qrDelegate;

@end

@implementation DCQRViewController

- (void) presentPopoverFrom: (NSView *) inView
	withQRDelegate: (id <DCQRDelegate>) inQRDelegate
{
	self.qrDelegate = inQRDelegate;
    [self.qrPopover showRelativeToRect: [inView bounds] ofView: inView preferredEdge: CGRectMaxYEdge];
}

- (void) dismissPopover: (id) inSender
{
	[self.qrPopover performClose: inSender];
	self.qrDelegate = nil;
}

- (void) captureTeardown
{
	[self.capture stop];
	[self.capture.layer removeFromSuperlayer];
	self.capture.delegate = nil;
	self.capture = nil;
}

#pragma mark - NSPopoverDelegate

- (void) popoverWillShow: (NSNotification *) inNotification
{
	self.capture = [[ZXCapture alloc] init];
	self.capture.layer.frame = self.captureView.bounds;
	[self.captureView.layer addSublayer: self.capture.layer];
	self.capture.delegate = self;
}

- (void) popoverDidClose: (NSNotification *) inNotification
{
	[self captureTeardown];
}

#pragma mark - ZXCaptureDelegate Methods

- (void) captureResult: (ZXCapture *) inCapture
	result: (ZXResult *) inResult
{
	if (inResult != nil) {
		// We got a result. Display information about the result onscreen.
		if (self.qrDelegate != nil) {
			[self.qrDelegate didReadCode: inResult.text withQRCodeController: self];
		}
	}
}

#pragma mark - Setters / Getters

- (NSPopover *) qrPopover
{
    if (_qrPopover == nil) {
        // create and setup our popover
        _qrPopover = [[NSPopover alloc] init];
		_qrPopover.contentViewController = self;
        _qrPopover.animates = YES;
        _qrPopover.behavior = NSPopoverBehaviorTransient;
        _qrPopover.delegate = self;
    }

	return _qrPopover;
}

@end
