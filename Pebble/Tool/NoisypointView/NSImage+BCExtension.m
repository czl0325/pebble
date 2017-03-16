//
//  NSImage+BCExtension.m
//  noiseBackground
//
//  Created by xu lian on 11-11-30.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import "NSImage+BCExtension.h"

@implementation NSImage (BCExtension)

+ (CGImageRef)createNoiseImageRefWithWidth:(int)width height:(int)height factor:(float)factor;
{
    int size = width*height;
    char *rgba = (char *)malloc(size); srand(124);
    for(int i=0; i < size; ++i){rgba[i] = rand()%256*factor;}
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    CGContextRef bitmapContext = CGBitmapContextCreate(rgba, width, height, 8, width, colorSpace, kCGImageAlphaNone);
    CFRelease(colorSpace);
    CGImageRef image = CGBitmapContextCreateImage(bitmapContext);
    CFRelease(bitmapContext);
    free(rgba);
    return image;    
}

@end
