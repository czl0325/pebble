//
//  KeyBoardTextField.h
//  KingCrab
//
//  Created by tpk on 14-10-28.
//  Copyright (c) 2014年 tpk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class KeyBoardTextField;
@protocol KeyBoardTextFieldDelegate <NSObject>
@optional
- (void)acceptKeyCode:(KeyBoardTextField*)keyboardTextField keyCode:(unsigned short)keyCode;
@end

@interface KeyBoardTextField : NSTextField

@property (nonatomic, strong) id<KeyBoardTextFieldDelegate> mydelegate;

@end
