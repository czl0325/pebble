//
//  MyTableView.h
//  Jedi
//
//  Created by tpk on 15-1-4.
//  Copyright (c) 2015年 tpk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MyTableView;
@protocol MyTableViewDelegate <NSObject>
@optional
- (void)myTableViewDidDoubleClickRow:(NSInteger)row column:(NSInteger)column;
@end

@interface MyTableView : NSTableView

@property (nonatomic, strong) id<MyTableViewDelegate> mydelegate;

@end
