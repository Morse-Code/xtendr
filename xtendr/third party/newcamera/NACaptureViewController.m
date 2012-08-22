//
//  NACaptureViewController.m
//
//  Created by Tony Million on 28/07/2012.
//  Copyright (c) 2012 Narrato. All rights reserved.
//

/*
	WARNING: This code is copyrighted, you are not allowed to use it outside of the xtendr project
	without express permission of me (Tony Million tonymillion@gmail.com).
 */

#import "NACaptureViewController.h"

#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreImage/CoreImage.h>
#import <ImageIO/ImageIO.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <MobileCoreServices/MobileCoreServices.h>


#import "NABluesImageEffect.h"
#import "NAClassicImageEffect.h"
#import "NAPixelateEffect.h"

#import "NAEffectsManager.h"



@interface NACaptureViewController () <AVCaptureVideoDataOutputSampleBufferDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate, UIGestureRecognizerDelegate>

@property(strong) UIImagePickerController		*libraryPickerController;

@property(strong) AVCaptureSession				*session;
@property(strong) AVCaptureDeviceInput			*input;
@property(strong) AVCaptureDevice				*videoDevice;

@property(strong) AVCaptureStillImageOutput		*stillImageOutput;

@property(strong) AVCaptureVideoDataOutput		*dataOutput;


@property(strong) CIContext						*liveImageContext;
@property(strong) CIContext						*capturedImageContext;



@property(strong) UIImageView					*liveImageView;
@property(strong) UIImageView					*capturedImageView;

@property(strong) UIImageView					*focusView;


@property(strong) UIView						*cameraControlsView;
@property(strong) UIImageView					*cameraControlsBackgroundView;
@property(strong) UIImageView					*barShadowView;
@property(strong) UIButton						*takePhotoButton;

@property(strong) UIButton						*cancelButton;
@property(strong) UIButton						*pickFromLibraryButton;
@property(strong) UIButton						*changeEffectButton;


@property(strong) UIView						*imageControlsView;
@property(strong) UIImageView					*imageControlsBackgroundView;
@property(strong) UIButton						*acceptImageButton;
@property(strong) UIButton						*rejectImageButton;
@property(strong) UIButton						*imageControlsChangeEffectButton;

@property(strong) UIButton						*changeCameraButton;

@property(assign) BOOL							effectsShowing;
@property(strong) UIScrollView					*effectsScrollView;
@property(strong) UIView						*effectButtonsHolderView;
@property(strong) NSMutableArray				*effectsViewArray;



@property(strong) UIImageView					*cameraOverlayImage;

@property(strong) NAImageEffect					*imageEffect;

@property(strong) UIImage						*capturedImage;
@property(strong) UIImage						*processedImage;

@property(assign) CGFloat						outputRotation;

@property(assign) CGFloat						scaleFactor;
@property(assign) CGFloat						beginGestureScale;

/// This determines the rotation applied to the output image, based on the source material
@property(readwrite, nonatomic) UIInterfaceOrientation outputImageOrientation;


-(void)switchToStaticImageModeWithImage:(UIImage*)image;

/** Get the position (front, rear) of the source camera
 */
- (AVCaptureDevicePosition)cameraPosition;

@end

@implementation NACaptureViewController
{
	BOOL capturePaused;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.wantsFullScreenLayout = YES;

		// create some CI contexts (we use one for live and one for non-live)
		self.liveImageContext		= [CIContext contextWithOptions:nil];
		self.capturedImageContext	= [CIContext contextWithOptions:nil];

		capturePaused = NO;

		self.scaleFactor = 1.0;
    }
    return self;
}

-(void)dealloc
{
	[self stopCameraCapture];

	[self.dataOutput setSampleBufferDelegate:nil
									   queue:nil];
}

