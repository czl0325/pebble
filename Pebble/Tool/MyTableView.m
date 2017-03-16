//
//  MyTableView.m
//  Jedi
//
//  Created by tpk on 15-1-4.
//  Copyright (c) 2015年 tpk. All rights reserved.
//

#import "MyTableView.h"

@implementation MyTableView

@synthesize mydelegate;

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)mouseDown:(NSEvent *)theEvent {
    [super mouseDown:theEvent];
    NSPoint point = [self convertPoint:theEvent.locationInWindow toView:nil];
    NSInteger row  = [self rowAtPoint:point];
    NSInteger column  = [self columnAtPoint:point];
    if (theEvent.clickCount == 2) {
        if ([mydelegate respondsToSelector:@selector(myTableViewDidDoubleClickRow:column:)]) {
            [mydelegate myTableViewDidDoubleClickRow:row column:column];
        }
    }
}

@end
