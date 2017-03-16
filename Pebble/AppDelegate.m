//
//  AppDelegate.m
//  Pebble
//
//  Created by tpk on 15/1/19.
//  Copyright (c) 2015年 tpk. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate

@synthesize root;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    root = [[RootWindowController alloc]initWithWindowNibName:@"RootWindowController"];
    root.JNWindow = (JNWAnimatableWindow*)root.window;
    //root.JNWindow.titlebarColor = [NSColor cyanColor];
    root.JNWindow.titleColor = [NSColor purpleColor];
    root.JNWindow.titleFont = [NSFont fontWithName:@"AmericanTypewriter" size:13];
    NSRect screenRC = [[NSScreen mainScreen] frame];
    [root.JNWindow setFrame:NSMakeRect(screenRC.size.width/2-root.JNWindow.width/2, screenRC.size.height/2-root.JNWindow.height/2, root.JNWindow.width, root.JNWindow.height) display:YES];
    [root.JNWindow makeKeyAndOrderFrontWithDuration:0.8 timing:nil setup:^(CALayer *layer) {
        CATransform3D transform  = CATransform3DMakeTranslation(700, 0, 0); //顺时针旋转M_PI， 也就是180度
        layer.transform = transform;
        layer.opacity = 0.f;
    } animations:^(CALayer *layer) {
        CATransform3D transform  = CATransform3DMakeTranslation(0, 0, 0); //顺时针旋转M_PI， 也就是180度
        layer.transform = transform;
        layer.opacity = 1.f;
    }];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication {
    return YES;
}


@end
