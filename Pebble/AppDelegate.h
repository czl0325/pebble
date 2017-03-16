//
//  AppDelegate.h
//  Pebble
//
//  Created by tpk on 15/1/19.
//  Copyright (c) 2015年 tpk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "RootWindowController.h"

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property(strong,nonatomic)RootWindowController* root;

@end

