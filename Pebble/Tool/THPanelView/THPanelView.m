//
//  NSTestView.m
//  FanText
//
//  Created by tanhao on 8/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "THPanelView.h"
#import <QuartzCore/QuartzCore.h>

@interface THSectorLayer : CALayer
{
    double startAngle;
    double endAngle;
    double progress;
    CGColorRef bgColor;
    CGColorRef fillColor;
    
    CGImageRef imgRef;
}

@property (assign) double startAngle;
@property (assign) double endAngle;
@property (assign) double progress;
@property (assign) CGColorRef bgColor;
@property (assign) CGColorRef fillColor;
@property (assign) CGImageRef imgRef;
@end

@implementation THSectorLayer
@synthesize startAngle,endAngle,progress;
@synthesize bgColor,fillColor;
@synthesize imgRef;

- (void)dealloc
{
    if (bgColor)
    {
        CGColorRelease(bgColor);
        bgColor = NULL;
    }
    if (fillColor)
    {
        CGColorRelease(fillColor);
        fillColor = NULL;
    }
    if (imgRef)
    {
        CGImageRelease(imgRef);
        imgRef = NULL;
    }
}

- (CGColorRef)bgColor
{
    return bgColor;
}

- (void)setBgColor:(CGColorRef)aColor
{
    if (bgColor)
    {
        CGColorRelease(bgColor);
        bgColor = NULL;
    }
    bgColor = CGColorRetain(aColor);
}

- (CGColorRef)fillColor
{
    return fillColor;
}

- (void)setFillColor:(CGColorRef)aColor
{
    if (fillColor)
    {
        CGColorRelease(fillColor);
        fillColor = NULL;
    }
    fillColor = CGColorRetain(aColor);
}

- (CGImageRef)imgRef
{
    return imgRef;
}

- (void)setImgRef:(CGImageRef)ref
{
    if (imgRef)
    {
        CGImageRelease(imgRef);
        imgRef = NULL;
    }
    imgRef = CGImageCreateCopy(ref);
}

- (id)init
{
    self = [super init];
    if (self)
    {        
        startAngle = 30*(M_PI/180.0);
        endAngle = 150*(M_PI/180.0);
        progress = 0;
        bgColor = CGColorCreateGenericRGB(1, 1, 1, 1);
        fillColor = CGColorCreateGenericRGB(0, 0, 0, 1);
        
        static NSImage *image = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSString *imagePath = [[NSBundle bundleForClass:self.class] pathForImageResource:@"panel_point"];
            image = [[NSImage alloc] initWithContentsOfFile:imagePath];
        });
        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)[image TIFFRepresentation], NULL);
        imgRef = CGImageSourceCreateImageAtIndex(source, 0, NULL);
        CFRelease(source);
        
        [self setNeedsDisplay];
    }
    return self;
}

- (id<CAAction>)actionForKey:(NSString *)key
{
    if ([key isEqualToString:@"progress"])
    {
        CABasicAnimation *anim = [CABasicAnimation animationWithKeyPath:@"progress"];
        anim.fromValue = [[self presentationLayer] valueForKey:key];
        anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
        anim.duration = 0.2;
        return anim;
    }
    return [super actionForKey:key];
}

- (id)initWithLayer:(id)layer
{
    self = [super initWithLayer:layer];
    if (self)
    {
        if ([layer isKindOfClass:[THSectorLayer class]])
        {
            self.startAngle = [(THSectorLayer *)layer startAngle];
            self.endAngle = [(THSectorLayer *)layer endAngle];
            self.bgColor = [(THSectorLayer *)layer bgColor];
            self.fillColor = [(THSectorLayer *)layer fillColor];
            self.progress = [(THSectorLayer *)layer progress];
            self.imgRef = [(THSectorLayer *)layer imgRef];
        }
    }
    return self;
}

+ (BOOL)needsDisplayForKey:(NSString *)key
{
    if ([key isEqualToString:@"progress"] || [key isEqualToString:@"startAngle"] || [key isEqualToString:@"endAngle"])
    {
        return YES;
    }
    return [super needsDisplayForKey:key];
}

- (void)drawWithStartAngle:(double)sAngle radius:(double)radius color:(CGColorRef)aColor context:(CGContextRef)ctx
{
    float centerSize = radius/2;
	CGPoint center = CGPointMake(self.bounds.size.width/2, 0);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddArc(path, NULL, center.x, center.y, radius, sAngle, endAngle, NO);
    CGPathAddArc(path, NULL, center.x, center.y, centerSize, endAngle, sAngle, YES);
    CGPathCloseSubpath(path);
    
    CGContextAddPath(ctx, path);
    CGContextSetFillColorWithColor(ctx, aColor);
    //CGContextSetStrokeColorWithColor(ctx, aColor);
    //CGContextSetLineWidth(ctx, 1.0);
    CGContextDrawPath(ctx, kCGPathFill);
    CGPathRelease(path);
}

