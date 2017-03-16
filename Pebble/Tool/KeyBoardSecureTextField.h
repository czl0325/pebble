//
//  KeyBoardSecureTextField.h
//  Jedi
//
//  Created by tpk on 15-1-12.
//  Copyright (c) 2015年 tpk. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class KeyBoardSecureTextField;
@protocol KeyBoardSecureTextFieldDelegate <NSObject>
@optional
- (void)acceptKeyCode:(KeyBoardSecureTextField*)KeyBoardSecureTextField keyCode:(unsigned short)keyCode;
@end

@interface KeyBoardSecureTextField : NSSecureTextField

@property (nonatomic, strong) id<KeyBoardSecureTextFieldDelegate> mydelegate;

@end