-(void)loadView
{
    [self.navigationController setNavigationBarHidden:YES];

	////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////
	////////////////////////////////////////////////////////////////////////
	//
    // set up main view
	//

    self.view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
    self.view.backgroundColor = [UIColor blackColor];

	////////////////////////////////////////////////////////////////////////
	//
    // set up live preview view
	//
    self.liveImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, self.view.bounds.size.height - 53)];
    self.liveImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.liveImageView.contentMode = UIViewContentModeScaleAspectFit;

    [self.view addSubview:self.liveImageView];
    self.liveImageView.userInteractionEnabled = YES;

	// tap gesture for focussing!
	UITapGestureRecognizer *_recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(imageTapped:)];

    [self.liveImageView addGestureRecognizer:_recognizer];

	self.liveImageView.hidden = NO;

	UIPinchGestureRecognizer * pinch = [[UIPinchGestureRecognizer alloc] initWithTarget:self
                                                                                 action:@selector(handlePinchGesture:)];
    pinch.delegate = self;
    [self.liveImageView addGestureRecognizer:pinch];



	////////////////////////////////////////////////////////////////////////
	//
    // set up processed image view (we use two views to avoid sillyness
	//

	self.capturedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, self.view.bounds.size.height - 53)];
    self.capturedImageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    self.capturedImageView.contentMode = UIViewContentModeScaleAspectFit;

    [self.view addSubview:self.capturedImageView];
	self.capturedImageView.alpha	= 0;


	UILongPressGestureRecognizer * lpgr = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(handleLongPress:)];

    lpgr.minimumPressDuration = 0.001;
    lpgr.allowableMovement = 100;

    [self.capturedImageView addGestureRecognizer:lpgr];
    self.capturedImageView.userInteractionEnabled = YES;


	////////////////////////////////////////////////////////////////////////
	//
    // set shadow view at bottom of image (this 'raises controls' off the image)
	//

	self.barShadowView = [[UIImageView alloc] initWithFrame:CGRectMake(0,
                                                                       self.view.bounds.size.height - 58,
                                                                       320,
                                                                       5)];
    self.barShadowView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    self.barShadowView.image = [UIImage imageNamed:@"PLCameraButtonBarSilverShadow"];
    [self.view addSubview:self.barShadowView];



	////////////////////////////////////////////////////////////////////////
	//
	// set up camera controls!
	//

	self.cameraControlsView = [[UIView alloc] initWithFrame:CGRectMake(0,
																	   self.view.bounds.size.height - 53,
																	   320,
																	   53)];
	self.cameraControlsView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.view addSubview:self.cameraControlsView];



    self.cameraControlsBackgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0,
																					  0,
																					  320,
																					  53)];
    self.cameraControlsBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    self.cameraControlsBackgroundView.image = [UIImage imageNamed:@"PLCameraButtonBarSilver"];
    [self.cameraControlsView addSubview:self.cameraControlsBackgroundView];




    self.takePhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];

    self.takePhotoButton.frame = CGRectMake(160-50,
                                            6,
                                            100,
                                            41);
    self.takePhotoButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.cameraControlsView addSubview:self.takePhotoButton];

    UIImage * takePhotoBack = [[UIImage imageNamed:@"PLCameraButtonSilver"] stretchableImageWithLeftCapWidth:20 topCapHeight:41];
    UIImage * takePhotoBackPressed = [[UIImage imageNamed:@"PLCameraButtonSilverPressed"] stretchableImageWithLeftCapWidth:20 topCapHeight:41];

    [self.takePhotoButton setBackgroundImage:takePhotoBack
                                    forState:UIControlStateNormal];
    [self.takePhotoButton setBackgroundImage:takePhotoBackPressed
                                    forState:UIControlStateHighlighted];

    [self.takePhotoButton addTarget:self action:@selector(takePhoto:) forControlEvents:UIControlEventTouchUpInside];




    self.cameraOverlayImage = [[UIImageView alloc] initWithFrame:CGRectMake(160-13,
                                                                            53 - 37,
                                                                            26,
                                                                            21)];
    self.cameraOverlayImage.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    self.cameraOverlayImage.image = [UIImage imageNamed:@"PLCameraButtonIcon"];
    [self.cameraControlsView addSubview:self.cameraOverlayImage];



	self.cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];

    self.cancelButton.frame = CGRectMake(10,
										 6,
										 41,
										 41);
    self.cancelButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.cameraControlsView addSubview:self.cancelButton];

    [self.cancelButton addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
	[self.cancelButton setImage:[UIImage imageNamed:@"cancelcapture"] forState:UIControlStateNormal];
	self.cancelButton.showsTouchWhenHighlighted = YES;


    self.pickFromLibraryButton = [UIButton buttonWithType:UIButtonTypeCustom];

    self.pickFromLibraryButton.frame = CGRectMake(60,
                                                  6,
                                                  41,
                                                  41);
    self.pickFromLibraryButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.cameraControlsView addSubview:self.pickFromLibraryButton];

    [self.pickFromLibraryButton addTarget:self action:@selector(pickFromLibrary:) forControlEvents:UIControlEventTouchUpInside];
	[self.pickFromLibraryButton setImage:[UIImage imageNamed:@"library"] forState:UIControlStateNormal];
	self.pickFromLibraryButton.showsTouchWhenHighlighted = YES;






    self.changeEffectButton = [UIButton buttonWithType:UIButtonTypeCustom];

    self.changeEffectButton.frame = CGRectMake(320 - 41 - 20,
                                               6,
                                               41,
                                               41);
    self.changeEffectButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.cameraControlsView addSubview:self.changeEffectButton];

    [self.changeEffectButton addTarget:self action:@selector(changeEffect:) forControlEvents:UIControlEventTouchUpInside];
	[self.changeEffectButton setImage:[UIImage imageNamed:@"showeffect"] forState:UIControlStateNormal];

	self.changeEffectButton.showsTouchWhenHighlighted = YES;







	////////////////////////////////////////////////////////////////////////
	//
	// set up image controls!
	//
	self.imageControlsView = [[UIView alloc] initWithFrame:CGRectMake(0,
																	  self.view.bounds.size.height - 53,
																	  320,
																	  53)];
	self.imageControlsView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
	[self.view insertSubview:self.imageControlsView belowSubview:self.cameraControlsView];


    self.imageControlsBackgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0,
																					 0,
																					 320,
																					 53)];
    self.imageControlsBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    self.imageControlsBackgroundView.image = [UIImage imageNamed:@"PLCameraButtonBarSilver"];
    [self.imageControlsView addSubview:self.imageControlsBackgroundView];



    self.acceptImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.acceptImageButton.frame = CGRectMake(160 + 30,
											  6,
											  41,
											  41);
    self.acceptImageButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.imageControlsView addSubview:self.acceptImageButton];
    [self.acceptImageButton addTarget:self action:@selector(acceptImage:) forControlEvents:UIControlEventTouchUpInside];
	[self.acceptImageButton setImage:[UIImage imageNamed:@"acceptphoto"] forState:UIControlStateNormal];




    self.rejectImageButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.rejectImageButton.frame = CGRectMake(160 - 41 - 30,
											  6,
											  41,
											  41);
    self.rejectImageButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.imageControlsView addSubview:self.rejectImageButton];
    [self.rejectImageButton addTarget:self action:@selector(rejectImage:) forControlEvents:UIControlEventTouchUpInside];
	[self.rejectImageButton setImage:[UIImage imageNamed:@"rejectphoto"] forState:UIControlStateNormal];





    self.imageControlsChangeEffectButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.imageControlsChangeEffectButton.frame = CGRectMake(320 - 41 - 20,
															6,
															41,
															41);
    self.imageControlsChangeEffectButton.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    [self.imageControlsView addSubview:self.imageControlsChangeEffectButton];

    [self.imageControlsChangeEffectButton addTarget:self action:@selector(changeEffect:) forControlEvents:UIControlEventTouchUpInside];
	[self.imageControlsChangeEffectButton setImage:[UIImage imageNamed:@"showeffect"] forState:UIControlStateNormal];

	self.imageControlsChangeEffectButton.showsTouchWhenHighlighted = YES;





	self.changeCameraButton = [UIButton buttonWithType:UIButtonTypeCustom];

	self.changeCameraButton.frame = CGRectMake(310-60, 10, 60, 35);
	[self.changeCameraButton addTarget:self action:@selector(rotateCamera:) forControlEvents:UIControlEventTouchUpInside];

    UIImage * changeCameraBack = [[UIImage imageNamed:@"CameraButtonBack"] stretchableImageWithLeftCapWidth:19 topCapHeight:17];
    UIImage * changeCameraBackPressed = [[UIImage imageNamed:@"CameraButtonBackPressed"] stretchableImageWithLeftCapWidth:19 topCapHeight:17];

	[self.changeCameraButton setImage:[UIImage imageNamed:@"PLCameraToggleIcon"] forState:UIControlStateNormal];

    [self.changeCameraButton setBackgroundImage:changeCameraBack
									   forState:UIControlStateNormal];
    [self.changeCameraButton setBackgroundImage:changeCameraBackPressed
									   forState:UIControlStateHighlighted];

	[self.view addSubview:self.changeCameraButton];





	self.effectsScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0,
																			self.view.bounds.size.height,
																			320,
																			100)];
    self.effectsScrollView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;

	self.effectsScrollView.backgroundColor = [UIColor clearColor];

	[self.view insertSubview:self.effectsScrollView
				belowSubview:self.imageControlsView];


	NSUInteger count = [[NAEffectsManager sharedInstance] count];

	self.effectsViewArray = [NSMutableArray arrayWithCapacity:count];
	self.effectButtonsHolderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, count*100, 100)];

	for(int x=0; x<count; x++)
	{
		UIView * effect = [[UIView alloc] initWithFrame:CGRectMake(100*x, 0, 100, 100)];
		effect.clipsToBounds = YES;

		effect.backgroundColor = [UIColor clearColor];

		UIImageView * back = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
		back.image = [UIImage imageNamed:@"effectback"];
        [effect addSubview:back];


        UIButton * button = [UIButton buttonWithType:UIButtonTypeRoundedRect];

        button.frame = CGRectMake(10, 10, 80, 80);

        [button setImage:[[NAEffectsManager sharedInstance] thumbnnailForEffectAtIndex:x]
                forState:UIControlStateNormal];

		button.tag = x;
        [button addTarget:self
                   action:@selector(chooseEffect:)
         forControlEvents:UIControlEventTouchUpInside];

        [effect addSubview:button];


        UILabel * label = [[UILabel alloc] initWithFrame:CGRectMake(0, 80, 100, 17)];
        label.text = [[NAEffectsManager sharedInstance] nameForEffectAtIndex:x];
        label.backgroundColor = [UIColor clearColor];
        label.textAlignment = UITextAlignmentCenter;

        label.font          = [UIFont fontWithName:@"HelveticaNeue-CondensedBold"
                                              size:16];
        label.textColor     = [UIColor whiteColor];
        label.shadowColor   = [UIColor colorWithWhite:0.0f alpha:0.70f];
        label.shadowOffset  = CGSizeMake(0.0f, -1.0f);

        [effect addSubview:label];



		[self.effectButtonsHolderView addSubview:effect];
	}

    [self.effectsScrollView setContentSize:self.effectButtonsHolderView.frame.size];
    [self.effectsScrollView addSubview:self.effectButtonsHolderView];





	////////////////////////////////////////////////////////////////////////
	//
	// ADD AN OBSERVER for orientation changes!
	//

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];

	////////////////////////////////////////////////////////////////////////
	//
	// set up default processing effect!
	//

	NSString * effectID = [[NSUserDefaults standardUserDefaults] stringForKey:@"currentEffect"];

	self.imageEffect = [[NAEffectsManager sharedInstance] effectWithIdentifier:effectID];


	self.cameraControlsView.alpha = 1;
	self.imageControlsView.alpha = 0;


	self.focusView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"PLFocusCrosshairsSmall1"]];
	[self.view addSubview:self.focusView];
	self.focusView.alpha = 0;

}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    NSError * error;

	AVCaptureDevicePosition cameraPosition = AVCaptureDevicePositionBack;

	// Grab the back-facing or front-facing camera
    self.videoDevice = nil;
	NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices)
	{
		if ([device position] == cameraPosition)
		{
			self.videoDevice = device;
		}
	}



    self.session = [[AVCaptureSession alloc] init];


    [self.session beginConfiguration];


    [self.session setSessionPreset:AVCaptureSessionPresetPhoto];


    self.input          = [AVCaptureDeviceInput deviceInputWithDevice:self.videoDevice
                                                                error:&error];

    [self.session addInput:self.input];



    self.dataOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.dataOutput setAlwaysDiscardsLateVideoFrames:YES];
    [self.dataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]}];

	dispatch_queue_t queue = dispatch_queue_create("com.tm.captureQueue", DISPATCH_QUEUE_SERIAL);
    [self.dataOutput setSampleBufferDelegate:self
									   queue:queue];
	dispatch_release(queue);

    [self.session addOutput:self.dataOutput];

    for (AVCaptureConnection *connection in self.dataOutput.connections)
    {
		if(connection.isVideoMirroringSupported)
		{
			connection.videoMirrored = (cameraPosition == AVCaptureDevicePositionFront);
		}
    }





	self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    [self.stillImageOutput setOutputSettings:@{(id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA]}];
    [self.session addOutput:self.stillImageOutput];
    for (AVCaptureConnection *connection in self.stillImageOutput.connections)
    {
		if(connection.isVideoMirroringSupported)
		{
			connection.videoMirrored = (cameraPosition == AVCaptureDevicePositionFront);
		}
    }



    [self.session commitConfiguration];

	[self startCameraCapture];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

	if(![UIApplication sharedApplication].statusBarHidden)
        [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
	[self orientationChanged:nil];

}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];

    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(CIImage *)scaleImage:(CIImage*)srcImage toRect:(CGRect)maxRect
{
    CGRect srcRect = srcImage.extent;
    CGRect dstRect = AVMakeRectWithAspectRatioInsideRect(srcImage.extent.size, maxRect );

    CGFloat wRatio = (dstRect.size.width / srcRect.size.width);
    CGFloat hRatio = (dstRect.size.height / srcRect.size.height);

    CIImage * scaledImage = [srcImage imageByApplyingTransform:CGAffineTransformMakeScale(wRatio, hRatio)];

    CIVector *theCropVector = [CIVector vectorWithCGRect:CGRectMake(0, 0, (int)dstRect.size.width, (int)dstRect.size.height)];
    CIFilter * theFilter = [CIFilter filterWithName:@"CICrop" keysAndValues:@"inputImage", scaledImage, @"inputRectangle", theCropVector, NULL];
    return theFilter.outputImage;
}


