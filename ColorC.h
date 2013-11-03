//
//  ColorC.h
//  SOCKS
//
//  Created by Daniel Sachse on 10/30/10.
//  Copyright 2010 coffeecoding. All rights reserved.
//


#import <Foundation/Foundation.h>

@interface UIColor(ColorC)

+(UIColor *)colorFromRGBIntegers:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
+(CGColorRef)createRGBValue:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;

@end