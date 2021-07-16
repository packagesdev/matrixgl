/*
 Copyright (c) 2015-2021, Stephane Sudre
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 - Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 - Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 - Neither the name of the WhiteBox nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "MGLConfigurationWindowController.h"

#import <ScreenSaver/ScreenSaver.h>

#import "MGLAboutBoxWindowController.h"

#import "MGLUserDefaults+Constants.h"

#import "MGLSettings.h"

#import "MGLWindow.h"

@interface MGLConfigurationWindowController () <MGLWindowDelegate>
{
    IBOutlet NSButton * _showImagesCheckBox;
    
    IBOutlet NSButton * _showCreditsCheckBox_;
    
    IBOutlet NSPopUpButton * _colorPopUpButton;
    
    
	IBOutlet NSButton * _mainScreenCheckBox;
	
	IBOutlet NSButton * _cancelButton;
	
	NSRect _savedCancelButtonFrame;
	
	MGLSettings * _sceneSettings;
	
	BOOL _mainScreenSetting;
    
    MGLAboutBoxWindowController * _aboutBoxWindowController;
}

- (IBAction)switchShowImages:(id)sender;

- (IBAction)switchShowCredits:(id)sender;

- (IBAction)switchColor:(id)sender;


- (IBAction)showAboutBox:(id)sender;

- (IBAction)resetDialogSettings:(id)sender;

- (IBAction)closeDialog:(id)sender;

@end

@implementation MGLConfigurationWindowController

- (instancetype)init
{
	self=[super init];
	
	if (self!=nil)
	{
		NSString *tIdentifier = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
		ScreenSaverDefaults *tDefaults = [ScreenSaverDefaults defaultsForModuleWithName:tIdentifier];
		
		_sceneSettings=[[MGLSettings alloc] initWithDictionaryRepresentation:[tDefaults dictionaryRepresentation]];
		
		_mainScreenSetting=[tDefaults boolForKey:MGLUserDefaultsMainDisplayOnly];
	}
	
	return self;
}


- (NSString *)windowNibName
{
	return NSStringFromClass([self class]);
}

- (void)windowDidLoad
{
	[super windowDidLoad];
	
	_savedCancelButtonFrame=_cancelButton.frame;
}

#pragma mark -

- (void)restoreUI
{
    BOOL tShowsImages=_sceneSettings.showsImages;
    
    _showImagesCheckBox.state=(tShowsImages==YES) ? NSOnState : NSOffState;
    
    _showCreditsCheckBox_.enabled=tShowsImages;
    
    _showCreditsCheckBox_.state=(tShowsImages==YES) ? ((_sceneSettings.showsCredits==YES) ? NSOnState : NSOffState) : NSOffState;
    
    [_colorPopUpButton selectItemWithTag:_sceneSettings.color];
    
    
	[_mainScreenCheckBox setState:(_mainScreenSetting==YES) ? NSOnState : NSOffState];
}

#pragma mark -

- (IBAction)showAboutBox:(id)sender
{
	if (_aboutBoxWindowController==nil)
		_aboutBoxWindowController=[MGLAboutBoxWindowController new];
	
	if (_aboutBoxWindowController.window.isVisible==NO)
		[_aboutBoxWindowController.window center];
	
	[_aboutBoxWindowController.window makeKeyAndOrderFront:nil];
}

- (IBAction)resetDialogSettings:(id)sender
{
	[_sceneSettings resetSettings];
	
	[self restoreUI];
}

- (IBAction)closeDialog:(id)sender
{
	NSString *tIdentifier = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
	ScreenSaverDefaults *tDefaults = [ScreenSaverDefaults defaultsForModuleWithName:tIdentifier];
	
	if ([sender tag]==NSModalResponseOK)
	{
		// Scene Settings
		
		NSDictionary * tDictionary=[_sceneSettings dictionaryRepresentation];
		
		[tDictionary enumerateKeysAndObjectsUsingBlock:^(NSString *bKey,id bObject, BOOL * bOutStop){
			[tDefaults setObject:bObject forKey:bKey];
		}];
		
		// Main Screen Only
		
		_mainScreenSetting=(_mainScreenCheckBox.state==NSOnState);
		
		[tDefaults setBool:_mainScreenSetting forKey:MGLUserDefaultsMainDisplayOnly];
		
		[tDefaults synchronize];
	}
	else
	{
		_sceneSettings=[[MGLSettings alloc] initWithDictionaryRepresentation:[tDefaults dictionaryRepresentation]];
		
		_mainScreenSetting=[tDefaults boolForKey:MGLUserDefaultsMainDisplayOnly];
	}
	
	[NSApp endSheet:self.window];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (_aboutBoxWindowController.window.isVisible==YES)
            [_aboutBoxWindowController.window orderOut:self];
        
    });
}

#pragma mark -

- (IBAction)switchShowImages:(NSButton *)sender
{
    _sceneSettings.showsImages=(sender.state==NSOnState);
    
    if (sender.state==NSOffState)
    {
        _showCreditsCheckBox_.state=NSOffState;
        _showCreditsCheckBox_.enabled=NO;
    }
    else
    {
        _showCreditsCheckBox_.enabled=YES;
        _showCreditsCheckBox_.state=(_sceneSettings.showsCredits==YES) ? NSOnState : NSOffState;
    }
}

- (IBAction)switchShowCredits:(NSButton *)sender
{
    _sceneSettings.showsCredits=(sender.state==NSOnState);
}

- (IBAction)switchColor:(NSPopUpButton *)sender
{
    _sceneSettings.color=sender.selectedTag;
}

#pragma mark -

- (void)window:(NSWindow *)inWindow modifierFlagsDidChange:(NSEventModifierFlags) inModifierFlags
{
	if ((inModifierFlags & NSAlternateKeyMask) == NSAlternateKeyMask)
	{
		NSRect tOriginalFrame=_cancelButton.frame;
		
		_cancelButton.title=NSLocalizedStringFromTableInBundle(@"Reset",@"Localizable",[NSBundle bundleForClass:[self class]],@"");
		_cancelButton.action=@selector(resetDialogSettings:);
		
		[_cancelButton sizeToFit];
		
		NSRect tFrame=_cancelButton.frame;
		
		tFrame.size.width+=10.0;	// To compensate for sizeToFit stupidity
		
		if (NSWidth(tFrame)<84.0)
			tFrame.size.width=84.0;
		
		tFrame.origin.x=NSMaxX(tOriginalFrame)-NSWidth(tFrame);
		
		_cancelButton.frame=tFrame;
	}
	else
	{
		_cancelButton.title=NSLocalizedStringFromTableInBundle(@"Cancel",@"Localizable",[NSBundle bundleForClass:[self class]],@"");
		_cancelButton.action=@selector(closeDialog:);
		
		_cancelButton.frame=_savedCancelButtonFrame;
	}
}


@end
