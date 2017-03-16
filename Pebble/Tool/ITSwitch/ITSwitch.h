//
//  ITSwitch.h
//  ITSwitch-Demo
//
//  Created by Ilija Tovilo on 01/02/14.
//  Copyright (c) 2014 Ilija Tovilo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

/**
 *  ITSwitch is a replica of UISwitch for Mac OS X
 */
@interface ITSwitch : NSControl

/**
 *  @property isOn - Gets or sets the switches state
 */
@property (nonatomic, setter = setOn:) BOOL isOn;

/**
 *  @property tintColor - Gets or sets the switches tint
 */
@property (nonatomic, strong) NSColor *tintColor;

/**
 *  @property enabled - Gets or sets whether the switch is disabled or not
 *                      The Property is inherited from NSControl, which is why we override it's accessors
 */
- (BOOL)isEnabled;
- (void)setEnabled:(BOOL)enabled;


@end
