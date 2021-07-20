
#import "MGLMatrixGLView.h"

#import "MGLConfigurationWindowController.h"

#import "MGLUserDefaults+Constants.h"

#import "MGLSettings.h"

#include "matrix.h"

@interface MGLMatrixGLView ()
{
	BOOL _preview;
	BOOL _mainScreen;
	
	BOOL _OpenGLIncompatibilityDetected;
	
	NSOpenGLView *_openGLView;
	
	sceneSettings * _sceneSettings;
	
	// Preferences
	
	MGLConfigurationWindowController *_configurationWindowController;
}

@end

@implementation MGLMatrixGLView

- (instancetype)initWithFrame:(NSRect)frameRect isPreview:(BOOL)isPreview
{
	self=[super initWithFrame:frameRect isPreview:isPreview];
	
	if (self!=nil)
	{
		_preview=isPreview;
		
		if (_preview==YES)
			_mainScreen=YES;
		else
			_mainScreen= (NSMinX(frameRect)==0 && NSMinY(frameRect)==0);
		
		[self setAnimationTimeInterval:1.0/60.0];
	}
	
	return self;
}

#pragma mark -

- (void)setFrameSize:(NSSize)newSize
{
	[super setFrameSize:newSize];
	
	if (_openGLView!=nil)
		[_openGLView setFrameSize:newSize];
}

#pragma mark -

- (void)keyDown:(NSEvent *) theEvent
{
    NSString * tString= theEvent.characters;
    
    NSUInteger stringLength=tString.length;
    
    for(NSUInteger i=0;i<stringLength;i++)
    {
        unichar tChar=[tString characterAtIndex:i];
        
        //RESET_TIMER(_sceneSettings);
        
        switch(tChar)
        {
            case 'n': /* n - Next picture. */
                if (_sceneSettings->classic) break;
                _sceneSettings->pic_offset+=rtext_x*text_y;
                _sceneSettings->pic_mode=1;
                _sceneSettings->timer=10;
                if(_sceneSettings->pic_offset>(rtext_x*text_y*(num_pics))) _sceneSettings->pic_offset=0;
                break;
                
            case 'c': /* Show "Credits" */
                _sceneSettings->classic=0;
                _sceneSettings->pic_offset=(num_pics+1)*(rtext_x*text_y);
                _sceneSettings->pic_mode=1;
                _sceneSettings->timer=70;
                break;
                
            case 'p':
                
                _sceneSettings->paused=!_sceneSettings->paused;
                
                break;
            case 's':
                
                if (!_sceneSettings->classic)
                {
                    _sceneSettings->pic_fade=0;
                    _sceneSettings->pic_offset=0;
                }
                
                _sceneSettings->pic_mode=!_sceneSettings->pic_mode;
                _sceneSettings->classic=!_sceneSettings->classic;
                
                break;
            case NSPageUpFunctionKey: // move the scene into the distance.
                Z_Off -= 0.3f;
                break;
                
            case NSPageDownFunctionKey: // move the scene closer.
                Z_Off += 0.3f;
                break;
            case 'e':
                _sceneSettings->exit_mode^=1;
                break;
            default:
                [super keyDown:theEvent];
                return;
        }
    }
}

#pragma mark -

- (void)drawRect:(NSRect) inFrame
{
	[[NSColor blackColor] set];
	
	NSRectFill(inFrame);
	
	if (_OpenGLIncompatibilityDetected==YES)
	{
		BOOL tShowErrorMessage=_mainScreen;
		
		if (tShowErrorMessage==NO)
		{
			NSString *tIdentifier = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
			ScreenSaverDefaults *tDefaults = [ScreenSaverDefaults defaultsForModuleWithName:tIdentifier];
			
			tShowErrorMessage=![tDefaults boolForKey:MGLUserDefaultsMainDisplayOnly];
		}
		
		if (tShowErrorMessage==YES)
		{
			NSRect tFrame=self.frame;
			
			NSMutableParagraphStyle * tMutableParagraphStyle=[[NSParagraphStyle defaultParagraphStyle] mutableCopy];
			tMutableParagraphStyle.alignment=NSCenterTextAlignment;
			
            NSDictionary * tAttributes = @{
                                           NSFontAttributeName:[NSFont systemFontOfSize:[NSFont systemFontSize]],
                                           NSForegroundColorAttributeName:[NSColor whiteColor],
                                           NSParagraphStyleAttributeName:tMutableParagraphStyle
                                           
                                           };
			
			
			NSString * tString=NSLocalizedStringFromTableInBundle(@"Minimum OpenGL requirements\rfor this Screen Effect\rnot available\ron your graphic card.",@"Localizable",[NSBundle bundleForClass:[self class]],@"No comment");
			
			NSRect tStringFrame;
			
			tStringFrame.origin=NSZeroPoint;
			tStringFrame.size=[tString sizeWithAttributes:tAttributes];
			
			tStringFrame=SSCenteredRectInRect(tStringFrame,tFrame);
			
			[tString drawInRect:tStringFrame withAttributes:tAttributes];
		}
	}
}

