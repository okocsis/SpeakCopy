//
//  AppDelegate.m
//  SpeakCopy
//
//  Created by Nick Bonatsakis on 12/2/11.
//  Copyright (c) 2011 Atlantia Software. All rights reserved.
//

#import "AppDelegate.h"
#import "SpeechService.h"

@interface AppDelegate()

@property (nonatomic, strong) SpeechService* speechService;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.speechService = [SpeechService new];
    
    [self.speechService startListening];
}

@end