- (void)startCameraCapture;
{
    if (![self.session isRunning])
	{
        //startingCaptureTime = [NSDate date];
		[self.session startRunning];
	};
}

- (void)stopCameraCapture;
{
    if ([self.session isRunning])
    {
        [self.session stopRunning];
    }
}

- (void)pauseCameraCapture;
{
    capturePaused = YES;
}

- (void)resumeCameraCapture;
{
    capturePaused = NO;
}

- (IBAction)rotateCamera:(id)sender
{
    NSError *error;
    AVCaptureDeviceInput *newVideoInput;
    AVCaptureDevicePosition currentCameraPosition = [[self.input device] position];

    if (currentCameraPosition == AVCaptureDevicePositionBack)
    {
        currentCameraPosition = AVCaptureDevicePositionFront;
    }
    else
    {
        currentCameraPosition = AVCaptureDevicePositionBack;
    }

    AVCaptureDevice *backFacingCamera = nil;
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
	for (AVCaptureDevice *device in devices)
	{
		if ([device position] == currentCameraPosition)
		{
			backFacingCamera = device;
		}
	}

    newVideoInput = [[AVCaptureDeviceInput alloc] initWithDevice:backFacingCamera error:&error];

    if (newVideoInput != nil)
    {
        [self.session beginConfiguration];

        [self.session removeInput:self.input];
        if ([self.session canAddInput:newVideoInput])
        {
            [self.session addInput:newVideoInput];
            self.input = newVideoInput;
        }
        else
        {
            [self.session addInput:self.input];
        }

		for (AVCaptureConnection *connection in self.dataOutput.connections)
		{
			if(connection.isVideoMirroringSupported)
			{
				connection.videoMirrored = (currentCameraPosition == AVCaptureDevicePositionFront);
			}
		}

		for (AVCaptureConnection *connection in self.stillImageOutput.connections)
		{
			if(connection.isVideoMirroringSupported)
			{
				connection.videoMirrored = (currentCameraPosition == AVCaptureDevicePositionFront);
			}
		}


        //captureSession.sessionPreset = oriPreset;
        [self.session commitConfiguration];
    }


    [self setOutputImageOrientation:_outputImageOrientation];
}



