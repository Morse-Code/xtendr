//
//  NAPixelateEffect.m
//  photovidcap
//
//  Created by Tony Million on 31/07/2012.
//  Copyright (c) 2012 Narrato. All rights reserved.
//

#import "NAPixelateEffect.h"

@interface NAPixelateEffect ()

@property(strong) NSMutableArray    *effectsArray;
@property(strong) CIContext         *context;

@end


@implementation NAPixelateEffect

-(id)init
{
    self = [super init];
    if(self)
    {
        self.effectsArray = [NSMutableArray arrayWithCapacity:3];
        
        self.context = [CIContext contextWithOptions:nil];
    }
    
    return self;
}

-(CIImage*)processImage:(CIImage*)inputImage
{
    @autoreleasepool
    {
        CIImage * scaledDown    = [inputImage imageByApplyingTransform:CGAffineTransformMakeScale(0.125, 0.125)];
        NSLog(@"down: %@", NSStringFromCGRect(scaledDown.extent));
 
        CIFilter * cropFilter = [CIFilter filterWithName:@"CICrop"];
        [cropFilter setDefaults];
        [cropFilter setValue:scaledDown forKey:@"inputImage"];
        [cropFilter setValue:[CIVector vectorWithCGRect:scaledDown.extent] forKey:@"inputRectangle"];
        
        CIImage * scaledUp      = [cropFilter.outputImage imageByApplyingTransform:CGAffineTransformMakeScale(8, 8)];
        scaledDown = nil;
        NSLog(@"up: %@", NSStringFromCGRect(scaledUp.extent));
        
        
        return scaledUp;
    }
}

-(void)finishProcessing
{
    for (CIFilter * filter in self.effectsArray) {
        [filter setValue:nil
                  forKey:kCIInputImageKey];
    }
}

@end
