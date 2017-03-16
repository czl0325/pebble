/*
 Copyright (c) 2008 Matthew Ball - http://www.mattballdesign.com
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */

#import "MBTableGridContentView.h"

#import "MBTableGrid.h"
#import "MBTableGridCell.h"


#define kGRAB_HANDLE_HALF_SIDE_LENGTH 2.0f
#define kGRAB_HANDLE_SIDE_LENGTH 4.0f

@interface MBTableGrid (Private)
- (id)_objectValueForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;
- (void)_setObjectValue:(id)value forColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;
- (BOOL)_canEditCellAtColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;
- (void)_setStickyColumn:(MBTableGridEdge)stickyColumn row:(MBTableGridEdge)stickyRow;
- (float)_widthForColumn:(NSUInteger)columnIndex;
- (id)_backgroundColorForColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex;
- (MBTableGridEdge)_stickyColumn;
- (MBTableGridEdge)_stickyRow;
@end

@interface MBTableGridContentView (Cursors)
- (NSCursor *)_cellSelectionCursor;
- (NSImage *)_cellSelectionCursorImage;
- (NSCursor *)_cellExtendSelectionCursor;
- (NSImage *)_cellExtendSelectionCursorImage;
@end

@interface MBTableGridContentView (DragAndDrop)
- (void)_setDraggingColumnOrRow:(BOOL)flag;
- (void)_setDropColumn:(NSInteger)columnIndex;
- (void)_setDropRow:(NSInteger)rowIndex;
- (void)_timerAutoscrollCallback:(NSTimer *)aTimer;
@end

@implementation MBTableGridContentView

#pragma mark -
#pragma mark Initialization & Superclass Overrides

- (id)initWithFrame:(NSRect)frameRect
{
	if(self = [super initWithFrame:frameRect]) {
		mouseDownColumn = NSNotFound;
		mouseDownRow = NSNotFound;
		
		editedColumn = NSNotFound;
		editedRow = NSNotFound;
		
		dropColumn = NSNotFound;
		dropRow = NSNotFound;
        
        
        grabHandleRect = NSRectFromCGRect(CGRectZero);
		
		// Cache the cursor image
		cursorImage = [self _cellSelectionCursorImage];
        cursorExtendSelectionImage = [self _cellExtendSelectionCursorImage];
		
		isDraggingColumnOrRow = NO;
		
		_cell = [[MBTableGridCell alloc] initTextCell:@""];
        [_cell setBordered:YES];
		[_cell setScrollable:YES];
		[_cell setLineBreakMode:NSLineBreakByTruncatingTail];
	}
	return self;
}


