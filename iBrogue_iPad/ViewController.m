//
//  ViewController.m
//  iBrogue_iPad
//
//  Created by Seth Howard on 2/22/13.
//  Copyright (c) 2013 Seth howard. All rights reserved.
//

#import "ViewController.h"
#include <limits.h>
#include <unistd.h>
#import "RogueDriver.h"
#import "Viewport.h"
#import "GameCenterManager.h"
#import "UIViewController+UIViewController_GCLeaderBoardView.h"
#import "AboutViewController.h"

#define BROGUE_VERSION	4	// A special version number that's incremented only when
// something about the OS X high scores file structure changes.

Viewport *theMainDisplay;
ViewController *viewController;

typedef enum {
    KeyDownUp = 0,
    KeyDownRight,
    KeyDownDown,
    KeyDownLeft,
}KeyDown;

@interface ViewController () <UITextFieldDelegate>
- (IBAction)escButtonPressed:(id)sender;
- (IBAction)upButtonPressed:(id)sender;
- (IBAction)downButtonPressed:(id)sender;
- (IBAction)rightButtonPressed:(id)sender;
- (IBAction)leftButtonPressed:(id)sender;
- (IBAction)upLeftButtonPressed:(id)sender;
- (IBAction)upRightButtonPressed:(id)sender;
- (IBAction)downLeftButtonPressed:(id)sender;
- (IBAction)downRightButtonPressed:(id)sender;
- (IBAction)seedKeyPressed:(id)sender;
- (IBAction)showLeaderBoardButtonPressed:(id)sender;
- (IBAction)aboutButtonPressed:(id)sender;

@property (weak, nonatomic) IBOutlet UIView *buttonView;
@property (weak, nonatomic) IBOutlet UIButton *escButton;
@property (nonatomic, strong) NSMutableArray *cachedTouches; // collection of iBTouches
@property (weak, nonatomic) IBOutlet UIView *playerControlView;
@property (weak, nonatomic) IBOutlet UITextField *aTextField;
@property (nonatomic, strong) NSMutableArray *cachedKeyStrokes;
@end

@implementation ViewController {
    @private
    __unused NSTimer __strong *_autoSaveTimer;
}

- (void)autoSave {
    [RogueDriver autoSave];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [GameCenterManager sharedInstance];
    [[GameCenterManager sharedInstance] authenticateLocalUser];
	// Do any additional setup after loading the view, typically from a nib.
    
    if (!theMainDisplay) {
        theMainDisplay = self.theDisplay;
        viewController = self;
        _cachedTouches = [NSMutableArray arrayWithCapacity:1];
        _cachedKeyStrokes = [NSMutableArray arrayWithCapacity:1];
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(didShowKeyboard) name:UIKeyboardDidShowNotification object:nil];
        [center addObserver:self selector:@selector(didHideKeyboard) name:UIKeyboardWillHideNotification object:nil];
        
        [self.buttonView setAlpha:0];
        
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [UIView animateWithDuration:0.2 animations:^{
                self.buttonView.alpha = 1.;
            }];
        });
        
        //TODO: consider this... may not be the time for this yet
      //  _autoSaveTimer = [NSTimer scheduledTimerWithTimeInterval:20. target:self selector:@selector(autoSave) userInfo:nil repeats:YES];
    }
    
    [self playBrogue];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)awakeFromNib
{
    //	extern Viewport *theMainDisplay;
    //	CGSize theSize;
	short versionNumber;
    
	versionNumber = [[NSUserDefaults standardUserDefaults] integerForKey:@"Brogue version"];
	if (versionNumber == 0 || versionNumber < BROGUE_VERSION) {
		// This is so we know when to purge the relevant preferences and save them anew.
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"NSWindow Frame Brogue main window"];
        
		if (versionNumber != 0) {
			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"Brogue version"];
		}
		[[NSUserDefaults standardUserDefaults] setInteger:BROGUE_VERSION forKey:@"Brogue version"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

- (void)playBrogue
{
    rogueMain();
}

#pragma mark - touches

- (void)addTouchToCache:(UITouch *)touch {
    @synchronized(self.cachedTouches){
        iBTouch ibtouch;
        ibtouch.location = [touch locationInView:theMainDisplay];
        ibtouch.phase = touch.phase;
        [self.cachedTouches addObject:[NSValue value:&ibtouch withObjCType:@encode(iBTouch)]];
    }
}

- (iBTouch)getTouchAtIndex:(uint)index {
    NSValue *anObj = [self.cachedTouches objectAtIndex:index];
    iBTouch touch;
    [anObj getValue:&touch];
    
    return touch;
}

- (void)removeTouchAtIndex:(uint)index {
    @synchronized(self.cachedTouches){
        if ([self.cachedTouches count] > 0) {
            [self.cachedTouches removeObjectAtIndex:index];
        }
    }
}

- (uint)cachedTouchesCount {
    return [self.cachedTouches count];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  //  NSLog(@"%s", __PRETTY_FUNCTION__);
    [touches enumerateObjectsUsingBlock:^(UITouch *touch, BOOL *stop) {
        // Get a single touch and it's location
        [self addTouchToCache:touch];
    }];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
   // NSLog(@"%s", __PRETTY_FUNCTION__);
    [touches enumerateObjectsUsingBlock:^(UITouch *touch, BOOL *stop) {
        // Get a single touch and it's location
        [self addTouchToCache:touch];
    }];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  //  NSLog(@"%s", __PRETTY_FUNCTION__);
    [touches enumerateObjectsUsingBlock:^(UITouch *touch, BOOL *stop) {
        // Get a single touch and it's location
        [self addTouchToCache:touch];
    }];
}

#pragma mark - views

- (void)showTitlePageItems:(BOOL)show {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (show) {
            double delayInSeconds = 0.5;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                if (self.buttonView.hidden == YES) {
                    self.buttonView.hidden = NO;
                    self.buttonView.alpha = 0.;
                    [UIView animateWithDuration:0.2 animations:^{
                        self.buttonView.alpha = 1.;
                    }];
                }
            });
        }
        else {
            self.buttonView.hidden = YES;
            // get your finger off the ctrl key.. we don't need it anymore
            _seedKeyDown = NO;
        }
    });
}

