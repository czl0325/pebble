//
//  MyImageView.m
//  Pebble
//
//  Created by tpk on 15-1-20.
//  Copyright (c) 2015年 tpk. All rights reserved.
//

#import "MyImageView.h"

@implementation MyImageView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

#pragma mark Cursor Rects
- (void) resetCursorRects {
    [super resetCursorRects];
    NSString *file = [[NSBundle mainBundle] pathForResource:@"cursur" ofType:@"png"];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:file];
    [self addCursorRect: [[NSScreen mainScreen] frame]
                 cursor: [[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(0, 0)]];
}

@end
