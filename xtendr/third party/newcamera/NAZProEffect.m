//
//  NAZProEffect.m
//  zummzumm
//
//  Created by Tony Million on 06/08/2012.
//  Copyright (c) 2012 OmniTyke. All rights reserved.
//

#import "NAZProEffect.h"

@interface NAZProEffect ()

@property(strong) NSMutableArray    *effectsArray;

@end

@implementation NAZProEffect

+(NSString*)name
{
	return @"ZPro";
}

+(NSString*)identifier
{
	return @"com.fx.zpro";
}

-(id)init
{
	self = [super init];
	if(self)
	{
		self.effectsArray = [NSMutableArray arrayWithCapacity:3];

		// apply a vignette
        CIFilter *vignettefilter = [CIFilter filterWithName:@"CIVignette"];

        [vignettefilter setDefaults];

        [vignettefilter setValue:[NSNumber numberWithFloat:1]
                          forKey:@"inputIntensity"];

        [vignettefilter setValue:[NSNumber numberWithFloat:2]
                          forKey:@"inputRadius"];

		[self.effectsArray addObject:vignettefilter];

		// Make tone filter filter
        // See mentioned link for visual reference
        CIFilter *toneCurveFilter = [CIFilter filterWithName:@"CIToneCurve"];
        [toneCurveFilter setDefaults];
        [toneCurveFilter setValue:[CIVector vectorWithX:0.01
                                                      Y:0.0] forKey:@"inputPoint0"]; // default
        [toneCurveFilter setValue:[CIVector vectorWithX:0.25
                                                      Y:0.2] forKey:@"inputPoint1"];
        [toneCurveFilter setValue:[CIVector vectorWithX:0.5
                                                      Y:0.50] forKey:@"inputPoint2"];
        [toneCurveFilter setValue:[CIVector vectorWithX:0.65
                                                      Y:0.75] forKey:@"inputPoint3"];
        [toneCurveFilter setValue:[CIVector vectorWithX:1.0
                                                      Y:1.0] forKey:@"inputPoint4"]; // default

		[self.effectsArray addObject:toneCurveFilter];

		////////////////////////////
        CIFilter * mono = [CIFilter filterWithName:@"CIColorMonochrome"];
        [mono setDefaults];

        [mono setValue:[CIColor colorWithRed:0.999582
                                       green:0.985841
                                        blue:0.686454]
                forKey:@"inputColor"];

        [mono setValue:[NSNumber numberWithFloat:0.1804339]
                forKey:@"inputIntensity"];

		[self.effectsArray addObject:mono];


		CIFilter * matrixFilter = [CIFilter filterWithName:@"CIColorMatrix"];
		[matrixFilter setDefaults]; // 3
		[matrixFilter setValue:[CIVector vectorWithX:1
												   Y:0
												   Z:0
												   W:0] forKey:@"inputRVector"]; // 5

		[matrixFilter setValue:[CIVector vectorWithX:0
												   Y:1
												   Z:0
												   W:0] forKey:@"inputGVector"]; // 6
		
		[matrixFilter setValue:[CIVector vectorWithX:0.01
												   Y:0.03
												   Z:1
												   W:0.02] forKey:@"inputBVector"]; // 7
		
		[matrixFilter setValue:[CIVector vectorWithX:0
												   Y:0
												   Z:0
												   W:1] forKey:@"inputAVector"]; // 8

		[self.effectsArray addObject:matrixFilter];

		CIFilter *colorfilter = [CIFilter filterWithName:@"CIColorControls"
                                           keysAndValues:
                                 @"inputSaturation",    [NSNumber numberWithFloat:1.3],
                                 @"inputBrightness",    [NSNumber numberWithFloat:0.03189695],
                                 @"inputContrast",      [NSNumber numberWithFloat:1.1],
                                 nil];

		[self.effectsArray addObject:colorfilter];


		// vibrance
		CIFilter * vibrance = [CIFilter filterWithName:@"CIVibrance"];
		[vibrance setDefaults];
		[vibrance setValue:[NSNumber numberWithFloat:1.5]
				  forKey:@"inputAmount"];
		[self.effectsArray addObject:vibrance];
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
