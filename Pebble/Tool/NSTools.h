//
//  UITools.h
//  PetClaw
//
//  Created by yihang zhuang on 11/1/12.
//  Copyright (c) 2012 ZQ. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSDate-Utilities.h"
#import "NSViewExt.h"
#import <QuartzCore/QuartzCore.h>

//UINavigationController *gNav;
#ifdef __cplusplus
extern "C" {
#endif
    
    //NSTextfield
    NSTextField* createLable(NSString* str, float fontsize);
    //NSImageView
    NSImageView* createImageView(NSString* str);
    //date
    NSString *formatDateToString( NSDate *date );
    NSString *formatDateToStringALL( NSDate *date );
    NSDate *formatStringToDate( NSString *string );
    NSDate *formatStringToDateEx( NSString *string );
    NSDate *dateZero( NSDate *olddate );
    void setButtonColor(NSButton *button, NSColor *color);
    
    CABasicAnimation *opacityForever_Animation(float time);
    CABasicAnimation *opacityTimes_Animation(float repeatTimes ,float time);
    CABasicAnimation *moveX(float time, NSNumber *x);
    CABasicAnimation *moveY(float time, NSNumber *y);
    CABasicAnimation *myScale(NSNumber *Multiple, NSNumber *orginMultiple, float time ,float repeatTimes);
    CABasicAnimation *myRotate();
    CAAnimationGroup *groupAnimation(NSArray *animationAry, float time, float repeatTimes);
    CAKeyframeAnimation *keyframeAniamtion(CGMutablePathRef path, float time, float repeatTimes);
    CABasicAnimation *movepoint(CGPoint point);
    CABasicAnimation *rotation(float dur, float degree, int direction, int repeatCount);
    
    float titleBarHeight();
    int countWord(NSString *s);
    void shakeWindow (NSWindow* window);
    void exchangeOut (NSView* view);
    void writeTestData(NSString* str);
    int getAppearCount(NSString* rString, NSString* findString);
    
#ifdef __cplusplus
}
#endif
