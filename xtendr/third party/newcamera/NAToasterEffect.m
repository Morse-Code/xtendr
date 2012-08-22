//
//  NAToasterEffect.m
//  photovidcap
//
//  Created by Tony Million on 01/08/2012.
//  Copyright (c) 2012 Narrato. All rights reserved.
//

#import "NAToasterEffect.h"

@implementation NAToasterEffect

+(NSString*)name
{
	return @"Crumpet";
}

+(NSString*)identifier
{
	return @"com.fx.toaster";
}

-(CIImage*)processImage:(CIImage*)inputImage
{
	CGRect imageRect = [inputImage extent];
	CGPoint center = CGPointMake(CGRectGetMidX(imageRect), CGRectGetMidY(imageRect));

	CGFloat max = MAX(center.x, center.y);

	CIFilter * gradient = [CIFilter filterWithName:@"CIRadialGradient"];
	[gradient setValue:[CIVector vectorWithX:center.x Y:center.y]			forKey:@"inputCenter"];
	[gradient setValue:[NSNumber numberWithInt:max/3]					forKey:@"inputRadius0"];
	[gradient setValue:[NSNumber numberWithInt:MAX(max, 800)]					forKey:@"inputRadius1"];
	
	[gradient setValue:[CIColor colorWithRed:0.9 green:0.4 blue:0.1 alpha:0.131] forKey:@"inputColor0"];
	[gradient setValue:[CIColor colorWithRed:0.7 green:0.0 blue:0.7 alpha:0.073] forKey:@"inputColor1"];

	

	// CROP IT PLS!!
    CIFilter *cropFilter = [CIFilter filterWithName:@"CICrop"];

    [cropFilter setValue:gradient.outputImage
                  forKey:@"inputImage"];
    [cropFilter setValue:[CIVector vectorWithCGRect:imageRect]
                  forKey:@"inputRectangle"];

	
    //MOOOLTIPLY!
    CIFilter *multiply = [CIFilter filterWithName:@"CIScreenBlendMode"];
    [multiply setDefaults];
    [multiply setValue:inputImage
                forKey:kCIInputBackgroundImageKey];
    [multiply setValue:cropFilter.outputImage
                forKey:kCIInputImageKey];

	CIFilter * vignette = [CIFilter filterWithName:@"CIVignette"];
	[vignette setDefaults];
	[vignette setValue:[NSNumber numberWithFloat:0.5] forKey:@"inputIntensity"];
	[vignette setValue:[NSNumber numberWithFloat:2.0] forKey:@"inputRadius"];
	[vignette setValue:multiply.outputImage
				forKey:kCIInputImageKey];

	CIFilter *colorfilter = [CIFilter filterWithName:@"CIColorControls"
									   keysAndValues:
							 kCIInputImageKey,      vignette.outputImage,
							 @"inputSaturation",    [NSNumber numberWithFloat:1.13],
							 @"inputBrightness",    [NSNumber numberWithFloat:0],
							 @"inputContrast",      [NSNumber numberWithFloat:1.1],
							 nil];


	CIFilter * filter = [CIFilter filterWithName:@"CIVibrance"];
	[filter setDefaults];
	[filter setValue:[NSNumber numberWithFloat:1.1] forKey:@"inputAmount"];
    [filter setValue:colorfilter.outputImage
                forKey:kCIInputImageKey];



	return filter.outputImage;
}

-(void)finishProcessing
{
}


@end
