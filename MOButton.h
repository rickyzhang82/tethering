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

@property(nonatomic,retain) UIColor* normalBackgroundColor;
@property(nonatomic,retain) UIColor* highlightedBackgroundColor;
@property(nonatomic,retain) UIColor* disabledBackgroundColor;

- (void)setBackgroundColor:(UIColor*)aColor forState:(UIControlState)aState;

@end