- (void)drawRect:(NSRect)rect
{
    
	NSUInteger numberOfColumns = [self tableGrid].numberOfColumns;
	NSUInteger numberOfRows = [self tableGrid].numberOfRows;
	
	NSUInteger firstColumn = NSNotFound;
	NSUInteger lastColumn = numberOfColumns - 1;
	NSUInteger firstRow = NSNotFound;
	NSUInteger lastRow = numberOfRows - 1;
	
	// Find the columns to draw
	NSUInteger column = 0;
	while (column < numberOfColumns) {
		NSRect columnRect = [self rectOfColumn:column];
		if (firstColumn == NSNotFound && NSMinX([self visibleRect]) >= NSMinX(columnRect) && NSMinX([self visibleRect]) <= NSMaxX(columnRect)) {
			firstColumn = column;
		} else if (firstColumn != NSNotFound && NSMaxX([self visibleRect]) >= NSMinX(columnRect) && NSMaxX([self visibleRect]) <= NSMaxX(columnRect)) {
			lastColumn = column;
			break;
		}
		column++;
	}
	
	// Find the rows to draw
	NSUInteger row = 0;
	while (row < numberOfRows) {
		NSRect rowRect = [self rectOfRow:row];
		if (firstRow == NSNotFound && NSMinY([self visibleRect]) >= rowRect.origin.x && NSMinY([self visibleRect]) <= NSMaxY(rowRect)) {
			firstRow = row;
		} else if (firstRow != NSNotFound && NSMaxY([self visibleRect]) >= NSMinY(rowRect) && NSMaxY([self visibleRect]) <= NSMaxY(rowRect)) {
			lastRow = row;
			break;
		}
		row++;
	}	
	
	column = firstColumn;
	while (column <= lastColumn) {
		row = firstRow;
		while (row <= lastRow) {
			NSRect cellFrame = [self frameOfCellAtColumn:column row:row];
			// Only draw the cell if we need to
			if ([self needsToDrawRect:cellFrame] && !(row == editedRow && column == editedColumn)) {
                
                NSColor *backgroundColor = [[self tableGrid] _backgroundColorForColumn:column row:row] ?: [NSColor whiteColor];
                
                
				[_cell setObjectValue:[[self tableGrid] _objectValueForColumn:column row:row]];
				[_cell drawWithFrame:cellFrame inView:self withBackgroundColor:backgroundColor];// Draw background color
                
			}
			row++;
		}
		column++;
	}
	
	// Draw the selection rectangle
	NSIndexSet *selectedColumns = [[self tableGrid] selectedColumnIndexes];
	NSIndexSet *selectedRows = [[self tableGrid] selectedRowIndexes];
	
	if([selectedColumns count] && [selectedRows count] && [self tableGrid].numberOfColumns > 0 && [self tableGrid].numberOfRows > 0) {
		NSRect selectionTopLeft = [self frameOfCellAtColumn:[selectedColumns firstIndex] row:[selectedRows firstIndex]];
		NSRect selectionBottomRight = [self frameOfCellAtColumn:[selectedColumns lastIndex] row:[selectedRows lastIndex]];
		
		NSRect selectionRect;
		selectionRect.origin = selectionTopLeft.origin;
		selectionRect.size.width = NSMaxX(selectionBottomRight)-selectionTopLeft.origin.x;
		selectionRect.size.height = NSMaxY(selectionBottomRight)-selectionTopLeft.origin.y;
		
        NSRect selectionInsetRect = NSInsetRect(selectionRect, 1, 1);
		NSBezierPath *selectionPath = [NSBezierPath bezierPathWithRect:selectionInsetRect];
		NSAffineTransform *translate = [NSAffineTransform transform];
		[translate translateXBy:-0.5 yBy:-0.5];
		[selectionPath transformUsingAffineTransform:translate];
		
		NSColor *selectionColor = [NSColor alternateSelectedControlColor];
		
		// If the view is not the first responder, then use a gray selection color
		NSResponder *firstResponder = [[self window] firstResponder];
		if (![[firstResponder class] isSubclassOfClass:[NSView class]] || ![(NSView *)firstResponder isDescendantOf:[self tableGrid]] || ![[self window] isKeyWindow]) {
			selectionColor = [[selectionColor colorUsingColorSpaceName:NSDeviceWhiteColorSpace] colorUsingColorSpaceName:NSDeviceRGBColorSpace];
		}
        else
        {
            // Draw grab handle
            [selectionColor set];
            grabHandleRect = NSMakeRect(NSMaxX(selectionInsetRect) - kGRAB_HANDLE_HALF_SIDE_LENGTH, NSMaxY(selectionInsetRect) - kGRAB_HANDLE_HALF_SIDE_LENGTH, kGRAB_HANDLE_SIDE_LENGTH, kGRAB_HANDLE_SIDE_LENGTH);
            NSRectFill(grabHandleRect);
        }
		
		[selectionColor set];
		[selectionPath setLineWidth: 1.0];
		[selectionPath stroke];
        
        [[selectionColor colorWithAlphaComponent:0.2f] set];
        [selectionPath fill];
        
        // Inavlidate cursors so we use the correct cursor for the selection in the right place
        [[self window] invalidateCursorRectsForView:self];
	}
	
	// Draw the column drop indicator
	if (isDraggingColumnOrRow && dropColumn != NSNotFound && dropColumn <= [self tableGrid].numberOfColumns && dropRow == NSNotFound) {
		NSRect columnBorder;
		if(dropColumn < [self tableGrid].numberOfColumns) {
			columnBorder = [self rectOfColumn:dropColumn];
		} else {
			columnBorder = [self rectOfColumn:dropColumn-1];
			columnBorder.origin.x += columnBorder.size.width;
		}
		columnBorder.origin.x = NSMinX(columnBorder)-2.0;
		columnBorder.size.width = 4.0;
		
		NSColor *selectionColor = [NSColor alternateSelectedControlColor];
		
		NSBezierPath *borderPath = [NSBezierPath bezierPathWithRect:columnBorder];
		[borderPath setLineWidth:2.0];
		
		[selectionColor set];
		[borderPath stroke];
	}
	
	// Draw the row drop indicator
	if (isDraggingColumnOrRow && dropRow != NSNotFound && dropRow <= [self tableGrid].numberOfRows && dropColumn == NSNotFound) {
		NSRect rowBorder;
		if(dropRow < [self tableGrid].numberOfRows) {
			rowBorder = [self rectOfRow:dropRow];
		} else {
			rowBorder = [self rectOfRow:dropRow-1];
			rowBorder.origin.y += rowBorder.size.height;
		}
		rowBorder.origin.y = NSMinY(rowBorder)-2.0;
		rowBorder.size.height = 4.0;
		
		NSColor *selectionColor = [NSColor alternateSelectedControlColor];
		
		NSBezierPath *borderPath = [NSBezierPath bezierPathWithRect:rowBorder];
		[borderPath setLineWidth:2.0];
		
		[selectionColor set];
		[borderPath stroke];
	}
	
	// Draw the cell drop indicator
	if (!isDraggingColumnOrRow && dropRow != NSNotFound && dropRow <= [self tableGrid].numberOfRows && dropColumn != NSNotFound && dropColumn <= [self tableGrid].numberOfColumns) {
		NSRect cellFrame = [self frameOfCellAtColumn:dropColumn row:dropRow];
		cellFrame.origin.x -= 2.0;
		cellFrame.origin.y -= 2.0;
		cellFrame.size.width += 3.0;
		cellFrame.size.height += 3.0;
		
		NSBezierPath *borderPath = [NSBezierPath bezierPathWithRect:NSInsetRect(cellFrame, 2, 2)];
		
		NSColor *dropColor = [NSColor alternateSelectedControlColor];
		[dropColor set];
		
		[borderPath setLineWidth:2.0];
		[borderPath stroke];
	}
}

