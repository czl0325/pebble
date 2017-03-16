//
//  NSWindow+NSWindowExt.m
//  Plum
//
//  Created by tpk on 14-11-7.
//  Copyright (c) 2014年 tpk. All rights reserved.
//

#import "NSWindowExt.h"

@implementation NSWindow (NSWindowExt)

- (CGFloat)left {
	return self.frame.origin.x;
}

- (CGFloat)width {
	return self.frame.size.width;
}

- (CGFloat)height {
	return self.frame.size.height;
}

@end
