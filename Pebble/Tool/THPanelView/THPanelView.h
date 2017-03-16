//
//  NSTestView.h
//  FanText
//
//  Created by tanhao on 8/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class THSectorLayer;
@interface THPanelView : NSView
{
    THSectorLayer *aLayer;
}
@property (nonatomic, assign) double progress;

@end
