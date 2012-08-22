//
//  NAImageEffect.m
//  photovidcap
//
//  Created by Tony Million on 29/07/2012.
//  Copyright (c) 2012 Narrato. All rights reserved.
//

#import "NABluesImageEffect.h"

@interface NABluesImageEffect ()

@property(strong) NSMutableArray    *effectsArray;

@end

@implementation NABluesImageEffect

+(NSString*)name
{
	return @"The Blues";
}

+(NSString*)identifier
{
	return @"com.fx.theblues";
}


-(id)init
{
    self = [super init];
    if(self)
    {
		self.effectsArray = [NSMutableArray arrayWithCapacity:3];
        
        
        CIFilter *filter;
        
        filter = [CIFilter filterWithName:@"CIColorControls"];
        [filter setDefaults];
        [filter setValue:[NSNumber numberWithFloat:0.8] forKey:@"inputSaturation"];
        [filter setValue:[NSNumber numberWithFloat:0.35] forKey:@"inputBrightness"];
		[filter setValue:[NSNumber numberWithFloat:1.5] forKey:@"inputContrast"];

        [self.effectsArray addObject:filter];
        
        
        
        filter = [CIFilter filterWithName:@"CIColorMonochrome"];
        //Put that right into the filter
        [filter setValue:[CIColor colorWithRed:0.4 green:1 blue:0.9] forKey:@"inputColor"];
        [filter setValue:[NSNumber numberWithFloat:0.3] forKey:@"inputIntensity"];
        [self.effectsArray addObject:filter];
        
        
    
         filter = [CIFilter filterWithName:@"CITemperatureAndTint"];
         [filter setDefaults];
         [filter setValue:[CIVector vectorWithX:6500 Y:0] forKey:@"inputNeutral"];
         [filter setValue:[CIVector vectorWithX:8500 Y:0] forKey:@"inputTargetNeutral"];
         [self.effectsArray addObject:filter];

        
        filter = [CIFilter filterWithName:@"CIWhitePointAdjust"];
        [filter setDefaults];
        [filter setValue:[CIColor colorWithString:@"0.950 0.85 0.80 1"] forKey:@"inputColor"];
        [self.effectsArray addObject:filter];
        
        filter = [CIFilter filterWithName:@"CIVignette"];
        [filter setDefaults];
        [filter setValue:[NSNumber numberWithFloat:1.0] forKey:@"inputIntensity"];
        [filter setValue:[NSNumber numberWithFloat:2.0] forKey:@"inputRadius"];
        [self.effectsArray addObject:filter];
    }
    
    return self;
}

-(CIImage*)processImage:(CIImage*)inputImage
{
    @autoreleasepool
    {
        CIImage *theImage = inputImage;
        
        for (CIFilter * filter in self.effectsArray) {
            [filter setValue:theImage
                      forKey:kCIInputImageKey];
            
            theImage = filter.outputImage;
        }
        
        return theImage;
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