-(void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
      fromConnection:(AVCaptureConnection *)connection
{
	if(capturePaused)
		return;

    @autoreleasepool
	{
        //CIImage *ciimg = [CIImage imageWithCVPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)
        //                                         options:@{ kCIImageColorSpace : (id)kCFNull }];

		CIImage *ciimg  = [CIImage imageWithCVPixelBuffer:CMSampleBufferGetImageBuffer(sampleBuffer)];

		ciimg = [self scaleImage:ciimg toRect:CGRectMake(0, 0, 480, 480)];

        ciimg = [ciimg imageByApplyingTransform:CGAffineTransformMakeRotation(-M_PI_2)];
        CGPoint origin = [ciimg extent].origin;
        ciimg = [ciimg imageByApplyingTransform:CGAffineTransformMakeTranslation(-origin.x, -origin.y)];

		if(connection.supportsVideoMirroring)
		{
			if(connection.isVideoMirrored)
			{
				ciimg = [ciimg imageByApplyingTransform:CGAffineTransformMakeScale(-1, 1)];
			}
		}


        ciimg = [self.imageEffect processImage:ciimg];


        CGImageRef  imgRef =   [self.liveImageContext createCGImage:ciimg
                                                           fromRect:ciimg.extent];

        UIImage     *newimg = [UIImage imageWithCGImage:imgRef];
        CGImageRelease(imgRef);

        dispatch_async(dispatch_get_main_queue(), ^{
            self.liveImageView.image = newimg;
        });

        [self.imageEffect finishProcessing];
    }
}

-(void)imageTapped:(id)sender
{
    UITapGestureRecognizer * tapRecogniser = sender;

    CGPoint pt = [tapRecogniser locationInView:self.liveImageView];

    CGFloat convertedX = (pt.y/self.liveImageView.bounds.size.height);
    CGFloat convertedY = 1.0 - (pt.x/self.liveImageView.bounds.size.width);

    CGPoint convertedPoint = CGPointMake(convertedX, convertedY);

    AVCaptureDevice *device = self.videoDevice;
    if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus])
	{
        NSError *error;
        if ([device lockForConfiguration:&error]) {
            [device setFocusPointOfInterest:convertedPoint];
            [device setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
            [device unlockForConfiguration];
        }
        else
        {
            DLog(@"Focus error: %@", error);
        }

		self.focusView.center = pt;
		self.focusView.alpha = 1;

		[UIView animateWithDuration:0.5 delay:0.5 options:0 animations:^{
			self.focusView.alpha = 0;
		} completion:^(BOOL finished) {

		}];
    }


}


