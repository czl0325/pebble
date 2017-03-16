//
//  TSPCircularProgressIndicator.m
//  TSPCircularProgressIndicator
//
//  Created by Synapse on 25.06.2010.
//  Copyright 2010 TheSynapseProject. All rights reserved.
//

#import "TSPCircularProgressIndicator.h"



@implementation TSPCircularProgressIndicator


@synthesize thickness;
@synthesize progressText,maxValue;
@synthesize showText;
@synthesize roundedHead;

- (id)initWithFrame:(NSRect)frameRect {
	id superInit = [super initWithFrame:frameRect];
	if (superInit) {
		[self setDoubleValue: 0.0];
		[self setThickness: 30.0];
		[self setMaxValue: 100.0];
		[self setShowText: YES];
		[self setRoundedHead: NO];
	}
	
	return superInit;
}

- (void)drawRect:(NSRect)dirtyRect {
	if (NSEqualRects(dirtyRect, NSZeroRect)) {
        return;
    }
    
	float size = dirtyRect.size.height;
	[NSGraphicsContext saveGraphicsState];
	
	/* HOLDER */
	NSBezierPath *holderPath = [NSBezierPath bezierPath];
	[holderPath appendBezierPathWithArcWithCenter:NSMakePoint(size/2, size/2) radius: size/2 startAngle: 90.0 endAngle:450.0 clockwise: NO];
	
	
	[holderPath appendBezierPathWithArcWithCenter:NSMakePoint(size/2, size/2) radius: size/2 - thickness startAngle: 450.0 endAngle: 90.0 clockwise: YES];
	
	[holderPath fillWithInnerShadow: [self innerShadowButtonPressed1]];
	[holderPath fillWithInnerShadow: [self innerShadowButtonPressed2]];
	
	/* TEXT */
	if (showText) {
		NSString *stringInProgress = [self progressText];
		NSFont *fontInProgress = [NSFont labelFontOfSize: dirtyRect.size.height/5];
		NSDictionary *attributesInProgress = [NSDictionary dictionaryWithObjectsAndKeys:[NSColor colorWithRed:1 green:97.0/255.0 blue:3.0/255.0 alpha:1.0], NSForegroundColorAttributeName,fontInProgress, NSFontAttributeName,nil];
		NSSize sizeInProgress = [stringInProgress sizeWithAttributes:attributesInProgress];
		[stringInProgress drawInRect:NSOffsetRect(dirtyRect, dirtyRect.size.height/2 - sizeInProgress.width/2, -dirtyRect.size.height/2 + sizeInProgress.height/2) withAttributes:attributesInProgress];
	}

	/* CIRCLE PROGRESS */
	NSBezierPath *path = [NSBezierPath bezierPath];
	[path appendBezierPathWithArcWithCenter:NSMakePoint(size/2, size/2) radius: size/2  startAngle: 90.0 endAngle: doubleValue clockwise: NO];
	
	
	
	if ([self roundedHead]) {
		point.x =  (cos((doubleValue) * (3.14159265/180)) * (size/2 - thickness/2)) + size/2;
		point.y = (sin((doubleValue) * (3.14159265/180)) * (size/2 - thickness/2)) + size/2;
		[path appendBezierPathWithArcWithCenter:NSMakePoint(point.x, point.y)
										 radius: thickness/2
									 startAngle: doubleValue 
									   endAngle: 270.0 + doubleValue - 90.0
									  clockwise: NO];
	}

	
	[path appendBezierPathWithArcWithCenter:NSMakePoint(size/2, size/2) 
									 radius: size/2 - thickness 
								 startAngle: doubleValue 
								   endAngle: 90.0
								  clockwise: YES];
	
	
	if ([self roundedHead]) {
		[path appendBezierPathWithArcWithCenter:NSMakePoint(size/2, size - thickness / 2) radius: thickness /2 startAngle: 270.0 endAngle: 90.0 clockwise: YES];
	}

	[path addClip];
	[path setLineJoinStyle:NSRoundLineJoinStyle];
	
	NSBezierPath *clipPath = [NSBezierPath bezierPath];
	[clipPath appendBezierPathWithArcWithCenter:NSMakePoint(size/2, size/2) radius: size/2 startAngle: 90.0 endAngle: 450.0 clockwise: NO];
	
	
	[clipPath appendBezierPathWithArcWithCenter:NSMakePoint(size/2, size/2) radius: size/2 - thickness startAngle: 450.0
	endAngle: 90.0 clockwise: YES];
	
	[[self viewBackgroundGradient] drawInBezierPath: clipPath relativeCenterPosition: NSMakePoint(0, 0)];
	
	[[NSColor colorWithCalibratedRed:0.0f green:100.0/255.0 blue:0.0f alpha:1.0f] set];
	[clipPath fill];
	
	[NSGraphicsContext restoreGraphicsState];
}

- (double)doubleValue {
    return doubleValue;
}

- (void)setDoubleValue:(double)arg { 
	if (arg != 0) {
		doubleValue = (arg * (360 / maxValue)) + 90.0; 
	} else {
		doubleValue = 90.0;
	}

}

- (NSGradient*) viewBackgroundGradient {
	return [[NSGradient alloc]
			 initWithStartingColor:[NSColor colorWithCalibratedRed:0.268 green:0.518 blue:0.904 alpha:1.000]
			 endingColor:[NSColor colorWithCalibratedRed:0.025 green:0.389 blue:0.762 alpha:1.000]];
}

- (NSShadow*)innerShadowButtonPressed1 {
	return [[NSShadow alloc] initWithColor:[NSColor blackColor]
									 offset:NSZeroSize blurRadius:3.0];
}
- (NSShadow*)innerShadowButtonPressed2 {
	return [[NSShadow alloc] initWithColor:[NSColor colorWithCalibratedWhite:0.0 alpha:.52]
									 offset:NSMakeSize(0.0, -2.0) blurRadius:8.0];
}

@end