- (void)drawInContext:(CGContextRef)ctx
{
    [super drawInContext:ctx];
    
    CGRect boundary = self.bounds;
    float radius;
    if (boundary.size.width/2 > boundary.size.height) 
    {
        radius = boundary.size.height;
    }
    else 
    {
        radius = boundary.size.width/2;
    }
    
    [self drawWithStartAngle:startAngle radius:radius color:bgColor context:ctx];
    [self drawWithStartAngle:endAngle-(endAngle-startAngle)*progress radius:radius color:fillColor context:ctx];
    
    if (imgRef)
    {
        size_t width = CGImageGetWidth(imgRef);
        size_t height = CGImageGetHeight(imgRef);
        NSRect imgRect = NSMakeRect(0, 0, width*radius/height, radius);
        imgRect.origin.x = - NSWidth(imgRect)/2;
        imgRect = NSIntegralRect(imgRect);
        
        CGContextTranslateCTM(ctx, boundary.size.width/2, 0);
        double angle = (endAngle-startAngle)*(1-progress)-((endAngle-startAngle)/2);
        CGContextRotateCTM(ctx, angle);
        CGContextDrawImage(ctx, imgRect, imgRef);
    }
}

@end


@implementation THPanelView
@synthesize progress;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) 
    {
        [self setWantsLayer:YES];
        aLayer = [THSectorLayer layer];
        [aLayer setNeedsDisplayOnBoundsChange:YES];
        [aLayer setFrame:CGRectMake(0, 0, NSWidth(frame), NSHeight(frame))];
        [aLayer setAutoresizingMask:kCALayerMinXMargin|kCALayerMaxXMargin|kCALayerMinYMargin|kCALayerMaxYMargin|kCALayerWidthSizable|kCALayerHeightSizable];
        //CGColorRef bgColor = CGColorCreateGenericRGB(209/255.0, 209/255.0, 209/255.0, 1);
        //CGColorRef fillColor = CGColorCreateGenericRGB(140/255.0, 191/255.0, 219/255.0, 1);
        CGColorRef bgColor = CGColorCreateGenericRGB(109/255.0, 200/255.0, 109/255.0, 1);
        CGColorRef fillColor = CGColorCreateGenericRGB(255/255.0, 191/255.0, 219/255.0, 1);
        [aLayer setBgColor:bgColor];
        [aLayer setFillColor:fillColor];
        CGColorRelease(bgColor);
        CGColorRelease(fillColor);
        [self.layer addSublayer:aLayer];
        
        //add shadow
        NSShadow *shadow = [[NSShadow alloc] init];
        [shadow setShadowBlurRadius:2.5];
        [shadow setShadowOffset:NSMakeSize(0, 0)];
        [shadow setShadowColor:[NSColor colorWithCalibratedRed:1 green:1 blue:1 alpha:0.75]];
        [self setShadow:shadow];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidChange:) name:NSViewFrameDidChangeNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidChange:(NSNotification *)notify
{
    if (notify.object == self)
    {
        [aLayer setFrame:self.bounds];
    }
}

- (double)progress
{
    return progress;
}

- (void)setProgress:(double)value
{
    if (value>1.0)
    {
        value = 1.0;
    }
    if (value<0)
    {
        value=0;
    }
    if (progress == value)
    {
        return;
    }
    progress = value;
    
    /*
    //不使用动画
    [aLayer setProgress:progress];
    [aLayer setNeedsDisplay];
    */
    
    //使用动画
    CFTimeInterval duration = fabs(progress-value)*2.0;
    CABasicAnimation *animtion = [CABasicAnimation animationWithKeyPath:@"progress"];
    [animtion setRemovedOnCompletion:YES];
    [animtion setFillMode:kCAFillModeForwards];
    animtion.duration = duration;
    animtion.toValue = [NSNumber numberWithDouble:progress];
    [animtion setDelegate:self];
    [aLayer addAnimation:animtion forKey:@"progress"];
    
}

- (void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag
{
    [aLayer setProgress:progress];
}

- (void)viewDidMoveToWindow
{
    [super viewDidMoveToWindow];
    [self.layer addSublayer:aLayer];
}

@end