-(IBAction)pickFromLibrary:(id)sender
{
    // Set up the image picker controller and add it to the view
    self.libraryPickerController               = [[UIImagePickerController alloc] init];
    self.libraryPickerController.delegate      = self;
    self.libraryPickerController.sourceType    = UIImagePickerControllerSourceTypePhotoLibrary;
    self.libraryPickerController.mediaTypes    = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeImage, nil];
    self.libraryPickerController.allowsEditing = self.allowsEditing;

	[self.session stopRunning];

    [self presentViewController:self.libraryPickerController
					   animated:YES
					 completion:^{
					 }];
}

-(IBAction)takePhoto:(id)sender
{
	self.takePhotoButton.enabled = NO;


    AVCaptureConnection          *stillImageConnection;

    stillImageConnection = [self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    [stillImageConnection setVideoScaleAndCropFactor:self.scaleFactor];


    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in self.stillImageOutput.connections)
    {
        for (AVCaptureInputPort *port in [connection inputPorts])
        {
            if ([[port mediaType] isEqual:AVMediaTypeVideo]){

                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }

	//[self.session beginConfiguration];
    //[self.session setSessionPreset:AVCaptureSessionPresetPhoto];
	//[self.session commitConfiguration];

	[self pauseCameraCapture];

    [self.stillImageOutput captureStillImageAsynchronouslyFromConnection:videoConnection
                                                       completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {

														   CIImage *ciimg = [CIImage imageWithCVPixelBuffer:CMSampleBufferGetImageBuffer(imageDataSampleBuffer)];

														   CIImage * scaledImage = [self scaleImage:ciimg
																							 toRect:CGRectMake(0, 0, 1024, 1024)];
														   ciimg = nil;

                                                           @autoreleasepool {
                                                               ///////////////////////////////////////////////////////////////
                                                               ///////////////////////////////////////////////////////////////
                                                               ///////////////////////////////////////////////////////////////
                                                               //
                                                               //   Rotate it
                                                               //

                                                               CIImage * rotatedImg = [scaledImage imageByApplyingTransform:CGAffineTransformMakeRotation(_outputRotation)];
                                                               scaledImage = nil;

															   if(videoConnection.supportsVideoMirroring)
																   if(videoConnection.isVideoMirrored)
																   {
																	   rotatedImg = [rotatedImg imageByApplyingTransform:CGAffineTransformMakeScale(-1, 1)];
																   }

                                                               ///////////////////////////////////////////////////////////////
                                                               ///////////////////////////////////////////////////////////////
                                                               ///////////////////////////////////////////////////////////////
                                                               //
                                                               //   Rasterize it
                                                               //
                                                               CGImageRef  imgRef =   [self.capturedImageContext createCGImage:rotatedImg
																													  fromRect:rotatedImg.extent];

															   [self switchToStaticImageModeWithImage:[UIImage imageWithCGImage:imgRef]];
															   
															   CGImageRelease(imgRef);
                                                           }

														   [self resumeCameraCapture];

                                                       }];
}

#pragma mark - imagePicker delegate crap

#define kGPUImageRotateRight		(-M_PI_2)
#define kGPUImageRotateLeft			(M_PI_2)
#define kGPUImageRotate180			(M_PI)
#define kGPUImageNoRotation			(0.0)


- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	
//	UIImage * originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
	UIImage * originalImage;

	if(self.allowsEditing)
		originalImage = [info objectForKey:UIImagePickerControllerEditedImage];
	else
		originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];

	DLog(@"Rect = %@, orientation= %d", NSStringFromCGSize(originalImage.size), originalImage.imageOrientation);

	CIImage * ciimg = [CIImage imageWithCGImage:originalImage.CGImage];

	CIImage * scaledImage = [self scaleImage:ciimg
									  toRect:CGRectMake(0, 0, 1024, 1024)];

	ciimg = nil;

	//TODO: rotate the image here

	CGFloat transform;

	switch (originalImage.imageOrientation) {
		case UIImageOrientationUp:
			DLog(@"UIImageOrientationUp");
			transform = kGPUImageNoRotation;
			break;
		case UIImageOrientationDown:
			DLog(@"UIImageOrientationDown");
			transform = kGPUImageRotate180;
			break;
		case UIImageOrientationLeft:
			DLog(@"UIImageOrientationLeft");
			transform = kGPUImageRotateLeft;
			break;
		case UIImageOrientationRight:
			DLog(@"UIImageOrientationRight");
			transform = kGPUImageRotateRight;
			break;

		default:
			break;
	}

	CIImage * rotatedImg = [scaledImage imageByApplyingTransform:CGAffineTransformMakeRotation(transform)];
	scaledImage = nil;


	CGImageRef  imgRef =   [self.capturedImageContext createCGImage:rotatedImg
														   fromRect:rotatedImg.extent];

	rotatedImg = nil;

	

	UIImage * newImage = [UIImage imageWithCGImage:imgRef];

	CGImageRelease(imgRef);
	

	DLog(@"Rect = %@, orientation= %d", NSStringFromCGSize(newImage.size), newImage.imageOrientation);


    [self.libraryPickerController dismissViewControllerAnimated:YES
                                                     completion:^{
														 [self switchToStaticImageModeWithImage:newImage];

                                                     }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
	[self.libraryPickerController dismissViewControllerAnimated:YES
													 completion:^{
														 [self startCameraCapture];
													 }];
}

#pragma mark - mode switching

-(void)switchToLiveCaptureMode
{
	self.capturedImage = nil;
	self.processedImage = nil;

	self.changeCameraButton.hidden = NO;
	self.takePhotoButton.enabled = YES;

	[UIView animateWithDuration:0.25
					 animations:^{
						 self.cameraControlsView.alpha	= 1;
						 self.imageControlsView.alpha	= 0;

						 self.liveImageView.alpha		= 1;
						 self.capturedImageView.alpha	= 0;
					 }
					 completion:^(BOOL finished){
						 self.capturedImageView.image	= nil;
					 }];

	[self startCameraCapture];
}

-(UIImage*)processImage:(UIImage*)inputImage
{
	CIImage * ciInputImage = [CIImage imageWithCGImage:inputImage.CGImage];

	ciInputImage = [self.imageEffect processImage:ciInputImage];

	CGImageRef  imgRef =   [self.capturedImageContext createCGImage:ciInputImage
														   fromRect:ciInputImage.extent];

	[self.imageEffect finishProcessing];

	UIImage * temp = [UIImage imageWithCGImage:imgRef scale:1.0 orientation:inputImage.imageOrientation];
	CGImageRelease(imgRef);

	return temp;
}

-(void)switchToStaticImageModeWithImage:(UIImage*)image
{
	[self stopCameraCapture];

	self.changeCameraButton.hidden = YES;


	self.capturedImage = image;

	self.processedImage = [self processImage:self.capturedImage];
	dispatch_async(dispatch_get_main_queue(), ^{
		self.capturedImageView.image = self.processedImage;
	});

	[UIView animateWithDuration:0.25
					 animations:^{
						 self.cameraControlsView.alpha	= 0;
						 self.imageControlsView.alpha	= 1;

						 self.liveImageView.alpha		= 0;
						 self.capturedImageView.alpha	= 1;
					 }];

	[self orientationChanged:nil];
}

-(IBAction)rejectImage:(id)sender
{
	[self switchToLiveCaptureMode];
}


-(IBAction)chooseEffect:(id)sender
{
	UIButton * btn = sender;

	if([self.imageEffect.identifier isEqual:[[NAEffectsManager sharedInstance] identifierForEffectAtIndex:btn.tag]] )
	{
		return;
	}

	self.imageEffect = [[NAEffectsManager sharedInstance] effectAtIndex:btn.tag];

	[[NSUserDefaults standardUserDefaults] setObject:self.imageEffect.identifier forKey:@"currentEffect"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	if(self.capturedImage)
	{
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
			self.processedImage = [self processImage:self.capturedImage];
			dispatch_async(dispatch_get_main_queue(), ^{
				self.capturedImageView.image = self.processedImage;
			});
		});
	}

}

