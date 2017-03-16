
//  TSPCircularProgressIndicator.m
//  TSPCircularProgressIndicator
//
//
//  Created by Synapse on 25.06.2010.
//  Copyright 2010 TheSynapseProject. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NSBezierPath+PXRoundedRectangleAdditions.h"
#import "NSBezierPath+MCAdditions.h"
#import "NSShadow+MCAdditions.h"

@interface TSPCircularProgressIndicator : NSView {
	double doubleValue;
	double thickness;
	double maxValue;
	
	NSString *progressText;
	NSPoint point;
	
	BOOL showText;
	BOOL roundedHead;
}

@property (readwrite,assign) double thickness;
@property (readwrite,retain) NSString *progressText;
@property (readwrite,assign) double maxValue;
@property (readwrite,assign) BOOL showText;
@property (readwrite,assign) BOOL roundedHead;

- (double)doubleValue;
- (void)setDoubleValue:(double)arg;


- (NSGradient*) viewBackgroundGradient;
- (NSShadow*)innerShadowButtonPressed1;
- (NSShadow*)innerShadowButtonPressed2;
@end
