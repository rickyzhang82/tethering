//
//  ColorC.m
//  SOCKS
//
//  Created by Daniel Sachse on 10/30/10.
//  Copyright 2010 coffeecoding. All rights reserved.
//

#import "ColorC.h"

@implementation UIColor(ColorC)

// create and return the new UIColor
+(UIColor *)colorFromRGBIntegers:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
	CGFloat redF    = red/255.0f;
	CGFloat greenF    = green/255.0f;
	CGFloat blueF    = blue/255.0f;
	CGFloat alphaF    = alpha/1.0f;
	
	return [UIColor colorWithRed:redF green:greenF blue:blueF alpha:alphaF];
}

@end
