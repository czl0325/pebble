//
//  McSwitchoverView.h
//  Test
//
//  Created by TanHao on 12-11-23.
//  Copyright (c) 2012年 tanhao.me. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface McSwitchoverView : NSView
{
    NSAnimation *animation;
    NSImageView *viewA;
    NSImageView *viewB;
    NSImageView *viewShow;
    float startCenterA;
    float startCenterB;
}

@end
