//
//  UITools.m
//  PetClaw
//
//  Created by yihang zhuang on 11/1/12.
//  Copyright (c) 2012 ZQ. All rights reserved.
//

#import "NSTools.h"

#pragma mark NSTextField
NSTextField* createLable(NSString* str, float fontsize) {
    NSTextField* textField = [[NSTextField alloc]initWithFrame:NSMakeRect(0, 0, 100, fontsize+6)];
    textField.bordered = NO;
    textField.backgroundColor = [NSColor clearColor];
    textField.editable = NO;
    textField.alignment = NSLeftTextAlignment;
    textField.font = [NSFont systemFontOfSize:fontsize];
    textField.stringValue = str;;
    return textField;
}

NSImageView* createImageView(NSString* str) {
    NSImage* image = [NSImage imageNamed:str];
    NSImageView* imageView = [[NSImageView alloc]initWithFrame:NSMakeRect(0, 0, 20, 20)];
    imageView.image = image;
    imageView.width = image.size.width;
    imageView.height = image.size.height;
    return imageView;
}

#pragma mark date
NSString *formatDateToString( NSDate *date ){
    NSString *s = [NSString stringWithFormat:@"%04ld-%02ld-%02ld",
                   (long)date.year,(long)date.month,(long)date.day];
    return s;
}

NSString *formatDateToStringALL( NSDate *date ){
    NSString *s = [NSString stringWithFormat:@"%04ld-%02ld-%02ld %02ld:%02ld:%02ld",
                   (long)date.year,(long)date.month,(long)date.day,(long)date.hour,(long)date.minute,(long)date.seconds];
    return s;
}

NSDate *formatStringToDate( NSString *string ){
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setTimeZone:[NSTimeZone defaultTimeZone]];
    [dateFormat setDateFormat:@"yyyy-MM-dd"];
    NSDate *date = [dateFormat dateFromString:string];
    return date;
}

NSDate *formatStringToDateEx( NSString *string ){
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setTimeZone:[NSTimeZone defaultTimeZone]];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [dateFormat dateFromString:string];
    
    return date;
}

NSDate *dateZero( NSDate *olddate ){
    NSMutableString* string = [NSMutableString stringWithString:formatDateToStringALL(olddate)];
    [string replaceCharactersInRange:NSMakeRange(string.length-2, 2) withString:@"00"];
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setTimeZone:[NSTimeZone defaultTimeZone]];
    [dateFormat setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    NSDate *date = [dateFormat dateFromString:string];
    return date;
}

void setButtonColor(NSButton *button, NSColor *color) {
    if (color == nil) {
        color = [NSColor redColor];
    }
    
    int fontSize = 16;
    NSFont *font = [NSFont systemFontOfSize:fontSize];
    NSDictionary * attrs = [NSDictionary dictionaryWithObjectsAndKeys:font,
                            NSFontAttributeName,
                            color,
                            NSForegroundColorAttributeName,
                            nil];
    
    NSMutableAttributedString* attributedString = [[NSMutableAttributedString alloc] initWithString:[button title] attributes:attrs];
    [attributedString setAlignment:NSCenterTextAlignment range:NSMakeRange(0, [attributedString length])];
    [button setAttributedTitle:attributedString];
}


CABasicAnimation *opacityForever_Animation(float time) {//永久闪烁的动画
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue=[NSNumber numberWithFloat:1.0];
    animation.toValue=[NSNumber numberWithFloat:0.0];
    animation.autoreverses=YES;
    animation.duration=time;
    animation.repeatCount=FLT_MAX;
    animation.removedOnCompletion=NO;
    animation.fillMode=kCAFillModeForwards;
    return animation;
}

CABasicAnimation *opacityTimes_Animation(float repeatTimes ,float time) {//有闪烁次数的动画
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue=[NSNumber numberWithFloat:1.0];
    animation.toValue=[NSNumber numberWithFloat:0.0];
    animation.repeatCount=repeatTimes;
    animation.duration=time;
    animation.removedOnCompletion=YES;
    animation.fillMode=kCAFillModeForwards;
    animation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    animation.autoreverses=YES;
    return  animation;
}

CABasicAnimation *moveX(float time, NSNumber *x) {//横向移动
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"transform.translation.x"];
    animation.toValue=x;
    animation.duration=time;
    animation.removedOnCompletion=NO;
    animation.fillMode=kCAFillModeForwards;
    return animation;
}

CABasicAnimation *moveY(float time, NSNumber *y) {//纵向移动
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"transform.translation.y"];
    animation.toValue=y;
    animation.duration=time;
    animation.removedOnCompletion=NO;
    animation.fillMode=kCAFillModeForwards;
    return animation;
}

CABasicAnimation *myScale(NSNumber *Multiple, NSNumber *orginMultiple, float time ,float repeatTimes) { //缩放
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"transform.scale"];
    animation.fromValue             = orginMultiple;
    animation.toValue               = Multiple;
    animation.duration              = time;
    animation.autoreverses          = NO;
    animation.repeatCount           = repeatTimes;
    animation.removedOnCompletion   = NO;
    animation.fillMode              = kCAFillModeForwards;
    return animation;
}

CABasicAnimation *myRotate() {
    CATransform3D rotationTransform  = CATransform3DMakeRotation(M_PI, 1.0, 0, 0.0);
    CABasicAnimation* animation;
    animation = [CABasicAnimation animationWithKeyPath:@"transform.rotate"];
    animation.toValue		= [NSValue valueWithCATransform3D:rotationTransform];
    animation.duration		= 0.5;
    animation.autoreverses	= NO;
    animation.cumulative	= YES;
    animation.repeatCount	= FLT_MAX;  //"forever"
    //设置开始时间，能够连续播放多组动画
    animation.beginTime		= 0.5;
    animation.removedOnCompletion   = NO;
    //设置动画代理
    //animation.delegate		= self;
    return animation;
}

