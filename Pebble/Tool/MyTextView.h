//
//  MyTextView.h
//  Bamboo
//
//  Created by tpk on 14-9-26.
//  Copyright (c) 2014年 tpk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MyTextView : NSTextView {
    BOOL isCanEdit;
}

@property(nonatomic,assign)long myTag;

- (void)setCanEdit:(BOOL)isEdit;

@end
