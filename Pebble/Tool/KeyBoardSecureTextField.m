//
//  KeyBoardSecureTextField.m
//  Jedi
//
//  Created by tpk on 15-1-12.
//  Copyright (c) 2015年 tpk. All rights reserved.
//

#import "KeyBoardSecureTextField.h"

@implementation KeyBoardSecureTextField

@synthesize mydelegate;

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)keyUp:(NSEvent *)theEvent {
    [super keyUp:theEvent];
    if ([mydelegate respondsToSelector:@selector(acceptKeyCode:keyCode:)]) {
        [mydelegate acceptKeyCode:self keyCode:theEvent.keyCode];
    }
}

@end
