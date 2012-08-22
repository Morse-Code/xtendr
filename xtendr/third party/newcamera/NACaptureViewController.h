//
//  NACaptureViewController.h
//  photovidcap
//
//  Created by Tony Million on 28/07/2012.
//  Copyright (c) 2012 Narrato. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NACaptureDelegate;


@interface NACaptureViewController : UIViewController

@property(weak) id<NACaptureDelegate> capturedelegate;
@property(assign) BOOL	allowsEditing;

@end




@protocol NACaptureDelegate <NSObject>

-(void)captureViewControllerDidCancel:(NACaptureViewController*)captureView;
-(void)captureViewController:(NACaptureViewController*)captureView didCaptureImage:(UIImage*)image;

@end
