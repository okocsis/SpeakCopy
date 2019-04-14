//
//  SpeechService.m
//  SpeakCopy
//
//  Created by Nick Bonatsakis on 12/2/11.
//  Copyright (c) 2011 Atlantia Software. All rights reserved.
//

#import "SpeechService.h"
#import <Carbon/Carbon.h>

#include <IOKit/hid/IOHIDKeys.h>

id aSelf;

OSStatus handleHotKeyPress(EventHandlerCallRef nextHandler, EventRef anEvent, void *userData);

#define kSpeakHotKeyId 123
#define kSpeakHotKeyId2 124
#define kSpeakHotKeyId3 125
#define kSpeakHotKeyId4 126
#define kSpeakHotKeyId5 127
#define kSpeakHotKeyId6 128

@interface SpeechService()<NSSpeechSynthesizerDelegate>

@property (nonatomic) BOOL isPaused;
@property (nonatomic) BOOL stoppedOnDemand;
@property (nonatomic) BOOL isLastWordInSentence;
@property (nonatomic, strong) NSSpeechSynthesizer* speech;
@property (atomic, strong) NSMutableArray<NSString *> *sentencesToSpeakArray;
@property (atomic, strong) NSMutableArray<NSNumber *> *paragraphIndexesArray;
@property (nonatomic) NSUInteger sentencesToSpeakArrayIndex;
@property (nonatomic) NSUInteger paragraphIndexesArrayIndex;
@property (nonatomic) NSRange lastWordRangeInSentence;


- (void) speakPastedText;
- (NSString*) fetchPastedText;
- (void) doCopy;

@end

@implementation SpeechService

#pragma mark - Life cycle
-(id)init {
    self = [super init];
    if (self) {
        aSelf = self;
        [self setup];
    }
    return self;
}

-(void)setup {
    _speech = [NSSpeechSynthesizer new];
    _speech.delegate = self;
    _isPaused = NO;
    _isLastWordInSentence = NO;
    _sentencesToSpeakArray = [NSMutableArray new];
    _paragraphIndexesArray = [NSMutableArray new];
    _sentencesToSpeakArrayIndex = 0;
    _paragraphIndexesArrayIndex = 0;
}

#pragma mark - private
-(void)incrSentencesToSpeakArrayIndex {

    if (self.sentencesToSpeakArrayIndex < self.sentencesToSpeakArray.count) {

        ++_sentencesToSpeakArrayIndex;
        NSNumber *indexNum = @(_sentencesToSpeakArrayIndex);

        if ([self.paragraphIndexesArray containsObject:indexNum]) {
            self.paragraphIndexesArrayIndex = [self.paragraphIndexesArray indexOfObject:indexNum];
        }
    }
}

-(void)decrSentencesToSpeakArrayIndex {

    if (self.sentencesToSpeakArrayIndex > 0) {

        --_sentencesToSpeakArrayIndex;
        NSNumber *indexNum = @(_sentencesToSpeakArrayIndex);

        if ([self.paragraphIndexesArray containsObject:indexNum]) {
            self.paragraphIndexesArrayIndex = [self.paragraphIndexesArray indexOfObject:indexNum];
        }
    }
}
-(void)incrParagraphsIndexesArrayIndex {

    if (self.paragraphIndexesArrayIndex < self.paragraphIndexesArray.count) {

        ++_paragraphIndexesArrayIndex;
        self.sentencesToSpeakArrayIndex = self.paragraphIndexesArray[_paragraphIndexesArrayIndex].unsignedIntegerValue;

    } else {
        self.sentencesToSpeakArrayIndex = self.sentencesToSpeakArray.count;
    }
}
-(void)decrParagraphsIndexesArrayIndex
{
    if (self.paragraphIndexesArrayIndex > 0)
    {
        --_paragraphIndexesArrayIndex;
        self.sentencesToSpeakArrayIndex = self.paragraphIndexesArray[_paragraphIndexesArrayIndex].unsignedIntegerValue;
    }
}

