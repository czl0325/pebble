//
//  BCView.h
//  noiseBackground
//
//  Created by xu lian on 11-11-30.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BCView : NSView
{
    CGImageRef noisePattern;
    NSColor *backgroundColor;
    float grain;
}
@property(nonatomic, retain) NSColor *backgroundColor;
@property(nonatomic, assign) float grain;

@end
