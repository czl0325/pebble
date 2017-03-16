//
//  LIGridField.m
//  LIGrid
//
//  Created by Mark Onyschuk on 11/18/2013.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGridField.h"

@implementation LIGridField

+ (Class)cellClass {
    return [LIGridFieldCell class];
}

- (id)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        [self configureGridField];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    [self configureGridField];
}

- (void)configureGridField {
    [self setWantsLayer:YES];
    [self setLayerContentsRedrawPolicy:NSViewLayerContentsRedrawOnSetNeedsDisplay];
    
    [self.cell configureGridCell];
}

- (BOOL)isVertical {
    return [(LIGridFieldCell *)self.cell isVertical];
}
- (void)setVertical:(BOOL)vertical {
    [(LIGridFieldCell *)self.cell setVertical:vertical];
}

- (LIGridFieldVerticalAlignment)verticalAlignment {
    return [(LIGridFieldCell *)self.cell verticalAlignment];
}
- (void)setVerticalAlignment:(LIGridFieldVerticalAlignment)verticalAlignment {
    [(LIGridFieldCell *)self.cell setVerticalAlignment:verticalAlignment];
}

@end

@implementation LIGridFieldCell {
    NSSize      _cachedCellSize;
    NSSize      _cachedInputSize;
    
    NSRect      _fieldEditorOriginalFrame;
    LIGridFieldCell *_fieldEditorPositioningCell;
    BOOL        _fieldEditorIsBeingPositioned;
}

- (id)initTextCell:(NSString *)aString {
    if ((self = [super initTextCell:aString])) {
        [self configureGridCell];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self configureGridCell];
}

- (void)configureGridCell {
    self.wraps              = YES;
    
    self.bezeled            = NO;
    self.bordered           = NO;
    self.focusRingType      = NSFocusRingTypeNone;
    self.drawsBackground    = YES;
    
    self.editable           = YES;
    self.selectable         = YES;
    
    self.alignment          = NSRightTextAlignment;
    
    _vertical               = NO;
    _verticalAlignment      = LIGridFieldVerticalAlignment_Center;
    
    self.font               = [NSFont fontWithName:@"AvenirNext-Regular" size:11];
}

#pragma mark -
#pragma mark NSCopying

- (id)copyWithZone:(NSZone *)zone {
    LIGridFieldCell *copy = [super copyWithZone:zone];
    
    copy->_vertical = _vertical;
    copy->_verticalAlignment = _verticalAlignment;
    
    return copy;
}

#pragma mark -
#pragma mark Value

- (void)setObjectValue:(id<NSCopying>)obj {
    _cachedInputSize = NSZeroSize;
    [super setObjectValue:obj];
}
- (void)setIntegerValue:(NSInteger)anInteger {
    _cachedInputSize = NSZeroSize;
    [super setIntegerValue:anInteger];
}
- (void)setFloatValue:(float)aFloat {
    _cachedInputSize = NSZeroSize;
    [super setFloatValue:aFloat];
}
- (void)setDoubleValue:(double)aDouble {
    _cachedInputSize = NSZeroSize;
    [super setDoubleValue:aDouble];
}
- (void)setStringValue:(NSString *)aString {
    _cachedInputSize = NSZeroSize;
    [super setStringValue:aString];
}
- (void)setAttributedStringValue:(NSAttributedString *)obj {
    _cachedInputSize = NSZeroSize;
    [super setAttributedStringValue:obj];
}

- (void)setFont:(NSFont *)fontObj {
    _cachedInputSize = NSZeroSize;
    [super setFont:fontObj];
}

- (void)setVerticalAlignment:(LIGridFieldVerticalAlignment)verticalAlignment {
    if (_verticalAlignment != verticalAlignment) {
        _cachedInputSize = NSZeroSize;

        _verticalAlignment = verticalAlignment;
        [self.controlView setNeedsDisplay:YES];
    }
}

#pragma mark -
#pragma mark Layout

- (NSSize)cellSize {
    NSSize cellSize = [super cellSize];
    
    cellSize.width  = ceilf(cellSize.width);
    cellSize.height = ceilf(cellSize.height);
    
    cellSize.height += 2;
    
    return cellSize;
}

- (NSSize)originalCellSizeForBounds:(NSRect)aRect {
    if (!NSEqualSizes(aRect.size, _cachedInputSize)) {
        _cachedCellSize  = [super cellSizeForBounds:aRect];
        _cachedInputSize = aRect.size;
    }
    return _cachedCellSize;
}

- (NSSize)cellSizeForBounds:(NSRect)aRect {
        NSSize cellSize = [self originalCellSizeForBounds:aRect];
        
        cellSize.width  = ceilf(cellSize.width);
        cellSize.height = ceilf(cellSize.height);
        
        cellSize.height += 2;

    return cellSize;
}