CAAnimationGroup *groupAnimation(NSArray *animationAry, float time ,float repeatTimes) {//组合动画
    CAAnimationGroup *animation=[CAAnimationGroup animation];
    animation.animations=animationAry;
    animation.duration=time;
    animation.repeatCount=repeatTimes;
    animation.removedOnCompletion=YES;
    animation.fillMode=kCAFillModeForwards;
    return animation;
}

CAKeyframeAnimation *keyframeAniamtion(CGMutablePathRef path, float time,float repeatTimes) {//路径动画
    CAKeyframeAnimation *animation=[CAKeyframeAnimation animationWithKeyPath:@"position"];
    animation.path=path;
    animation.removedOnCompletion=NO;
    animation.fillMode=kCAFillModeForwards;
    animation.timingFunction=[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
    animation.autoreverses=NO;
    animation.duration=time;
    animation.repeatCount=repeatTimes;
    return animation;
}

CABasicAnimation *movepoint(CGPoint point) {//点移动
    CABasicAnimation *animation=[CABasicAnimation animationWithKeyPath:@"transform.translation"];
    animation.toValue=[NSValue valueWithPoint:point];
    animation.removedOnCompletion=NO;
    animation.fillMode=kCAFillModeForwards;
    return animation;
}

CABasicAnimation *rotation(float dur, float degree, int direction, int repeatCount) {//旋转
    CATransform3D rotationTransform  = CATransform3DMakeRotation(degree, 0, 0,direction);
    CABasicAnimation* animation;
    animation = [CABasicAnimation animationWithKeyPath:@"transform"];
    animation.toValue= [NSValue valueWithCATransform3D:rotationTransform];
    animation.duration= dur;
    animation.autoreverses= NO;
    animation.cumulative= YES;
    animation.removedOnCompletion=NO;
    animation.fillMode=kCAFillModeForwards;
    animation.repeatCount= repeatCount;
    //animation.delegate= self;
    return animation;
}

#pragma mark 获取标题栏的高度
float titleBarHeight() {
    NSRect frame = NSMakeRect (0, 0, 100, 100);
    NSRect contentRect;
    contentRect = [NSWindow contentRectForFrameRect: frame
                                          styleMask: NSTitledWindowMask];
    return (frame.size.height - contentRect.size.height);
}

int convertToInt(NSString* strtemp) {
    int strlength = 0;
    char* p = (char*)[strtemp cStringUsingEncoding:NSUnicodeStringEncoding];
    for (int i=0 ; i<[strtemp lengthOfBytesUsingEncoding:NSUnicodeStringEncoding] ;i++) {
        if (*p) {
            p++;
            strlength++;
        }
        else {
            p++;
        }
    }
    return strlength;
}

int countWord(NSString *s) {
    int i,l=0,a=0,b=0;
    long n=[s length];
    unichar c;
    for(i=0;i<n;i++){
        c=[s characterAtIndex:i];
        if(isblank(c)){
            b++;
        } else if(isascii(c)){
            a++;
        } else{
            l++;
        }
    }
    if(a==0 && l==0) return 0;
    return l+(int)ceilf((float)(a+b)/2.0);
}

void shakeWindow (NSWindow* window) {
    static int numberOfShakes = 10;
    static float durationOfShake = 0.3f;
    static float vigourOfShake = 0.05f;
    
    CGRect frame=[window frame];
    CAKeyframeAnimation *shakeAnimation = [CAKeyframeAnimation animation];
    
    CGMutablePathRef shakePath = CGPathCreateMutable();
    CGPathMoveToPoint(shakePath, NULL, NSMinX(frame), NSMinY(frame));
    for (NSInteger index = 0; index < numberOfShakes; index++){
        CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) - frame.size.width * vigourOfShake, NSMinY(frame));
        CGPathAddLineToPoint(shakePath, NULL, NSMinX(frame) + frame.size.width * vigourOfShake, NSMinY(frame));
    }
    CGPathCloseSubpath(shakePath);
    shakeAnimation.path = shakePath;
    shakeAnimation.duration = durationOfShake;
    
    [window setAnimations:[NSDictionary dictionaryWithObject: shakeAnimation forKey:@"frameOrigin"]];
    [[window animator] setFrameOrigin:[window frame].origin];
}

void exchangeOut (NSView* view) {
    CAKeyframeAnimation* animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    animation.duration = 3.0;
    animation.removedOnCompletion = NO;
    animation.fillMode = kCAFillModeForwards;
    NSMutableArray* values = [NSMutableArray new];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.8, 0.8, 1.0)]];
    [values addObject:[NSValue valueWithCATransform3D:CATransform3DMakeScale(4.0, 4.0, 1.0)]];
    animation.values = values;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:@"easeInEaseOut"];
    [view.layer addAnimation:animation forKey:nil];
}

void writeTestData(NSString* str) {
    //输出测试数据
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDir = [documentPaths objectAtIndex:0];
    char filepath[100];
    memset(filepath, 0, sizeof(filepath));
    sprintf(filepath, "%s/test.log",[documentDir cStringUsingEncoding:NSUTF8StringEncoding]);
    FILE* file = fopen(filepath, "at+");
    if (file!=NULL) {
        fputs([str cStringUsingEncoding:NSUTF8StringEncoding], file);
        fclose(file);
    }
}

int getAppearCount(NSString* rString, NSString* findString) {
    int count = 0;
    for (int i=0; i<rString.length-findString.length+1; i++) {
        if ([[rString substringWithRange:NSMakeRange(i, findString.length)] isEqualToString:findString]) {
            count++;
        }
    }
    return count;
}