-(IBAction)changeEffect:(id)sender
{
	[UIView animateWithDuration:0.2
						  delay:0
						options:UIViewAnimationOptionCurveEaseInOut
					 animations:^{
						 if(!self.effectsShowing)
						 {
							 self.effectsScrollView.frame = CGRectMake(0,
																	   self.view.bounds.size.height - 53 - 100,
																	   320,
																	   100);
						 }
						 else
						 {
							 self.effectsScrollView.frame = CGRectMake(0,
																	   self.view.bounds.size.height,
																	   320,
																	   100);
						 }

						 self.effectsShowing = !self.effectsShowing;

					 }
					 completion:^(BOOL finished) {
					 }];



}



-(void)setImageAnimated:(UIImage *)image
{
    CATransition *animation = [CATransition animation];
    animation.duration = 0.188;
    animation.type = kCATransitionFade;
    [[self.capturedImageView layer] addAnimation:animation forKey:@"imageFade"];
    [self.capturedImageView setImage:image];
}

-(void)handleLongPress:(UILongPressGestureRecognizer *)recognizer
{
    switch (recognizer.state) {
        case UIGestureRecognizerStateBegan:
            [self setImageAnimated:self.capturedImage];
            break;

        case UIGestureRecognizerStateChanged:
            break;

        case UIGestureRecognizerStateEnded:
            [self setImageAnimated:self.processedImage];
            break;
        default:
            break;
    }
}

