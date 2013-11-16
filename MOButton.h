//
//  MOButton.h
//  SimplyTweet
//
//  Created by Hwee-Boon Yar on Feb/13/2010.
//  Copyright 2010 MotionObj. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface MOButton : UIButton {
	UIColor* normalBackgroundColor;
	UIColor* highlightedBackgroundColor;
	UIColor* disabledBackgroundColor;
}

@property(nonatomic,strong) UIColor* normalBackgroundColor;
@property(nonatomic,strong) UIColor* highlightedBackgroundColor;
@property(nonatomic,strong) UIColor* disabledBackgroundColor;

- (void)setBackgroundColor:(UIColor*)aColor forState:(UIControlState)aState;

@end
