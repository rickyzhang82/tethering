//
//  MOButton.m
//  SimplyTweet
//
//  Created by Hwee-Boon Yar on Feb/13/2010.
//  Copyright 2010 MotionObj. All rights reserved.
//
//  Enhanced by Daniel Sachse on 10/30/10.
//  Copyright 2010 coffeecoding. All rights reserved.
//

#import "MOButton.h"

#import <QuartzCore/QuartzCore.h>

@implementation MOButton

@synthesize normalBackgroundColor;
@synthesize highlightedBackgroundColor;
@synthesize disabledBackgroundColor;

// Have to set up handlers for various touch events. Can't rely on UIButton.highlighted and enabled property because highlighted is still YES when touch up.
- (void)setupStateChangeHandlers {
	[self addTarget:self action:@selector(buttonUp:event:) forControlEvents:(UIControlEventTouchUpOutside|UIControlEventTouchUpInside|UIControlEventTouchCancel|UIControlEventTouchDragExit)];
	[self addTarget:self action:@selector(buttonDown:event:) forControlEvents:UIControlEventTouchDown|UIControlEventTouchDragEnter];
}


- (id)initWithFrame:(CGRect)aRect {
	if (self = [super initWithFrame:aRect]) {
		[self setupStateChangeHandlers];
	}

	return self;
}


- (void)awakeFromNib {
	[self setupStateChangeHandlers];
}


- (void)dealloc {
	self.normalBackgroundColor = nil;
	self.highlightedBackgroundColor = nil;
	self.disabledBackgroundColor = nil;

	[super dealloc];
}


- (void)setBackgroundColor:(UIColor*)aColor forState:(UIControlState)aState {
	switch (aState) {
		case UIControlStateNormal:
			self.normalBackgroundColor = aColor;
			if (self.enabled) self.layer.backgroundColor = self.normalBackgroundColor.CGColor;
			break;
		case UIControlStateHighlighted:
			self.highlightedBackgroundColor = aColor;
			break;
		case UIControlStateDisabled:
			self.disabledBackgroundColor = aColor;
			if (!self.enabled) self.layer.backgroundColor = self.disabledBackgroundColor.CGColor;
			break;
		default:
			break;
	}
}


- (void)setEnabled:(BOOL)yesOrNo {
	[super setEnabled:yesOrNo];
	self.layer.backgroundColor = yesOrNo? self.normalBackgroundColor.CGColor: self.disabledBackgroundColor.CGColor;
}

#pragma mark Events

- (void)buttonUp:(id)aButton event:(id)event {
	self.layer.backgroundColor = self.normalBackgroundColor.CGColor;
}


- (void)buttonDown:(id)aButton event:(id)event {
	self.layer.backgroundColor = self.highlightedBackgroundColor.CGColor;
}

@end