-(IBAction)cancel:(id)sender
{
	if(self.capturedelegate && [self.capturedelegate respondsToSelector:@selector(captureViewControllerDidCancel:)])
	{
		[self.session stopRunning];

		self.wantsFullScreenLayout = NO;

		if([UIApplication sharedApplication].statusBarHidden)
			[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];

		[self.capturedelegate captureViewControllerDidCancel:self];

	}
}

-(IBAction)acceptImage:(id)sender
{
	if(self.capturedelegate && [self.capturedelegate respondsToSelector:@selector(captureViewController:didCaptureImage:)])
	{
		[self.session stopRunning];

		self.wantsFullScreenLayout = NO;

		if([UIApplication sharedApplication].statusBarHidden)
			[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];


		[self.capturedelegate captureViewController:self
									didCaptureImage:self.processedImage];

	}
}

- (AVCaptureDevicePosition)cameraPosition
{
    return [[self.input device] position];
}


#pragma mark - orientation changes

-(void)orientationChanged:(NSNotification*)note
{
    [UIView animateWithDuration:0.2 animations:^{
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];

		BOOL validOrientation = FALSE;

        CGAffineTransform t;

		CGFloat angle = 0;
		if ( orientation == UIDeviceOrientationLandscapeLeft )
		{
			angle = M_PI_2;
			validOrientation = YES;
		}
		else if ( orientation == UIDeviceOrientationLandscapeRight )
		{
			angle = -M_PI_2;
			validOrientation = YES;
		}
		else if ( orientation == UIDeviceOrientationPortraitUpsideDown )
		{
			angle = M_PI;
			validOrientation = YES;
		}
		else if ( orientation == UIDeviceOrientationPortrait )
		{
			angle = 0;
			validOrientation = YES;
		}

		if(	validOrientation )
		{
			[self setOutputImageOrientation:orientation];



			if (orientation == UIDeviceOrientationPortrait) {
				self.cameraOverlayImage.image = [UIImage imageNamed:@"PLCameraButtonIcon"];
			}
			else if (orientation == UIDeviceOrientationLandscapeRight) {
				self.cameraOverlayImage.image = [UIImage imageNamed:@"PLCameraButtonIconLandscape"];
			}
			else if (orientation == UIDeviceOrientationLandscapeLeft) {
				self.cameraOverlayImage.image = [UIImage imageNamed:@"PLCameraButtonIconLandscape"];
			}
			else if (orientation == UIDeviceOrientationPortraitUpsideDown) {
				self.cameraOverlayImage.image = [UIImage imageNamed:@"PLCameraButtonIcon"];
			}

			t = CGAffineTransformMakeRotation(angle);
			self.cameraOverlayImage.transform		= t;

			self.changeEffectButton.transform		= t;
			self.pickFromLibraryButton.transform	= t;
			self.cancelButton.transform				= t;

			self.acceptImageButton.transform		= t;
			self.rejectImageButton.transform		= t;

			self.changeCameraButton.transform = CGAffineTransformIdentity;
			if((orientation == UIDeviceOrientationLandscapeLeft) || (orientation == UIDeviceOrientationLandscapeRight))
			{
				self.changeCameraButton.frame = CGRectMake(310-50, 25, 60, 35);
			}
			else
			{
				self.changeCameraButton.frame = CGRectMake(310-60, 10, 60, 35);
			}
			self.changeCameraButton.transform		= t;



			if(UIDeviceOrientationIsPortrait(orientation))
			{
				self.capturedImageView.transform		= t;
			}
			else if(UIDeviceOrientationIsLandscape(orientation))
			{
				CGFloat scale;

				scale = self.capturedImage.size.width / self.capturedImage.size.height;

				self.capturedImageView.transform		= CGAffineTransformScale(t, scale, scale);
			}

			for (UIView * subView in self.effectButtonsHolderView.subviews) {
				subView.transform = t;
			}
		}
    }];
}


