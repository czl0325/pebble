//
//  KeyBoardTextField.m
//  KingCrab
//
//  Created by tpk on 14-10-28.
//  Copyright (c) 2014年 tpk. All rights reserved.
//

#import "KeyBoardTextField.h"

@implementation KeyBoardTextField

@synthesize mydelegate;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)viewDidMoveToWindow {
    
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)keyDown:(NSEvent *)theEvent {
    [super keyDown:theEvent];
}

- (void)keyUp:(NSEvent *)theEvent {
    [super keyUp:theEvent];
    if ([mydelegate respondsToSelector:@selector(acceptKeyCode:keyCode:)]) {
        [mydelegate acceptKeyCode:self keyCode:theEvent.keyCode];
    }
}



@end
