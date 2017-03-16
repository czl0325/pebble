//
//  MyTextView.m
//  Bamboo
//
//  Created by tpk on 14-9-26.
//  Copyright (c) 2014年 tpk. All rights reserved.
//

#import "MyTextView.h"

@implementation MyTextView

@synthesize myTag;

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        isCanEdit = YES;
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)setCanEdit:(BOOL)isEdit {
    isCanEdit = isEdit;
}

- (void)keyDown:(NSEvent *)theEvent {
    if ([theEvent keyCode])
        return;
}

- (void)mouseDown:(NSEvent *)theEvent {
    if (isCanEdit) {
        [super mouseDown:theEvent];
    }
}

- (void)rightMouseDown:(NSEvent *)theEvent {
    if (isCanEdit) {
        [super rightMouseDown:theEvent];
    }
}

- (void)otherMouseDown:(NSEvent *)theEvent{
    if (isCanEdit) {
        [super otherMouseDown:theEvent];
    }
}

- (void)mouseUp:(NSEvent *)theEvent{
    if (isCanEdit) {
        [super mouseUp:theEvent];
    }
}

- (void)rightMouseUp:(NSEvent *)theEvent{
    if (isCanEdit) {
        [super rightMouseUp:theEvent];
    }
}

- (void)otherMouseUp:(NSEvent *)theEvent{
    if (isCanEdit) {
        [super otherMouseUp:theEvent];
    }
}

- (void)mouseMoved:(NSEvent *)theEvent{
    if (isCanEdit) {
        [super mouseMoved:theEvent];
    }
}

- (void)mouseDragged:(NSEvent *)theEvent {
    if (isCanEdit) {
        [super mouseDragged:theEvent];
    }
}

#pragma mark Cursor Rects
- (void) resetCursorRects {
    [super resetCursorRects];
    NSString *file = [[NSBundle mainBundle] pathForResource:@"cursur" ofType:@"tiff"];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile:file];
    [self addCursorRect:[self bounds]
                 cursor:[[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(0, 0)]];
    [self addCursorRect:[self bounds]
                 cursor:[[NSCursor alloc] initWithImage:image hotSpot:NSMakePoint(0, 0)]];

}

@end
