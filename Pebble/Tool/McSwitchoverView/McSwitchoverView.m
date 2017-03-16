//
//  McSwitchoverView.m
//  Test
//
//  Created by TanHao on 12-11-23.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import "McSwitchoverView.h"
#import <QuartzCore/QuartzCore.h>

#define kDefaultSizeWidth  148.0
#define kDefaultSizeHeight 170.0
#define kDefaultScaleMin 0.7

@protocol McSwitchAnimationDelegate <NSAnimationDelegate>
- (void)animation:(NSAnimation *)animation progressDidChanged:(float)progress;
@end

@interface McSwitchAnimation : NSAnimation
@property (nonatomic,unsafe_unretained) id<McSwitchAnimationDelegate> mydelegate;
@end

@implementation McSwitchAnimation
@synthesize mydelegate;

- (id<McSwitchAnimationDelegate>)delegate
{
    return (id<McSwitchAnimationDelegate>)[super delegate];
}

- (void)setDelegate:(id<McSwitchAnimationDelegate>)aDelegate
{
    [super setDelegate:aDelegate];
    mydelegate = aDelegate;
}

- (void)setCurrentProgress:(NSAnimationProgress)progress
{
    [super setCurrentProgress:progress];
    [mydelegate animation:self progressDidChanged:progress];
}

@end


@interface McSwitchoverView ()<McSwitchAnimationDelegate>
@end

@implementation McSwitchoverView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    animation = [[McSwitchAnimation alloc] init];
    animation.duration = 1.0;
    animation.delegate = self;
    animation.animationBlockingMode = NSAnimationBlocking;
    
    NSImage *imageA = [NSImage imageNamed:@"imageA"];
    viewA = [[NSImageView alloc] init];
    [viewA setFrame:NSMakeRect(NSMidX(self.bounds)-kDefaultSizeWidth/2, NSMidY(self.bounds)-kDefaultSizeHeight/2, kDefaultSizeWidth, kDefaultSizeHeight)];
    [viewA setImage:imageA];
    [viewA setImageFrameStyle:NSImageFrameNone];
    [viewA setImageScaling:NSImageScaleAxesIndependently];
    [self addSubview:viewA];
    viewShow = viewA;
    
    NSImage *imageB = [NSImage imageNamed:@"imageB"];
    viewB = [[NSImageView alloc] init];
    [viewB setFrameSize:NSMakeSize(kDefaultSizeWidth*kDefaultScaleMin, kDefaultSizeHeight*kDefaultScaleMin)];
    [viewB setFrameOrigin:NSMakePoint(0,NSMidY(self.bounds)-NSHeight(viewB.frame)/2)];
    [viewB setImage:imageB];
    [viewB setImageFrameStyle:NSImageFrameNone];
    [viewB setImageScaling:NSImageScaleAxesIndependently];
    [self addSubview:viewB];
    
    CIFilter *filterA = [CIFilter filterWithName:@"CIColorControls"];
    [filterA setDefaults];
    [filterA setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputSaturation"];
    [viewA setWantsLayer:YES];
    [viewA setContentFilters:[NSArray arrayWithObject:filterA]];
    
    CIFilter *filterB = [CIFilter filterWithName:@"CIColorControls"];
    [filterB setDefaults];
    [filterB setValue:[NSNumber numberWithFloat:0.0] forKey:@"inputSaturation"];
    [viewB setWantsLayer:YES];
    [viewB setContentFilters:[NSArray arrayWithObject:filterB]];
    
    [viewA setAutoresizingMask:NSViewMinYMargin|NSViewMaxYMargin|NSViewMinXMargin|NSViewMaxXMargin];
    [viewB setAutoresizingMask:NSViewMinYMargin|NSViewMaxYMargin|NSViewMaxXMargin];
}