- (BOOL)isFlipped
{
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
    
    // Setup the timer for autoscrolling
	// (the simply calling autoscroll: from mouseDragged: only works as long as the mouse is moving)
	autoscrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_timerAutoscrollCallback:) userInfo:nil repeats:YES];
	
	NSPoint loc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	mouseDownColumn = [self columnAtPoint:loc];
	mouseDownRow = [self rowAtPoint:loc];
	
	if([theEvent clickCount] == 1) {
		// Pass the event back to the MBTableGrid (Used to give First Responder status)
		[[self tableGrid] mouseDown:theEvent];
		
		// Single click
		if(([theEvent modifierFlags] & NSShiftKeyMask) && [self tableGrid].allowsMultipleSelection) {
			// If the shift key was held down, extend the selection
			NSUInteger stickyColumn = [[self tableGrid].selectedColumnIndexes firstIndex];
			NSUInteger stickyRow = [[self tableGrid].selectedRowIndexes firstIndex];
			
			MBTableGridEdge stickyColumnEdge = [[self tableGrid] _stickyColumn];
			MBTableGridEdge stickyRowEdge = [[self tableGrid] _stickyRow];
			
			// Compensate for sticky edges
			if (stickyColumnEdge == MBTableGridRightEdge) {
				stickyColumn = [[self tableGrid].selectedColumnIndexes lastIndex];
			}
			if (stickyRowEdge == MBTableGridBottomEdge) {
				stickyRow = [[self tableGrid].selectedRowIndexes lastIndex];
			}
			
			NSRange selectionColumnRange = NSMakeRange(stickyColumn, mouseDownColumn-stickyColumn+1);
			NSRange selectionRowRange = NSMakeRange(stickyRow, mouseDownRow-stickyRow+1);
			
			if (mouseDownColumn < stickyColumn) {
				selectionColumnRange = NSMakeRange(mouseDownColumn, stickyColumn-mouseDownColumn+1);
				stickyColumnEdge = MBTableGridRightEdge;
			} else {
				stickyColumnEdge = MBTableGridLeftEdge;
			}
			
			if (mouseDownRow < stickyRow) {
				selectionRowRange = NSMakeRange(mouseDownRow, stickyRow-mouseDownRow+1);
				stickyRowEdge = MBTableGridBottomEdge;
			} else {
				stickyRowEdge = MBTableGridTopEdge;
			}
			
			// Select the proper cells
			[self tableGrid].selectedColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:selectionColumnRange];
			[self tableGrid].selectedRowIndexes = [NSIndexSet indexSetWithIndexesInRange:selectionRowRange];
			
			// Set the sticky edges
			[[self tableGrid] _setStickyColumn:stickyColumnEdge row:stickyRowEdge];
		} else {
			// No modifier keys, so change the selection
			[self tableGrid].selectedColumnIndexes = [NSIndexSet indexSetWithIndex:mouseDownColumn];
			[self tableGrid].selectedRowIndexes = [NSIndexSet indexSetWithIndex:mouseDownRow];
			[[self tableGrid] _setStickyColumn:MBTableGridLeftEdge row:MBTableGridTopEdge];
		}
        
        [self setNeedsDisplay:YES];
        
	} else if([theEvent clickCount] == 2) {
		// Double click
		[self editSelectedCell:self];
        [self setNeedsDisplay:YES];
	}
}