- (void)setOutputImageOrientation:(UIInterfaceOrientation)newValue;
{
    _outputImageOrientation = newValue;

	//    From the iOS 5.0 release notes:
	//    In previous iOS versions, the front-facing camera would always deliver buffers in AVCaptureVideoOrientationLandscapeLeft and the back-facing camera would always deliver buffers in AVCaptureVideoOrientationLandscapeRight.

    if ([self cameraPosition] == AVCaptureDevicePositionBack)
    {
        switch(_outputImageOrientation)
        {
            case UIInterfaceOrientationPortrait:_outputRotation				= kGPUImageRotateRight; break;
            case UIInterfaceOrientationPortraitUpsideDown:_outputRotation	= kGPUImageRotateLeft; break;
            case UIInterfaceOrientationLandscapeLeft:_outputRotation		= kGPUImageRotate180; break;
            case UIInterfaceOrientationLandscapeRight:_outputRotation		= kGPUImageNoRotation; break;
        }
    }
    else
    {
        switch(_outputImageOrientation)
        {
            case UIInterfaceOrientationPortrait:_outputRotation				= kGPUImageRotateRight; break;
            case UIInterfaceOrientationPortraitUpsideDown:_outputRotation	= kGPUImageRotateLeft; break;
            case UIInterfaceOrientationLandscapeLeft:_outputRotation		= kGPUImageNoRotation; break;
            case UIInterfaceOrientationLandscapeRight:_outputRotation		= kGPUImageRotate180; break;
        }
    }
}


#pragma mark - Gesture callback

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
	if ( [gestureRecognizer isKindOfClass:[UIPinchGestureRecognizer class]] )
    {
		self.beginGestureScale = self.scaleFactor;
	}
	return YES;
}

// scale image depending on users pinch gesture
- (IBAction)handlePinchGesture:(UIPinchGestureRecognizer *)recognizer
{
	BOOL allTouchesAreOnThePreviewLayer = YES;
	NSUInteger numTouches = [recognizer numberOfTouches], i;
	for ( i = 0; i < numTouches; ++i )
    {
//		CGPoint location = [recognizer locationOfTouch:i inView:self.previewView];
//		CGPoint convertedLocation = [self.previewLayer convertPoint:location fromLayer:self.previewLayer.superlayer];
//		if ( ! [self.previewLayer containsPoint:convertedLocation] )
//        {
//			allTouchesAreOnThePreviewLayer = NO;
//			break;
//		}
	}

	if ( allTouchesAreOnThePreviewLayer )
    {
		self.scaleFactor = self.beginGestureScale * recognizer.scale;
		if (self.scaleFactor < 1.0)
			self.scaleFactor = 1.0;

		CGFloat maxScaleAndCropFactor = [[self.stillImageOutput connectionWithMediaType:AVMediaTypeVideo] videoMaxScaleAndCropFactor];
		if (self.scaleFactor > maxScaleAndCropFactor)
			self.scaleFactor = maxScaleAndCropFactor;

		[CATransaction begin];
		[CATransaction setAnimationDuration:.025];
		self.liveImageView.transform = CGAffineTransformMakeScale(self.scaleFactor, self.scaleFactor);
		[CATransaction commit];
	}

	DLog(@"scale = %f", self.scaleFactor);
}


-(IBAction)flashOn:(id)sender
{
    if(self.videoDevice.flashAvailable)
    {
        NSError * err;
        if([self.videoDevice lockForConfiguration:&err])
        {
            self.videoDevice.flashMode = AVCaptureFlashModeOn;
			[self.videoDevice unlockForConfiguration];
        }
    }
}

-(IBAction)flashOff:(id)sender
{
    if(self.videoDevice.flashAvailable)
    {
        NSError * err;
        if([self.videoDevice lockForConfiguration:&err])
        {
            self.videoDevice.flashMode = AVCaptureFlashModeOff;
			[self.videoDevice unlockForConfiguration];
        }
    }
}

-(IBAction)flashAuto:(id)sender
{
    if(self.videoDevice.flashAvailable)
    {
        NSError * err;
        if([self.videoDevice lockForConfiguration:&err])
        {
            self.videoDevice.flashMode = AVCaptureFlashModeAuto;
			[self.videoDevice unlockForConfiguration];
        }
    }
}


@end
