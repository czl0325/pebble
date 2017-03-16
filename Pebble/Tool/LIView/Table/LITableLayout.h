//
//  LITableLayout.h
//  Matrix
//
//  Created by Mark Onyschuk on 2013-12-31.
//  Copyright (c) 2013 Mark Onyschuk. All rights reserved.
//

#import "LIGrid.h"

@class LITable;

 __attribute__((deprecated))
@interface LITableLayout : NSResponder <LIGridDataSource, LIGridDelegate>

- (void)awakeInTableView:(LITable *)table;

- (void)reloadData;

@property(readonly, nonatomic, weak) LITable *tableView;

@end