- (void)mouseDragged:(NSEvent *)theEvent
{
	if (mouseDownColumn != NSNotFound && mouseDownRow != NSNotFound && [self tableGrid].allowsMultipleSelection) {
		NSPoint loc = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		NSInteger column = [self columnAtPoint:loc];
		NSInteger row = [self rowAtPoint:loc];
		
		MBTableGridEdge columnEdge = MBTableGridLeftEdge;
		MBTableGridEdge rowEdge = MBTableGridTopEdge;
		
		// Select the appropriate number of columns
		if(column != NSNotFound) {
			NSInteger firstColumnToSelect = mouseDownColumn;
			NSInteger numberOfColumnsToSelect = column-mouseDownColumn+1;
			if(column < mouseDownColumn) {
				firstColumnToSelect = column;
				numberOfColumnsToSelect = mouseDownColumn-column+1;
				
				// Set the sticky edge to the right
				columnEdge = MBTableGridRightEdge;
			}
			
			[self tableGrid].selectedColumnIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstColumnToSelect,numberOfColumnsToSelect)];
			
		}
		
		// Select the appropriate number of rows
		if(row != NSNotFound) {
			NSInteger firstRowToSelect = mouseDownRow;
			NSInteger numberOfRowsToSelect = row-mouseDownRow+1;
			if(row < mouseDownRow) {
				firstRowToSelect = row;
				numberOfRowsToSelect = mouseDownRow-row+1;
				
				// Set the sticky row to the bottom
				rowEdge = MBTableGridBottomEdge;
			}
			
			[self tableGrid].selectedRowIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(firstRowToSelect,numberOfRowsToSelect)];
			
		}
		
		// Set the sticky edges
		[[self tableGrid] _setStickyColumn:columnEdge row:rowEdge];
		
        [self setNeedsDisplay:YES];
	}
	
//	[self autoscroll:theEvent];
}

- (void)mouseUp:(NSEvent *)theEvent
{
	[autoscrollTimer invalidate];
	autoscrollTimer = nil;
	
	mouseDownColumn = NSNotFound;
	mouseDownRow = NSNotFound;
}

#pragma mark Cursor Rects

- (void)resetCursorRects
{
    //NSLog(@"%s - %f %f %f %f", __func__, grabHandleRect.origin.x, grabHandleRect.origin.y, grabHandleRect.size.width, grabHandleRect.size.height);
	// The main cursor should be the cell selection cursor
	[self addCursorRect:[self visibleRect] cursor:[self _cellSelectionCursor]];
    [self addCursorRect:grabHandleRect cursor:[self _cellExtendSelectionCursor]];
}

#pragma mark -
#pragma mark Notifications

#pragma mark Field Editor

- (void)textDidEndEditing:(NSNotification *)aNotification
{	
	// Give focus back to the table grid (the field editor took it)
	[[self window] makeFirstResponder:[self tableGrid]];
	
	NSString *value = [[[aNotification object] string] copy];
	[[self tableGrid] _setObjectValue:value forColumn:editedColumn row:editedRow];
	
	editedColumn = NSNotFound;
	editedRow = NSNotFound;
	
	// End the editing session
	[[[self tableGrid] cell] endEditing:[[self window] fieldEditor:NO forObject:self]];
}

#pragma mark -
#pragma mark Protocol Methods

#pragma mark NSDraggingDestination

