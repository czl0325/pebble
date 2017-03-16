/*
 ==============================================================================
 ScrollingTextView.m
 
 http://www.pixelegg.me
 
 Created on 2014-27-11 by Aaron Elkins
 encoding="UTF-8"
 ------------------------------------------------------------------------------
 
 Copyright (c) 2014 Aaron Elkins
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 
 ==============================================================================
 */

#import "ScrollingTextView.h"

@interface ScrollingTextView (Expose)
- (void)scrollText:(NSTimer*)t;
@end

@implementation ScrollingTextView (Expose)
- (void)scrollText:(NSTimer*)t{
    // Pause
    //if (pauseScrolling) {
    //    return ;
    //}
    
    NSRect frame = self.bounds;
    
    if(!CGRectIntersectsRect(frame, textRect)){
        if (textDirection == NSTOPTOBOTTOM) {
            textRect.origin.y = NSMaxY(self.bounds);
        } else {
            textRect.origin.x = NSMaxX(self.bounds);
        }
    }
    
    if (textDirection == NSTOPTOBOTTOM) {
        textRect.origin.y -= 1;
    } else {
        textRect.origin.x -= 2;
        if (textRect.origin.x <= (frame.size.width/2-textRect.size.width/2)) {
            if (timer) {
                [timer invalidate];
                timer = nil;
            }
        }
    }
    [self setNeedsDisplay:YES];
}
@end

@implementation ScrollingTextView

- (id)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        textDirection = NSTOPTOBOTTOM;
        [self setBackgroundColor:[NSColor whiteColor]];
        if (!timer) {
            timer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(scrollText:) userInfo:nil repeats:YES];
        }
    }
    return self;
}

- (void)setString:(NSString*)as{
    // don't pause at start up
    pauseScrolling = NO;
    
    // Setting up attributed string
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    [dict setObject:[NSFont fontWithName:@"Lucida Grande" size:textDirection==NSLEFTTORIGHT?(self.bounds.size.height>100?100:self.bounds.size.height-10):10] forKey:NSFontAttributeName];
    [dict setObject:[NSColor colorWithDeviceRed:0.64 green:0.64 blue:0.64 alpha:0.7] forKey:NSForegroundColorAttributeName];
    //[dict setObject:[NSColor colorWithWhite:0 alpha:0.4] forKey:NSForegroundColorAttributeName];
    attributedString = [[NSAttributedString alloc] initWithString:as attributes:dict];
    
    NSSize size = self.frame.size;
    
    // Calculate attributed string rect
    NSTextStorage *storage =
    [[NSTextStorage alloc] initWithAttributedString:attributedString];
    
    NSTextContainer *container =
    [[NSTextContainer alloc] initWithContainerSize:size];
    NSLayoutManager *manager = [[NSLayoutManager alloc] init];
    
    [manager addTextContainer:container];
    [storage addLayoutManager:manager];
    
    [manager glyphRangeForTextContainer:container];
    
    NSRect idealRect = [manager usedRectForTextContainer: container];
    idealRect.origin = NSZeroPoint;
    idealRect.size.height += 25;

    textRect = idealRect;
    if (textDirection == NSTOPTOBOTTOM) {
        textRect.origin.y = NSMaxY(self.bounds);
    } else {
        textRect.origin.x = NSMaxX(self.bounds);
    }
    [self setNeedsDisplay:YES];
}

- (void)awakeFromNib{
    // don't pause at start up
    pauseScrolling = NO;
    
    // Setup background color
    [self setBackgroundColor:[NSColor whiteColor]];
    timer = [NSTimer scheduledTimerWithTimeInterval:0.03 target:self selector:@selector(scrollText:) userInfo:nil repeats:YES];
}

- (void)drawRect:(NSRect)dirtyRect{
    NSRect frame = [self bounds];
    
    // Draw background with backgroundColor
    if (![[self backgroundColor] isEqualTo:[NSColor clearColor]]) {
        [[self backgroundColor] set];
        NSRectFill(frame);
    }
    
    // Draw atrtributed string
    [attributedString drawInRect:textRect];
}

- (BOOL)isFlipped{
    return YES;
}

- (void)mouseDown:(NSEvent *)theEvent{
    //pauseScrolling = !pauseScrolling;
}

- (void)setDirection:(TextDirection)direction {
    textDirection = direction;
    if (attributedString && attributedString.string) {
        [self setString:attributedString.string];
    }
    [self setNeedsDisplay:YES];
}

@end