- (void)hideControls {
    if (self.playerControlView.hidden == NO) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.playerControlView.hidden = YES;
        });
    }
}

- (void)showControls {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.playerControlView.hidden == YES) {
            double delayInSeconds = 0.5;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                self.playerControlView.hidden = NO;
                self.playerControlView.alpha = 0;
                [UIView animateWithDuration:0.2 animations:^{
                    self.playerControlView.alpha = 0.65;
                }];
            });
        }
    });
}

#pragma mark - keyboard stuff

- (void)showKeyboard {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.aTextField.text = @"Recording";
        [self.aTextField becomeFirstResponder];
    });
}

- (void)viewDidUnload {
    [self setPlayerControlView:nil];
    [self setATextField:nil];
    [self setEscButton:nil];
    [self setButtonView:nil];
    [super viewDidUnload];
}

- (uint)cachedKeyStrokeCount {
    return [self.cachedKeyStrokes count];
}

- (char)dequeKeyStroke {
    NSString *keyStroke = [self.cachedKeyStrokes objectAtIndex:0];
    @synchronized(self.cachedKeyStrokes){
        [self.cachedKeyStrokes removeObjectAtIndex:0];
    }
    
    return [keyStroke characterAtIndex:0];
}

#pragma mark - UITextFieldDelegate

- (void)didHideKeyboard {
    if ([self.cachedKeyStrokes count] == 0) {
        [self.cachedKeyStrokes addObject:@"\033"];
    }

    self.escButton.hidden = YES;
}

- (void)didShowKeyboard {
    self.escButton.hidden = NO;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self.cachedKeyStrokes addObject:@"\015"];
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    const char *_char = [string cStringUsingEncoding:NSUTF8StringEncoding];
    int isBackSpace = strcmp(_char, "\b");
    
    if (isBackSpace == -8) {
        // is backspace
        [self.cachedKeyStrokes addObject:@"\177"];
    }
    else if([string isEqualToString:@"\n"]) {
        [textField resignFirstResponder];
        // enter
        [self.cachedKeyStrokes addObject:@"\015"];
    }
    else {
        // misc
        [self.cachedKeyStrokes addObject:string];
    }
    
    return YES;
}

#pragma mark - Actions

- (IBAction)escButtonPressed:(id)sender {
    [self.cachedKeyStrokes addObject:@"\033"];
    [self.aTextField resignFirstResponder];
}

- (IBAction)upButtonPressed:(id)sender {
    [self.cachedKeyStrokes addObject:@"k"];
}

- (IBAction)downButtonPressed:(id)sender {
    [self.cachedKeyStrokes addObject:@"j"];
}

- (IBAction)rightButtonPressed:(id)sender {
    [self.cachedKeyStrokes addObject:@"l"];
}

- (IBAction)leftButtonPressed:(id)sender {
    [self.cachedKeyStrokes addObject:@"h"];
}

- (IBAction)upLeftButtonPressed:(id)sender {
    [self.cachedKeyStrokes addObject:@"y"];
}

- (IBAction)upRightButtonPressed:(id)sender {
    [self.cachedKeyStrokes addObject:@"u"];
}

- (IBAction)downLeftButtonPressed:(id)sender {
    [self.cachedKeyStrokes addObject:@"b"];
}

- (IBAction)downRightButtonPressed:(id)sender {
    [self.cachedKeyStrokes addObject:@"n"];
}

- (IBAction)seedKeyPressed:(id)sender {
    _seedKeyDown = !_seedKeyDown;
}

- (IBAction)showLeaderBoardButtonPressed:(id)sender {
    [self rgGCshowLeaderBoardWithCategory:kBrogueHighScoreLeaderBoard];
}

- (IBAction)aboutButtonPressed:(id)sender {
    self.modalPresentationStyle = UIModalPresentationFormSheet;
    AboutViewController *aboutVC = [[AboutViewController alloc] init];
    aboutVC.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:aboutVC animated:YES completion:nil];
}

@end
