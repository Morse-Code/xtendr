//
//  NAClassicImageEffect.m
//  photovidcap
//
//  Created by Tony Million on 31/07/2012.
//  Copyright (c) 2012 Narrato. All rights reserved.
//

#import "NAClassicImageEffect.h"

float blend(float a,float b,float x) { return ((a) * (1 - (x)) + (b) * (x)); }

@interface NAClassicImageEffect ()

@property(strong) NSMutableArray    *effectsArray;

@end


@implementation NAClassicImageEffect

+(NSString*)name
{
	return @"Classic";
}

+(NSString*)identifier
{
	return @"com.fx.classic";
}

-(id)init
{
    self = [super init];
    if(self)
    {

        self.effectsArray = [NSMutableArray arrayWithCapacity:3];

        CIFilter *filter;

        //filter = [CIFilter filterWithName:@"CISepiaTone"];
        //[filter setDefaults];
        //[filter setValue:[NSNumber numberWithFloat:0.5f] forKey:@"inputIntensity"];
        //[self.effectsArray addObject:filter];

		CIFilter *monochromeFilter = [CIFilter filterWithName:@"CIColorMonochrome"];
        [monochromeFilter setValue:[CIColor colorWithRed:0.75 green:0.75 blue:0.75] forKey:@"inputColor"];
        [monochromeFilter setValue:[NSNumber numberWithFloat:0.3] forKey:@"inputIntensity"];
        [self.effectsArray addObject:monochromeFilter];


		CIFilter* caFilter = [CIFilter filterWithName:@"CIColorMatrix"];
		[caFilter setDefaults];

		[caFilter setValue:[CIVector vectorWithX:1
											   Y:0.27
											   Z:0.495
											   W:-0.13]
					forKey:@"inputRVector"];
		
		[caFilter setValue:[CIVector vectorWithX:-0.01
											   Y:0.69
											   Z:0.42
											   W:0]
					forKey:@"inputGVector"];
		
		[caFilter setValue:[CIVector vectorWithX:-0.19
											   Y:0
											   Z:1
											   W:0]
					forKey:@"inputBVector"];
		
		[caFilter setValue:[CIVector vectorWithX:0
											   Y:0
											   Z:0.08
											   W:1]
					forKey:@"inputAVector"];
		
		[caFilter setValue:[CIVector vectorWithX:0
											   Y:0
											   Z:0
											   W:0]
					forKey:@"inputBiasVector"];
        [self.effectsArray addObject:caFilter];


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
