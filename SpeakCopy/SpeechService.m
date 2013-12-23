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
{
    BOOL _isPaused;
}
@property (nonatomic) BOOL stoppedOnDemand;
@property (nonatomic, strong) NSSpeechSynthesizer* speech;
@property (atomic, strong) NSMutableArray *sentencesToSpeakArray;
@property (nonatomic) NSUInteger sentencesToSpeakArrayIndex;



- (void) speakPastedText;
- (NSString*) fetchPastedText;
- (void) doCopy;

@end

OSStatus handleHotKeyPress(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData);

@implementation SpeechService

@synthesize speech;
//-(NSUInteger) sentencesToSpeakArrayIndex
//{
//    return _sentencesToSpeakArrayIndex < [_sentencesToSpeakArray count] ? _sentencesToSpeakArrayIndex : [_sentencesToSpeakArray count]-1;
//}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.speech = [[NSSpeechSynthesizer alloc] init];
        self.speech.delegate = self;
        aSelf = self;
        _isPaused = NO;
        _sentencesToSpeakArray = [NSMutableArray new];
        
    }
    return self;
}

#define kSpeakHotKeyId 123
#define kSpeakHotKeyId2 124
#define kSpeakHotKeyId3 125
#define kSpeakHotKeyId4 126
- (void) incrSentencesToSpeakArrayIndex
{
    if (self.sentencesToSpeakArrayIndex < [self.sentencesToSpeakArray count]-1)
    {
    ++_sentencesToSpeakArrayIndex;
    }
}
- (void) decrSentencesToSpeakArrayIndex
{
    if (self.sentencesToSpeakArrayIndex > 0)
    {
    --_sentencesToSpeakArrayIndex;
    }
}
- (void) startListening
{
    EventHotKeyRef hotKeyRef;     
    EventHotKeyID speakKeyId;     
    EventTypeSpec eventType;
    speakKeyId.signature ='spk1';     
    speakKeyId.id = kSpeakHotKeyId;
    eventType.eventClass = kEventClassKeyboard;
    eventType.eventKind = kEventHotKeyPressed;
    InstallApplicationEventHandler(&handleHotKeyPress,1,&eventType,NULL,NULL);
    
    //ToDo - make the keystroke configurable in some UI.
    RegisterEventHotKey(38, cmdKey, speakKeyId, GetApplicationEventTarget(), 0, &hotKeyRef);//cmd+j for pause
    
    EventHotKeyRef hotKeyRef2;
    EventHotKeyID speakKeyId2;
    speakKeyId2.signature ='spk2';
    speakKeyId2.id = kSpeakHotKeyId2;
 
    
    //ToDo - make the keystroke configurable in some UI.
    RegisterEventHotKey(40, cmdKey, speakKeyId2, GetApplicationEventTarget(), 0, &hotKeyRef2); //cmd+k for pause
    
    EventHotKeyRef hotKeyRef3;
    EventHotKeyID speakKeyId3;
    speakKeyId3.signature ='spk3';
    speakKeyId3.id = kSpeakHotKeyId3;
    
    
    //ToDo - make the keystroke configurable in some UI.
    RegisterEventHotKey(38, cmdKey+optionKey, speakKeyId3, GetApplicationEventTarget(), 0, &hotKeyRef3);
    //cmd+otpion+j for step one senctece back
    
    EventHotKeyRef hotKeyRef4;
    EventHotKeyID speakKeyId4;
    speakKeyId4.signature ='spk4';
    speakKeyId4.id = kSpeakHotKeyId4;
    
    
    //ToDo - make the keystroke configurable in some UI.
    RegisterEventHotKey(40, cmdKey+optionKey, speakKeyId4, GetApplicationEventTarget(), 0, &hotKeyRef4);
    //cmd+otpion+k for for step one senctece forward
}

OSStatus handleHotKeyPress(EventHandlerCallRef nextHandler,EventRef theEvent,void *userData)
{
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
        case kSpeakHotKeyId3:
            [aSelf decrSentencesToSpeakArrayIndex];
            [[aSelf speech] stopSpeaking];
            [aSelf setStoppedOnDemand:YES];
            [aSelf speakAtSomeIndex];
            break;
        case kSpeakHotKeyId4:
            [aSelf incrSentencesToSpeakArrayIndex];
            [[aSelf speech] stopSpeaking];
            [aSelf setStoppedOnDemand:YES];
            [aSelf speakAtSomeIndex];
            break;
    }
 
    return noErr;
}




- (void) speakPastedText
{
    if (_isPaused)
    {
        [self.speech continueSpeaking];
        _isPaused = NO;
    }
    else
    {
        if ([self.speech isSpeaking])
        {
            [self.speech stopSpeaking];
            _stoppedOnDemand = YES;
        }
        else
        {
            [self doCopy];
            [self fetchPastedText];
            self.sentencesToSpeakArrayIndex = 0;
            [self.speech startSpeakingString:self.sentencesToSpeakArray[self.sentencesToSpeakArrayIndex]];

        }

    }
    
}
- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender didFinishSpeaking:(BOOL)finishedSpeaking
{
    if (!_stoppedOnDemand)
    {
        [self incrSentencesToSpeakArrayIndex];
        [self speakAtSomeIndex];
    }
    _stoppedOnDemand = NO;
    
    
}

-(void) speakAtSomeIndex
{

        [self.speech startSpeakingString:self.sentencesToSpeakArray[self.sentencesToSpeakArrayIndex]];

}
- (void) pausePastedText
{
    if ([self.speech isSpeaking])
    {
        [self.speech pauseSpeakingAtBoundary:NSSpeechWordBoundary];
        _isPaused = YES;
    }
    else
    {
        [self.speech continueSpeaking];
        _isPaused = NO;
    }
}

- (NSString*) fetchPastedText
{
    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
    NSArray* classArray = [NSArray arrayWithObject:[NSString class]];
    NSDictionary* options = [NSDictionary dictionary];
    
    BOOL ok = [pasteboard canReadObjectForClasses:classArray options:options];
    NSString* text = @"";
    if (ok)
    {
        NSArray* objectsToPaste = [pasteboard readObjectsForClasses:classArray options:options];
        text = [objectsToPaste objectAtIndex:0];
    }
    
    [text enumerateSubstringsInRange:NSMakeRange(0, [text length]) options:NSStringEnumerationBySentences usingBlock:^(NSString *sentece, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        if (![sentece isEqual:@"\n"])
        {
            [self.sentencesToSpeakArray addObject:sentece];
        }

    }];
    return text;
}

- (void) doCopy // simulate cmd+c
{
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
