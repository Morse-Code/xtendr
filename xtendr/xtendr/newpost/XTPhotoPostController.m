//
//  ZZPhotoPostController.m
//  //
//
//  Created by Tony Million on 16/06/2012.
//  Copyright (c) 2012 OmniTyke. All rights reserved.
//

#import "XTPhotoPostController.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

#import "XTNewPostViewController.h"

#import "NACaptureViewController.h"

@interface XTPhotoPostController () <NACaptureDelegate>

@property(weak) UIViewController			*parentVC;
@property(strong) NSString					*topicID;

@property(strong) UINavigationController	*navController;

@end

@implementation XTPhotoPostController

@synthesize parentVC;


-(void)presentWithParent:(UIViewController*)parent
{
    self.parentVC   = parent;

	NACaptureViewController * cvc = [[NACaptureViewController alloc] init];

	cvc.capturedelegate = self;

	cvc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;

	self.navController = [[UINavigationController alloc] initWithRootViewController:cvc];

	[parent presentViewController:self.navController
						 animated:YES
					   completion:^{
					   }];
}

-(void)captureViewControllerDidCancel:(NACaptureViewController *)captureView
{
    [self.parentVC dismissViewControllerAnimated:YES
									  completion:^{
										  self.navController = nil;
									  }];
}

-(void)captureViewController:(NACaptureViewController *)captureView didCaptureImage:(UIImage *)image
{
	//NOW that we have the video thumbnail
	// make the attachment dictionaries and push the final step controller on the stack!

	XTNewPostViewController * npvc = [[XTNewPostViewController alloc] init];

	npvc.imageAttachment = image;

	[self.navController pushViewController:npvc
								  animated:YES];

}


@end
