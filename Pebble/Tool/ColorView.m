//
//  ColorView.m
//  Margaux-OQC(一拖二)
//
//  Created by tpk on 14-12-18.
//  Copyright (c) 2014年 tpk. All rights reserved.
//

#import "ColorView.h"

@implementation ColorView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        backgroundColor = [NSColor clearColor];
    }
    return self;
}

- (void)setBackgroundColor:(NSColor*)color {
    backgroundColor = color;
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
    [backgroundColor set];
    [NSBezierPath fillRect:dirtyRect];
}

@end