OSStatus handleHotKeyPress(EventHandlerCallRef nextHandler, EventRef theEvent, void *userData) {
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
            if ([[aSelf speech] isSpeaking])
            {
                [[aSelf speech] stopSpeaking];
                [aSelf setStoppedOnDemand:YES];
            }
            [aSelf speakAtSomeIndex];
            break;
        case kSpeakHotKeyId4:
            [aSelf incrSentencesToSpeakArrayIndex];
            if ([[aSelf speech] isSpeaking])
            {
                [[aSelf speech] stopSpeaking];
                [aSelf setStoppedOnDemand:YES];
            }
            [aSelf speakAtSomeIndex];
            break;
        case kSpeakHotKeyId5:
            [aSelf decrParagraphsIndexesArrayIndex];
            if ([[aSelf speech] isSpeaking])
            {
                [[aSelf speech] stopSpeaking];
                [aSelf setStoppedOnDemand:YES];
            }
            [aSelf speakAtSomeIndex];
            break;
        case kSpeakHotKeyId6:
            [aSelf incrParagraphsIndexesArrayIndex];
            if ([[aSelf speech] isSpeaking])
            {
                [[aSelf speech] stopSpeaking];
                [aSelf setStoppedOnDemand:YES];
            }
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
            self.paragraphIndexesArrayIndex = 0;
            self.isLastWordInSentence = NO;
            [self speakAtSomeIndex];

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
- (void)speechSynthesizer:(NSSpeechSynthesizer *)sender willSpeakWord:(NSRange)characterRange ofString:(NSString *)string
{
    if (self.lastWordRangeInSentence.location == characterRange.location)
    {
        self.isLastWordInSentence = YES;
    }
    else self.isLastWordInSentence = NO;
}
- (void) writeFirstThreeWordsToPasteBoard:(NSString *)words
{
    __block int i =0;
    __block NSUInteger rangeLenght = 0;
    NSString * threeWords = @"";
    
    [words enumerateSubstringsInRange:NSMakeRange(0,[words length])  options:NSStringEnumerationByWords usingBlock:^(NSString *word, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        if (i<5)
        {
            rangeLenght = substringRange.location + substringRange.length;
        }
        else *stop = YES;
        ++i;
    }];
    threeWords = [words substringWithRange:NSMakeRange(0, rangeLenght)];

    NSPasteboard* pasteboard = [NSPasteboard generalPasteboard];
    [pasteboard clearContents];
    BOOL success = [pasteboard writeObjects:[NSArray arrayWithObject:threeWords]];
    if (!success)
    {
        NSLog(@"pasboard write failed");
    }
}
-(void) speakAtSomeIndex
{
    if (self.sentencesToSpeakArrayIndex < [self.sentencesToSpeakArray count])
    {
        NSString *senteceToSpeak = self.sentencesToSpeakArray[self.sentencesToSpeakArrayIndex];
        [self writeFirstThreeWordsToPasteBoard:senteceToSpeak];
        [self lookForLastWordInSentence:senteceToSpeak];
        [self.speech startSpeakingString:senteceToSpeak];
    }
    

}
- (void) pausePastedText
{
    if ([self.speech isSpeaking] || !_isPaused)
    {
        [self.speech pauseSpeakingAtBoundary:NSSpeechWordBoundary];
        _isPaused = YES;
    }
    else if (_isPaused)
    {
        if (self.isLastWordInSentence)
        {
            [self speechSynthesizer:self.speech didFinishSpeaking:YES];
            self.isLastWordInSentence = NO;
        }
        else
        {
        [self.speech continueSpeaking];
        }
        _isPaused = NO;
    }
}
-(void) lookForLastWordInSentence:(NSString *) sentence
{
    [sentence enumerateSubstringsInRange:NSMakeRange(0,[sentence length]) options:NSStringEnumerationByWords usingBlock:^(NSString *word, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        self.lastWordRangeInSentence = substringRange;
    }];
}

-(NSArray *) splitParagraphToSentences:(NSString *) paragraph
{
    NSMutableArray *sentecesArray = [NSMutableArray new];
    [paragraph enumerateSubstringsInRange:NSMakeRange(0,[paragraph length]) options:NSStringEnumerationBySentences usingBlock:^(NSString *sentence, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        if ([sentence isNotEqualTo:@" "] )
        {
            [sentecesArray addObject:sentence];
        }
    }];
    return (NSArray *)sentecesArray;
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
    if ([self.sentencesToSpeakArray count] != 0)
    {
        [self.sentencesToSpeakArray removeAllObjects];
        [self.paragraphIndexesArray removeAllObjects];
    }
    [self.paragraphIndexesArray addObject:@0];
    [text enumerateSubstringsInRange:NSMakeRange(0, [text length]) options:NSStringEnumerationByParagraphs usingBlock:^(NSString *paragraph, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        if ([paragraph isNotEqualTo:@""])
        {
            NSArray *sentences = [self splitParagraphToSentences:paragraph];
            NSUInteger paragraphIndex = [[self.paragraphIndexesArray lastObject] unsignedIntegerValue] + [sentences count] ;
            [self.paragraphIndexesArray addObject:[NSNumber numberWithUnsignedInteger:paragraphIndex]  ];
            
            [self.sentencesToSpeakArray addObjectsFromArray:sentences];
        }
    }];
    [self.paragraphIndexesArray removeLastObject];
    
    
//    [self.sentencesToSpeakArray addObject:@"\n"];
    return text;
}

- (void) doCopy // simulate cmd+c
{
    CGEventSourceRef source = CGEventSourceCreate(kCGEventSourceStateCombinedSessionState);
    CGEventRef keyDown = CGEventCreateKeyboardEvent(source, (CGKeyCode)8, YES);
    CGEventSetFlags(keyDown, kCGEventFlagMaskCommand);
    CGEventRef keyUp = CGEventCreateKeyboardEvent(source, (CGKeyCode)8, NO);
    
    CGEventPost(kCGAnnotatedSessionEventTap, keyDown);
    // without this wait, the copy doesn't seem to register.
    [NSThread sleepForTimeInterval:0.25];
    CGEventPost(kCGAnnotatedSessionEventTap, keyUp);
    
    CFRelease(keyUp);
    CFRelease(keyDown);
    CFRelease(source);
}

#pragma mark - Public

- (void) startListening {
    EventHotKeyRef hotKeyRef = NULL;
    EventHotKeyID speakKeyId = {
        .signature = 'spk1',
        .id = kSpeakHotKeyId
    };
    EventTypeSpec eventType = {
        .eventClass = kEventClassKeyboard,
        .eventKind = kEventHotKeyPressed
    };
    InstallApplicationEventHandler(&handleHotKeyPress, 1, &eventType, (__bridge void *)self, NULL);

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

    EventHotKeyRef hotKeyRef5;
    EventHotKeyID speakKeyId5;
    speakKeyId5.signature ='spk5';
    speakKeyId5.id = kSpeakHotKeyId5;


    //ToDo - make the keystroke configurable in some UI.
    RegisterEventHotKey(38, cmdKey+optionKey+controlKey, speakKeyId5, GetApplicationEventTarget(), 0, &hotKeyRef5);
    //cmd+otpion+j for step one senctece back

    EventHotKeyRef hotKeyRef6;
    EventHotKeyID speakKeyId6;
    speakKeyId6.signature ='spk6';
    speakKeyId6.id = kSpeakHotKeyId6;


    //ToDo - make the keystroke configurable in some UI.
    RegisterEventHotKey(40, cmdKey+optionKey+controlKey, speakKeyId6, GetApplicationEventTarget(), 0, &hotKeyRef6);
    //cmd+otpion+k for for step one senctece forward

}

-(void)dealloc {
//    RemoveEventHandler(EventHandlerRef inHandlerRef)
}


@end