/*
 * These methods simply pass the drag event back to the table grid.
 * They are only required for autoscrolling.
 */

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	// Setup the timer for autoscrolling 
	// (the simply calling autoscroll: from mouseDragged: only works as long as the mouse is moving)
	autoscrollTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(_timerAutoscrollCallback:) userInfo:nil repeats:YES];
	
	return [[self tableGrid] draggingEntered:sender];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender
{
	return [[self tableGrid] draggingUpdated:sender];
}

- (void)draggingExited:(id <NSDraggingInfo>)sender
{
	[autoscrollTimer invalidate];
	autoscrollTimer = nil;
	
	[[self tableGrid] draggingExited:sender];
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender
{
	[[self tableGrid] draggingEnded:sender];
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	return [[self tableGrid] prepareForDragOperation:sender];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	return [[self tableGrid] performDragOperation:sender];
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender
{
	[[self tableGrid] concludeDragOperation:sender];
}

#pragma mark -
#pragma mark Subclass Methods

- (MBTableGrid *)tableGrid
{
	return (MBTableGrid *)[[self enclosingScrollView] superview];
}

- (void)editSelectedCell:(id)sender
{
	// Get the top-left selection
	editedColumn = [[self tableGrid].selectedColumnIndexes firstIndex];
	editedRow = [[self tableGrid].selectedRowIndexes firstIndex];
	
	// Check if the cell can be edited
	if(![[self tableGrid] _canEditCellAtColumn:editedColumn row:editedRow]) {
		editedColumn = NSNotFound;
		editedRow = NSNotFound;
		return;
	}
	
	// Select it and only it
	if([[self tableGrid].selectedColumnIndexes count] > 1) {
		[self tableGrid].selectedColumnIndexes = [NSIndexSet indexSetWithIndex:editedColumn];
	}
	if([[self tableGrid].selectedRowIndexes count] > 1) {
		[self tableGrid].selectedRowIndexes = [NSIndexSet indexSetWithIndex:editedRow];
	}
	
	NSTextFieldCell *cell = [[self tableGrid] cell];
	[cell setEditable:YES];
	[cell setSelectable:YES];
	[cell setObjectValue:[[self tableGrid] _objectValueForColumn:editedColumn row:editedRow]];
	
	NSRect cellFrame = [self frameOfCellAtColumn:editedColumn row:editedRow];
	NSText *editor = [[self window] fieldEditor:YES forObject:self];
	[cell editWithFrame:cellFrame inView:self editor:editor delegate:self event:nil];
}

#pragma mark Layout Support
- (NSRect)rectOfColumn:(NSUInteger)columnIndex {
    float width = [[self tableGrid] _widthForColumn:columnIndex];

	NSRect rect = NSMakeRect(0, 0, width, [self frame].size.height);
	//rect.origin.x += 60.0 * columnIndex;
	
	NSUInteger i = 0;
	while(i < columnIndex) {
        float headerWidth = [[self tableGrid] _widthForColumn:i];
		rect.origin.x += headerWidth;
		i++;
	}
	
	return rect;
}

- (NSRect)rectOfRow:(NSUInteger)rowIndex
{
    
	float heightForRow = 20.0;
	NSRect rect = NSMakeRect(0, 0, [self frame].size.width, heightForRow);
	
	rect.origin.y += 20.0 * rowIndex;
	
	/*NSUInteger i = 0;
	while(i < rowIndex) {
		float rowHeight = rect.size.height;
		rect.origin.y += rowHeight;
		i++;
	}*/
	
	return rect;
}

- (NSRect)frameOfCellAtColumn:(NSUInteger)columnIndex row:(NSUInteger)rowIndex
{
	NSRect columnRect = [self rectOfColumn:columnIndex];
	NSRect rowRect = [self rectOfRow:rowIndex];
	return NSMakeRect(columnRect.origin.x, rowRect.origin.y, columnRect.size.width, rowRect.size.height);
}

- (NSInteger)columnAtPoint:(NSPoint)aPoint
{
	NSInteger column = 0;
	while(column < [self tableGrid].numberOfColumns) {
		NSRect columnFrame = [self rectOfColumn:column];
		if(NSPointInRect(aPoint, columnFrame)) {
			return column;
		}
		column++;
	}
	return NSNotFound;
}

- (NSInteger)rowAtPoint:(NSPoint)aPoint
{
	NSInteger row = 0;
	while(row < [self tableGrid].numberOfRows) {
		NSRect rowFrame = [self rectOfRow:row];
		if(NSPointInRect(aPoint, rowFrame)) {
			return row;
		}
		row++;
	}
	return NSNotFound;
}

@end

@implementation MBTableGridContentView (Cursors)

- (NSCursor *)_cellSelectionCursor
{
	NSCursor *cursor = [[NSCursor alloc] initWithImage:cursorImage hotSpot:NSMakePoint(8, 8)];
	return cursor;
}

/**
 * @warning		This method is not as efficient as it could be, but
 *				it should only be called once, at initialization.
 *				TODO: Make it faster
 */
- (NSImage *)_cellSelectionCursorImage
{
	NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(20, 20)];
	[image setFlipped:YES];
	[image lockFocus];
	
	NSRect horizontalInner = NSMakeRect(7.0, 2.0, 2.0, 12.0);
	NSRect verticalInner = NSMakeRect(2.0, 7.0, 12.0, 2.0);
	
	NSRect horizontalOuter = NSInsetRect(horizontalInner, -1.0, -1.0);
	NSRect verticalOuter = NSInsetRect(verticalInner, -1.0, -1.0);
	
	// Set the shadow
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.8]];
	[shadow setShadowBlurRadius:2.0];
	[shadow setShadowOffset:NSMakeSize(0, -1.0)];
	
	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	[shadow set];
	
	[[NSColor blackColor] set];
	NSRectFill(horizontalOuter);
	NSRectFill(verticalOuter);
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
	// Fill them again to compensate for the shadows
	NSRectFill(horizontalOuter);
	NSRectFill(verticalOuter);
	
	[[NSColor whiteColor] set];
	NSRectFill(horizontalInner);
	NSRectFill(verticalInner);
	
	[image unlockFocus];
	
	return image;
}

