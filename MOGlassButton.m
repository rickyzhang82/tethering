//
//  MOGlassButton.m
//  SimplyTweet
//
//  Created by Hwee-Boon Yar on Jan/31/2010.
//  Copyright 2010 MotionObj. All rights reserved.
//
//  Enhanced by Daniel Sachse on 10/30/10.
//  Copyright 2010 coffeecoding. All rights reserved.
//

#import "MOGlassButton.h"
#import "ColorC.h"

@implementation MOGlassButton

@synthesize gradientLayer1;
@synthesize gradientLayer2;
@synthesize outlineLayer;


- (void)setupLayers {
	self.layer.cornerRadius = 8.0f;
	self.layer.masksToBounds = YES;
	self.layer.borderColor = [[UIColor colorFromRGBIntegers:100 green:103 blue:107 alpha:1.0f] CGColor];
	self.layer.borderWidth = 1.0f;

	self.gradientLayer1 = [[[CAGradientLayer alloc] init] autorelease];
	gradientLayer1.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height/2);
	gradientLayer1.colors = [NSArray arrayWithObjects:(id)[[UIColor colorFromRGBIntegers:255 green:255 blue:255 alpha:0.45f] CGColor], (id)[[UIColor colorFromRGBIntegers:255 green:235 blue:255 alpha:0.1f] CGColor], nil];
	[self.layer insertSublayer:gradientLayer1 atIndex:0];

	self.gradientLayer2 = [[[CAGradientLayer alloc] init] autorelease];
	gradientLayer2.frame = CGRectMake(0, self.frame.size.height/2, self.frame.size.width, self.frame.size.height/2);
	gradientLayer2.colors = [NSArray arrayWithObjects:(id)[[UIColor colorFromRGBIntegers:205 green:205 blue:205 alpha:0.0f] CGColor], (id)[[UIColor colorFromRGBIntegers:235 green:215 blue:215 alpha:0.2f] CGColor], nil];

	self.outlineLayer = [[[CALayer alloc] init] autorelease];
	outlineLayer.frame = CGRectMake(0, 1, self.frame.size.width, self.frame.size.height);
	outlineLayer.borderColor = [[UIColor colorFromRGBIntegers:255 green:255 blue:255 alpha:1.0f] CGColor];
	outlineLayer.borderWidth = 1.0f;
	outlineLayer.borderWidth = 1.0f;
	outlineLayer.opacity = 0.2f;
}


- (id)initWithFrame:(CGRect)aRect {
	if (self = [super initWithFrame:aRect]) {
		[self setupLayers];
	}

	return self;
}


- (void)awakeFromNib {
	[super awakeFromNib];
	[self setupLayers];
}


- (void)dealloc {
	self.gradientLayer1 = nil;
	self.gradientLayer2 = nil;
	self.outlineLayer = nil;

	[super dealloc];
}


- (void)layoutSubviews {
	[super layoutSubviews];

	gradientLayer1.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height/2);
	gradientLayer2.frame = CGRectMake(0, self.frame.size.height/2, self.frame.size.width, self.frame.size.height/2);
	outlineLayer.frame = CGRectMake(0, 1, self.frame.size.width, self.frame.size.height);
}

#pragma mark Default Button Background Colors

- (void)setupForStandardButtons {
	[self setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[self setTitleColor:[UIColor colorFromRGBIntegers:205 green:212 blue:220 alpha:1.0f] forState:UIControlStateDisabled];
	self.titleLabel.shadowOffset = CGSizeMake(0, -1);
	self.titleLabel.shadowColor = [UIColor colorFromRGBIntegers:192 green:73 blue:84 alpha:1.0f];
	self.titleLabel.font = [UIFont boldSystemFontOfSize:20];
}


- (void)setupAsGreenButton {
	[self setBackgroundColor:[UIColor colorFromRGBIntegers:24 green:157 blue:22 alpha:1.0f] forState:UIControlStateNormal];
	[self setBackgroundColor:[UIColor colorFromRGBIntegers:9 green:54 blue:14 alpha:1.0f] forState:UIControlStateHighlighted];
	[self setBackgroundColor:[UIColor colorFromRGBIntegers:24 green:157 blue:22 alpha:1.0f] forState:UIControlStateDisabled];
	[self setupForStandardButtons];
}


- (void)setupAsRedButton {
	[self setBackgroundColor:[UIColor colorFromRGBIntegers:160 green:1 blue:20 alpha:1.0f] forState:UIControlStateNormal];
	[self setBackgroundColor:[UIColor colorFromRGBIntegers:120 green:0 blue:0 alpha:1.0f] forState:UIControlStateHighlighted];
	[self setBackgroundColor:[UIColor colorFromRGBIntegers:160 green:1 blue:20 alpha:1.0f] forState:UIControlStateDisabled];
	[self setupForStandardButtons];
}

- (void)setupAsWhiteButton {
	[self setBackgroundColor:[UIColor colorFromRGBIntegers:160 green:160 blue:160 alpha:1.0f] forState:UIControlStateNormal];
	[self setBackgroundColor:[UIColor colorFromRGBIntegers:80 green:80 blue:80 alpha:1.0f] forState:UIControlStateHighlighted];
	[self setBackgroundColor:[UIColor colorFromRGBIntegers:160 green:160 blue:160 alpha:1.0f] forState:UIControlStateDisabled];
	[self setupForStandardButtons];
}


- (void)setupAsSmallGreenButton {
	[self setupAsGreenButton];
	self.titleLabel.font = [UIFont boldSystemFontOfSize:15];
	self.layer.cornerRadius = 4.0f;
}


- (void)setupAsSmallRedButton {
	[self setupAsRedButton];
	self.titleLabel.font = [UIFont boldSystemFontOfSize:15];
	self.layer.cornerRadius = 4.0f;
}

@end