- (NSRect)textFrameWithFrame:(NSRect)aRect {
    NSRect textFrame;
    
    textFrame = aRect;
    textFrame.size.height = MIN(aRect.size.height, [self originalCellSizeForBounds:aRect].height);
    
    switch (self.verticalAlignment) {
        case LIGridFieldVerticalAlignment_Top:
            break;
            
        case LIGridFieldVerticalAlignment_Center:
            textFrame.origin.y = NSMidY(aRect) - NSHeight(textFrame) / 2;
            break;
            
        case LIGridFieldVerticalAlignment_Bottom:
            textFrame.origin.y = NSMaxY(aRect) - NSHeight(textFrame);
            break;
    }
    
    // ensure drawing, editing are performed on integral boundaries
    // since when editing, the field editor appears to position itself
    // in that way to avoid messy text rendering...
    
    textFrame = NSIntegralRectWithOptions(textFrame, NSAlignAllEdgesInward);
    
    return textFrame;
}

#pragma mark -
#pragma mark Editing

- (void)editWithFrame:(NSRect)aRect
               inView:(NSView *)controlView
               editor:(NSText *)textObj
             delegate:(id)anObject
                event:(NSEvent *)theEvent {
    
    [super editWithFrame:[self textFrameWithFrame:aRect]
                  inView:controlView
                  editor:textObj
                delegate:anObject
                   event:theEvent];
    
    [self startEditingWithFrame:aRect editor:textObj];
}

- (void)selectWithFrame:(NSRect)aRect
                 inView:(NSView *)controlView
                 editor:(NSText *)textObj
               delegate:(id)anObject
                  start:(NSInteger)selStart
                 length:(NSInteger)selLength {
    
    [super selectWithFrame:[self textFrameWithFrame:aRect]
                    inView:controlView
                    editor:textObj
                  delegate:anObject
                     start:selStart
                    length:selLength];
    
    [self startEditingWithFrame:aRect editor:textObj];
}

- (void)startEditingWithFrame:(NSRect)aRect editor:(NSText *)textObj {
    
    _fieldEditorOriginalFrame = aRect;
    _fieldEditorPositioningCell = self.copy;
    _fieldEditorPositioningCell.stringValue = @"";
    
    textObj.minSize = [_fieldEditorPositioningCell textFrameWithFrame:_fieldEditorOriginalFrame].size;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fieldEditorFrameDidChange:)
                                                 name:NSViewFrameDidChangeNotification
                                               object:textObj];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(fieldEditorFrameDidChange:)
                                                 name:NSTextDidChangeNotification
                                               object:textObj];
}
- (void)endEditing:(NSText *)textObj {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSViewFrameDidChangeNotification
                                                  object:textObj];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSTextDidChangeNotification
                                                  object:textObj];
    
    _fieldEditorPositioningCell = nil;
    
    [super endEditing:textObj];
}

- (void)fieldEditorFrameDidChange:(NSNotification *)aNotification {
    if (_fieldEditorIsBeingPositioned) return;
    
    NSText *textObj = aNotification.object;
    
    _fieldEditorIsBeingPositioned = YES;
    
    _fieldEditorPositioningCell.stringValue = textObj.string;
    NSRect newTextFrame = [_fieldEditorPositioningCell textFrameWithFrame:_fieldEditorOriginalFrame];
    
    [self.controlView setNeedsDisplayInRect:textObj.superview.frame];
    [textObj.superview setFrame:newTextFrame];
    [self.controlView setNeedsDisplayInRect:textObj.superview.frame];
    
    _fieldEditorIsBeingPositioned = NO;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    if (self.backgroundColor) {
        [self.backgroundColor set];
        NSRectFill(cellFrame);
    }
    if (self.isHighlighted && _fieldEditorPositioningCell == nil) {
        [[self highlightColorWithFrame:cellFrame inView:controlView] set];
        NSRectFill(cellFrame);
    }
    
    if (self.vertical) {
        [NSGraphicsContext saveGraphicsState];
        NSAffineTransform *transform = [NSAffineTransform transform];
        
        [transform translateXBy:NSMidX(cellFrame) yBy:NSMidY(cellFrame)];
        [transform rotateByDegrees:-90];
        [transform translateXBy:-NSMidX(cellFrame) yBy:-NSMidY(cellFrame)];
        [transform concat];
    }
    
    NSRect textFrame = [self textFrameWithFrame:cellFrame];
    [super drawWithFrame:textFrame inView:controlView];
    
    if (self.vertical) {
        [NSGraphicsContext restoreGraphicsState];
    }
}

- (NSColor *)highlightColorWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    NSColor *color = [super highlightColorWithFrame:cellFrame inView:controlView];
    
    if ([color isEqual:[NSColor secondarySelectedControlColor]]) {
        return [color blendedColorWithFraction:0.66 ofColor:[NSColor whiteColor]];
    }
    else {
        return color;
    }
}


@end
