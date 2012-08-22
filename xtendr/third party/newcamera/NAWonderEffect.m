//
//  NAWonderEffect.m
//  photovidcap
//
//  Created by Tony Million on 02/08/2012.
//  Copyright (c) 2012 Narrato. All rights reserved.
//

#import "NAWonderEffect.h"

@interface NAWonderEffect ()

@property(strong) CIFilter * gradientFilter;

@property(strong) CIFilter *cropFilter;
@property(strong) CIFilter *lighten;
@property(strong) CIFilter *vibrance;

@property(strong) CIFilter *toneCurveFilter;


@end

@implementation NAWonderEffect

+(NSString*)name
{
	return @"Wonder";
}

+(NSString*)identifier
{
	return @"com.fx.wonder";
}

-(id)init
{
	self = [super init];
	if(self)
	{
		self.gradientFilter = [CIFilter filterWithName:@"CIRadialGradient"];
		[self.gradientFilter setDefaults];

		[self.gradientFilter setValue:[CIColor colorWithRed:0 green:1 blue:0 alpha:0.03]
							   forKey:@"inputColor0"];
		[self.gradientFilter setValue:[CIColor colorWithRed:0 green:0.3 blue:0 alpha:0.01]
							   forKey:@"inputColor1"];



		// CROP IT PLS!!
		self.cropFilter = [CIFilter filterWithName:@"CICrop"];
		[self.cropFilter setDefaults];



		// add a lighten filter!
		self.lighten = [CIFilter filterWithName:@"CIColorDodgeBlendMode"];
		[self.lighten setDefaults];


		// vibrance
		self.vibrance = [CIFilter filterWithName:@"CIVibrance"];
		[self.vibrance setDefaults];
		[self.vibrance setValue:[NSNumber numberWithFloat:1.2] forKey:@"inputAmount"];

		self.toneCurveFilter = [CIFilter filterWithName:@"CIToneCurve"];
        [self.toneCurveFilter setDefaults];

        [self.toneCurveFilter setValue:[CIVector vectorWithX:0.0
														   Y:0.01] forKey:@"inputPoint0"]; // default
        [self.toneCurveFilter setValue:[CIVector vectorWithX:0.25
														   Y:0.2] forKey:@"inputPoint1"];
        [self.toneCurveFilter setValue:[CIVector vectorWithX:0.5
														   Y:0.50] forKey:@"inputPoint2"];
        [self.toneCurveFilter setValue:[CIVector vectorWithX:0.65
														   Y:0.75] forKey:@"inputPoint3"];
        [self.toneCurveFilter setValue:[CIVector vectorWithX:1.0
														   Y:0.95] forKey:@"inputPoint4"]; // default
	}
	return self;
}

-(CIImage*)processImage:(CIImage*)inputImage
{
	CGRect imageRect = [inputImage extent];

	[self.gradientFilter setValue:[CIVector vectorWithX:imageRect.size.width/2
													  Y:imageRect.size.height/2]
						   forKey:@"inputCenter"];

	[self.gradientFilter setValue:[NSNumber numberWithFloat:MIN(800, MAX(imageRect.size.width, imageRect.size.height))*0.78]
						   forKey:@"inputRadius1"];



	[self.cropFilter setValue:self.gradientFilter.outputImage
					   forKey:@"inputImage"];

	[self.cropFilter setValue:[CIVector vectorWithCGRect:imageRect]
					   forKey:@"inputRectangle"];



    [self.lighten setValue:inputImage
					forKey:kCIInputBackgroundImageKey];

    [self.lighten setValue:self.cropFilter.outputImage
					forKey:kCIInputImageKey];


    [self.vibrance setValue:self.lighten.outputImage
					 forKey:kCIInputImageKey];

	//[self.toneCurveFilter setValue:self.vibrance.outputImage
	//						forKey:kCIInputImageKey];


	return self.vibrance.outputImage;
}

-(void)finishProcessing
{
	// most of what we fo here is setting the imput images to nil to keep memory down
    [self.lighten setValue:nil forKey:kCIInputBackgroundImageKey];
    [self.lighten setValue:nil forKey:kCIInputImageKey];

    [self.vibrance setValue:nil forKey:kCIInputImageKey];

	[self.toneCurveFilter setValue:nil forKey:kCIInputImageKey];
}



@end
