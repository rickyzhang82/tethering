//
//  ColorC.m
//  SOCKS
//
//  Created by Daniel Sachse on 10/30/10.
//  Copyright 2010 coffeecoding. All rights reserved.
//

#import "ColorC.h"

@implementation UIColor(ColorC)

// helper function
+(CGColorRef)createRGBValue:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGFloat components[4] = {red, green, blue, alpha};
	CGColorRef color = CGColorCreate(colorspace, components);
	CGColorSpaceRelease(colorspace);
	return color;
}

// create and return the new UIColor
+(UIColor *)colorFromRGBIntegers:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
	CGFloat redF    = red/255;
	CGFloat greenF    = green/255;
	CGFloat blueF    = blue/255;
	CGFloat alphaF    = alpha/1.0f;
	
	CGColorRef    color = [UIColor createRGBValue:redF green:greenF blue:blueF alpha:alphaF];
	
	return [UIColor colorWithCGColor:color];
}

@end
