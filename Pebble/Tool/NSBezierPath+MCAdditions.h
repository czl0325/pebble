#import <Cocoa/Cocoa.h>


@interface NSBezierPath (MCAdditions)

+ (NSBezierPath *)bezierPathWithCGPath:(CGPathRef)pathRef;
- (CGPathRef)cgPath;

- (NSBezierPath *)pathWithStrokeWidth:(CGFloat)strokeWidth;

- (void)fillWithInnerShadow:(NSShadow *)shadow;
- (void)drawBlurWithColor:(NSColor *)color radius:(CGFloat)radius;

- (void)strokeInside;
- (void)strokeInsideWithinRect:(NSRect)clipRect;

@end
