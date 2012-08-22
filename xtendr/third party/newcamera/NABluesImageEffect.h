//
//  NAImageEffect.h
//  photovidcap
//
//  Created by Tony Million on 29/07/2012.
//  Copyright (c) 2012 Narrato. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>

#import "NAImageEffect.h"

@interface NABluesImageEffect : NAImageEffect

-(CIImage*)processImage:(CIImage*)inputImage;
-(void)finishProcessing;

@end
