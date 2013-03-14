//
//  SpeechService.m
//  SpeakCopy
//
//  Created by Nick Bonatsakis on 12/2/11.
//  Copyright (c) 2011 Atlantia Software. All rights reserved.
//

#import "SpeechService.h"
#import <Carbon/Carbon.h>

id aSelf;

@interface SpeechService()

@property (nonatomic, strong) NSSpeechSynthesizer* speech;

- (void) speakPastedText;
- (NSString*) fetchPastedText;
- (void) doCopy;

@end

OSStatus handleHotKeyPress(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData);

@implementation SpeechService

@synthesize speech;

- (id)init {
    self = [super init];
    if (self) {
        self.speech = [[NSSpeechSynthesizer alloc] init];
        aSelf = self;
        isPaused = NO;
    }
    return self;
}

#define kSpeakHotKeyId 123
#define kSpeakHotKeyId2 124

- (void) startListening {
    EventHotKeyRef hotKeyRef;     
    EventHotKeyID speakKeyId;     
    EventTypeSpec eventType;
    speakKeyId.signature ='spk1';     
    speakKeyId.id = kSpeakHotKeyId;
    eventType.eventClass = kEventClassKeyboard;
    eventType.eventKind = kEventHotKeyPressed;
    InstallApplicationEventHandler(&handleHotKeyPress,1,&eventType,NULL,NULL);
    
    //ToDo - make the keystroke configurable in some UI.
    RegisterEventHotKey(38, cmdKey, speakKeyId, GetApplicationEventTarget(), 0, &hotKeyRef);
    
    EventHotKeyRef hotKeyRef2;
    EventHotKeyID speakKeyId2;
    speakKeyId2.signature ='spk2';
    speakKeyId2.id = kSpeakHotKeyId2;
 
    
    //ToDo - make the keystroke configurable in some UI.
    RegisterEventHotKey(40, cmdKey, speakKeyId2, GetApplicationEventTarget(), 0, &hotKeyRef2); //alt+s for pause
}

OSStatus handleHotKeyPress(EventHandlerCallRef nextHandler,EventRef theEvent,void *userData){
	EventHotKeyID hotKeyID;
	GetEventParameter(theEvent,kEventParamDirectObject,typeEventHotKeyID,
                      NULL,sizeof(hotKeyID),NULL,&hotKeyID);
	int temphotKeyId = hotKeyID.id; //Get the id, so we can know which HotKey we are handling.
    switch(temphotKeyId){
        case kSpeakHotKeyId:
            [aSelf speakPastedText];
            break;
        case kSpeakHotKeyId2:
            [aSelf pausePastedText];
            break;
    }
 
    return noErr;
}




- (void) speakPastedText
{
    if (isPaused)
    {
        [self.speech continueSpeaking];
        isPaused = NO;
    }
    else
    {
        if ([self.speech isSpeaking])
        {
            [self.speech stopSpeaking];
        }
        else
        {
            [self doCopy];
            [self.speech startSpeakingString:[self fetchPastedText]];
        }

    }
    
}
- (void) pausePastedText {
    if ([self.speech isSpeaking])
    {
        [self.speech pauseSpeakingAtBoundary:NSSpeechWordBoundary];
        isPaused = YES;
    }
    else
    {
        [self.speech continueSpeaking];
        isPaused = NO;
    }
}

- (NSString*) fetchPastedText {
    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
    NSArray* classArray = [NSArray arrayWithObject:[NSString class]];
    NSDictionary* options = [NSDictionary dictionary];
    
    BOOL ok = [pasteboard canReadObjectForClasses:classArray options:options];
    NSString* text = @"";
    if (ok) {
        NSArray* objectsToPaste = [pasteboard readObjectsForClasses:classArray options:options];
        text = [objectsToPaste objectAtIndex:0];
    }

    return text;
}

- (void) doCopy {    
    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
    CGEventRef keyDown = CGEventCreateKeyboardEvent(source, (CGKeyCode)8, YES);
    CGEventSetFlags(keyDown, kCGEventFlagMaskCommand);
    CGEventRef keyUp = CGEventCreateKeyboardEvent(source, (CGKeyCode)8, NO);
    
    CGEventPost(kCGAnnotatedSessionEventTap, keyDown);
    // without this wait, the copy seems to not register.
    [NSThread sleepForTimeInterval:0.25];
    CGEventPost(kCGAnnotatedSessionEventTap, keyUp);
    
    CFRelease(keyUp);
    CFRelease(keyDown);
    CFRelease(source);
}


@end
