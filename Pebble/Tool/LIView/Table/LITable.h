//
//  LITable.h
//  Table
//
//  Created by Mark Onyschuk on 12/20/13.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LITableLayouts.h"
#import <Cocoa/Cocoa.h>

@class LIGrid, LIShadow, LITableLayout;

@interface LITable : NSView

#pragma mark -
#pragma mark Layout Manager

@property(nonatomic, strong) id <LITableLayouts> tableLayout;

@property(nonatomic, strong) LITableLayout *layoutManager __attribute__((deprecated));

#pragma mark -
#pragma mark Views

@property(readonly, nonatomic, strong) LIShadow *rowShadow, *columnShadow;
@property(readonly, nonatomic, strong) LIGrid *grid, *rowHeader, *columnHeader;

#pragma mark -
#pragma mark Reload

- (void)reloadData;


@end