- (NSCursor *)_cellExtendSelectionCursor
{
	NSCursor *cursor = [[NSCursor alloc] initWithImage:cursorExtendSelectionImage hotSpot:NSMakePoint(8, 8)];
	return cursor;
}

/**
 * @warning		This method is not as efficient as it could be, but
 *				it should only be called once, at initialization.
 *				TODO: Make it faster
 */
- (NSImage *)_cellExtendSelectionCursorImage
{
	NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(20, 20)];
	[image setFlipped:YES];
	[image lockFocus];
	
	NSRect horizontalInner = NSMakeRect(7.0, 2.0, 2.0, 12.0);
	NSRect verticalInner = NSMakeRect(2.0, 7.0, 12.0, 2.0);
	
	NSRect horizontalOuter = NSInsetRect(horizontalInner, -1.0, -1.0);
	NSRect verticalOuter = NSInsetRect(verticalInner, -1.0, -1.0);
	
	// Set the shadow
	NSShadow *shadow = [[NSShadow alloc] init];
	[shadow setShadowColor:[NSColor colorWithDeviceWhite:0.0 alpha:0.8]];
	[shadow setShadowBlurRadius:2.0];
	[shadow setShadowOffset:NSMakeSize(0, -1.0)];
	
	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	[shadow set];
	
	[[NSColor blackColor] set];
	NSRectFill(horizontalOuter);
	NSRectFill(verticalOuter);
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
	// Fill them again to compensate for the shadows
	NSRectFill(horizontalOuter);
	NSRectFill(verticalOuter);
	
	[[NSColor blackColor] set];
	NSRectFill(horizontalInner);
	NSRectFill(verticalInner);
	
	[image unlockFocus];
	
	return image;
}

@end

@implementation MBTableGridContentView (DragAndDrop)

- (void)_setDraggingColumnOrRow:(BOOL)flag
{
	isDraggingColumnOrRow = flag;
}

- (void)_setDropColumn:(NSInteger)columnIndex
{
	dropColumn = columnIndex;
	[self setNeedsDisplay:YES];
}

- (void)_setDropRow:(NSInteger)rowIndex
{
	dropRow = rowIndex;
	[self setNeedsDisplay:YES];
}

- (void)_timerAutoscrollCallback:(NSTimer *)aTimer
{
	NSEvent* event = [NSApp currentEvent];
    if ([event type] == NSLeftMouseDragged )
        [self autoscroll:event];
}

@end