- (void)updateTrackingAreas
{
    NSArray *areas = [self trackingAreas];
    for (NSTrackingArea *area in areas)
    {
        [self removeTrackingArea:area];
    }
    
    NSTrackingArea *trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                                options:NSTrackingActiveInActiveApp|NSTrackingMouseMoved|NSTrackingMouseEnteredAndExited
                                                                  owner:self
                                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (void)startAnimation
{
    if (viewShow == viewA)
    {
        viewShow = viewB;
    }else
    {
        viewShow = viewA;
    }
    startCenterA = NSMidX(viewA.frame);
    startCenterB = NSMidX(viewB.frame);
    [animation startAnimation];
}

- (void)stopAnimation
{
    [animation stopAnimation];
}

- (void)mouseEntered:(NSEvent *)theEvent
{
    [self mouseMoved:theEvent];
}

- (void)mouseExited:(NSEvent *)theEvent
{
    [[NSCursor arrowCursor] set];
}

- (void)mouseMoved:(NSEvent *)theEvent
{
    [[NSCursor arrowCursor] set];
    
    NSPoint point = [theEvent locationInWindow];
    point = [self convertPoint:point fromView:nil];
    if (NSPointInRect(point, viewA.frame) && viewShow!=viewA && !animation.isAnimating)
    {
        [[NSCursor pointingHandCursor] set];
    }
    
    if (NSPointInRect(point, viewB.frame) && viewShow!=viewB && !animation.isAnimating)
    {
        [[NSCursor pointingHandCursor] set];
    }
}

#pragma mark 
#pragma mark NSAnimationDelegate

- (BOOL)animationShouldStart:(NSAnimation*)animation
{
    return YES;
}

- (void)animationDidStop:(NSAnimation*)animation
{
}

- (void)animationDidEnd:(NSAnimation*)animation
{
}

- (float)animation:(NSAnimation*)animation valueForProgress:(NSAnimationProgress)progress
{
    return progress;
}

- (void)animation:(NSAnimation *)animation progressDidChanged:(float)progress
{
    CIFilter *filterA = [CIFilter filterWithName:@"CIColorControls"];
    [filterA setDefaults];
    
    CIFilter *filterB = [CIFilter filterWithName:@"CIColorControls"];
    [filterB setDefaults];
    
    NSSize sizeA;
    NSSize sizeB;
    float endCenterA = 0;
    float endCenterB = 0;
    if (viewShow == viewA)
    {
        endCenterA = NSMidX(self.bounds);
        endCenterB = kDefaultSizeWidth*kDefaultScaleMin/2;
        sizeA = NSMakeSize(kDefaultSizeWidth*(kDefaultScaleMin+(1-kDefaultScaleMin)*progress),
                           kDefaultSizeHeight*(kDefaultScaleMin+(1-kDefaultScaleMin)*progress));
        sizeB = NSMakeSize(kDefaultSizeWidth*(kDefaultScaleMin+(1-kDefaultScaleMin)*(1-progress)),
                           kDefaultSizeHeight*(kDefaultScaleMin+(1-kDefaultScaleMin)*(1-progress)));

        [filterA setValue:[NSNumber numberWithFloat:progress] forKey:@"inputSaturation"];
        [filterB setValue:[NSNumber numberWithFloat:1-progress] forKey:@"inputSaturation"];
        [viewA setAutoresizingMask:NSViewMinYMargin|NSViewMaxYMargin|NSViewMinXMargin|NSViewMaxXMargin];
        [viewB setAutoresizingMask:NSViewMinYMargin|NSViewMaxYMargin|NSViewMaxXMargin];
    }else
    {
        endCenterB = NSMidX(self.bounds);
        endCenterA = NSMaxX(self.bounds)-kDefaultSizeWidth*kDefaultScaleMin/2;
        
        sizeB = NSMakeSize(kDefaultSizeWidth*(kDefaultScaleMin+(1-kDefaultScaleMin)*progress),
                           kDefaultSizeHeight*(kDefaultScaleMin+(1-kDefaultScaleMin)*progress));
        sizeA = NSMakeSize(kDefaultSizeWidth*(kDefaultScaleMin+(1-kDefaultScaleMin)*(1-progress)),
                           kDefaultSizeHeight*(kDefaultScaleMin+(1-kDefaultScaleMin)*(1-progress)));

        [filterB setValue:[NSNumber numberWithFloat:progress] forKey:@"inputSaturation"];
        [filterA setValue:[NSNumber numberWithFloat:1-progress] forKey:@"inputSaturation"];
        [viewB setAutoresizingMask:NSViewMinYMargin|NSViewMaxYMargin|NSViewMinXMargin|NSViewMaxXMargin];
        [viewA setAutoresizingMask:NSViewMinYMargin|NSViewMaxYMargin|NSViewMinXMargin];
    }
    
    float currentCenterA = startCenterA+(endCenterA-startCenterA)*progress;
    [viewA setFrameSize:sizeA];
    [viewA setFrameOrigin:NSMakePoint(currentCenterA-NSWidth(viewA.frame)/2, NSMidY(self.bounds)-NSHeight(viewA.frame)/2)];
    float currentCenterB = startCenterB+(endCenterB-startCenterB)*progress;
    [viewB setFrameSize:sizeB];
    [viewB setFrameOrigin:NSMakePoint(currentCenterB-NSWidth(viewB.frame)/2, NSMidY(self.bounds)-NSHeight(viewB.frame)/2)];
    
    [viewA setContentFilters:[NSArray arrayWithObject:filterA]];
    [viewB setContentFilters:[NSArray arrayWithObject:filterB]];
    [self display];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint point = [theEvent locationInWindow];
    point = [self convertPoint:point fromView:nil];
    
    if (NSPointInRect(point, viewA.frame) && viewShow!=viewA && !animation.isAnimating)
    {
        [self startAnimation];
    }
    
    if (NSPointInRect(point, viewB.frame) && viewShow!=viewB && !animation.isAnimating)
    {
        [self startAnimation];
    }
}

@end
