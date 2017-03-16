//
//  ColorView.h
//  Margaux-OQC(一拖二)
//
//  Created by tpk on 14-12-18.
//  Copyright (c) 2014年 tpk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ColorView : NSView {
    NSColor *backgroundColor;
}

- (void)setBackgroundColor:(NSColor*)color;

@end
