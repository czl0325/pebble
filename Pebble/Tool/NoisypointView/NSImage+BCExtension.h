//
//  NSImage+BCExtension.h
//  noiseBackground
//
//  Created by xu lian on 11-11-30.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NSImage (BCExtension)

+ (CGImageRef)createNoiseImageRefWithWidth:(int)width height:(int)height factor:(float)factor;

@end