- (void)startAnimation
{
	_OpenGLIncompatibilityDetected=NO;
	
	[super startAnimation];
	
	NSString *tIdentifier = [[NSBundle bundleForClass:[self class]] bundleIdentifier];
	ScreenSaverDefaults *tDefaults = [ScreenSaverDefaults defaultsForModuleWithName:tIdentifier];
	
	BOOL tBool=[tDefaults boolForKey:MGLUserDefaultsMainDisplayOnly];
	
	if (tBool==YES && _mainScreen==NO)
		return;
	
	// Add OpenGLView
	
	NSOpenGLPixelFormatAttribute attribs[] =
	{
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize,(NSOpenGLPixelFormatAttribute)16,
		NSOpenGLPFAMinimumPolicy,
		(NSOpenGLPixelFormatAttribute)0
	};
	
	NSOpenGLPixelFormat *tFormat = [[NSOpenGLPixelFormat alloc] initWithAttributes:attribs];
	
	if (tFormat==nil)
	{
		_OpenGLIncompatibilityDetected=YES;
		return;
	}
	
	_openGLView = [[NSOpenGLView alloc] initWithFrame:self.bounds pixelFormat:tFormat];
	
	if (_openGLView!=nil)
	{
		[_openGLView setWantsBestResolutionOpenGLSurface:YES];
		
		[self addSubview:_openGLView];
	}
	else
	{
		_OpenGLIncompatibilityDetected=YES;
		return;
	}
	
	[_openGLView.openGLContext makeCurrentContext];
	
    glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [[_openGLView openGLContext] flushBuffer];
    
	NSRect tPixelBounds=[_openGLView convertRectToBacking:_openGLView.bounds];
	NSSize tSize=tPixelBounds.size;
	
	
    MGLSettings * tSettings=[[MGLSettings alloc] initWithDictionaryRepresentation:[tDefaults dictionaryRepresentation]];
    
    _sceneSettings=(sceneSettings *) malloc(sizeof(sceneSettings));
    
    _sceneSettings->color=(GLenum)tSettings.color;
    
    ourInit((int) tSize.width,(int) tSize.height,_sceneSettings);
    
    if (tSettings.showsCredits==YES)
    {
        _sceneSettings->classic=0;
        _sceneSettings->pic_offset=(num_pics+1)*(rtext_x*text_y);
        _sceneSettings->pic_mode=1;
        _sceneSettings->timer=70;
    }
    
    // Text Only
    
    if (tSettings.showsImages==NO)
    {
        _sceneSettings->pic_fade=0;
        _sceneSettings->pic_offset=0;
        
        _sceneSettings->pic_mode=0;
        _sceneSettings->classic=1;
    }
	
	const GLint tSwapInterval=1;
	CGLSetParameter(CGLGetCurrentContext(), kCGLCPSwapInterval,&tSwapInterval);
}

- (void)doScroll:(id) inObject
{
    if (!scrollScene(_sceneSettings->mode2,_sceneSettings))
    {
        SEL tSelector;
        
        tSelector=@selector(doScroll:);
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:tSelector object:nil];
        
        [self performSelector:tSelector withObject:nil afterDelay:0.060f];
    }
}

- (void)stopAnimation
{
	[super stopAnimation];
	
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
            
    if (_sceneSettings!=NULL)
    {
        free(_sceneSettings);
        _sceneSettings=NULL;
    }
}

- (void)animateOneFrame
{
	if (_openGLView!=nil)
	{
		[_openGLView.openGLContext makeCurrentContext];
		
        if (!cbRenderScene(_sceneSettings))
        {
            [self performSelector:@selector(doScroll:) withObject:nil afterDelay:0.060f];
        }
		
		[_openGLView.openGLContext flushBuffer];
	}
}

#pragma mark - Configuration

- (BOOL)hasConfigureSheet
{
	return YES;
}

- (NSWindow*)configureSheet
{
	if (_configurationWindowController==nil)
		_configurationWindowController=[MGLConfigurationWindowController new];
	
	NSWindow * tWindow=_configurationWindowController.window;
	
	[_configurationWindowController restoreUI];
	
	return tWindow;
}

@end
