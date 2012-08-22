//
//  NAOrlandoEffect.m
//  photovidcap
//
//  Created by Tony Million on 02/08/2012.
//  Copyright (c) 2012 Narrato. All rights reserved.
//

#import "NAOrlandoEffect.h"

@interface NAOrlandoEffect ()

@property(strong) CIImage * cyanImage;

@property(strong) CIFilter *toneCurve;
@property(strong) CIFilter *matrixFilter;

@property(strong) CIFilter *vibrance;
@end


@implementation NAOrlandoEffect

+(NSString*)name
{
	return @"Orlando";
}

+(NSString*)identifier
{
	return @"com.fx.orlando";
}

-(id)init
{
	self = [super init];
	if(self)
	{
		self.toneCurve = [CIFilter filterWithName:@"CIToneCurve"];
        [self.toneCurve setDefaults];
        [self.toneCurve setValue:[CIVector vectorWithX:0.0
											 Y:0.1] forKey:@"inputPoint0"]; // default
        [self.toneCurve setValue:[CIVector vectorWithX:0.25
											 Y:0.20] forKey:@"inputPoint1"];
        [self.toneCurve setValue:[CIVector vectorWithX:0.5
											 Y:0.45] forKey:@"inputPoint2"];
        [self.toneCurve setValue:[CIVector vectorWithX:0.75
											 Y:0.85] forKey:@"inputPoint3"];
        [self.toneCurve setValue:[CIVector vectorWithX:1.0
											 Y:1] forKey:@"inputPoint4"]; // default



		self.matrixFilter = [CIFilter filterWithName:@"CIColorMatrix"];
		[self.matrixFilter setDefaults]; // 3
		[self.matrixFilter setValue:[CIVector vectorWithX:1
														Y:-0.01
														Z:-0.021
														W:0] forKey:@"inputRVector"]; // 5

		[self.matrixFilter setValue:[CIVector vectorWithX:0
														Y:1
														Z:0
														W:0] forKey:@"inputGVector"]; // 6

		[self.matrixFilter setValue:[CIVector vectorWithX:0.1
														Y:0.3
														Z:1
														W:0.07] forKey:@"inputBVector"]; // 7
		[self.matrixFilter setValue:[CIVector vectorWithX:0
														Y:0
														Z:0 W:1] forKey:@"inputAVector"]; // 8
		


		// vibrance
		self.vibrance = [CIFilter filterWithName:@"CIVibrance"];
		[self.vibrance setDefaults];
		[self.vibrance setValue:[NSNumber numberWithFloat:0.2] forKey:@"inputAmount"];
	}
	return self;
}

-(CIImage*)processImage:(CIImage*)inputImage
{
	[self.matrixFilter setValue:inputImage
						 forKey:kCIInputImageKey];


	[self.toneCurve setValue:self.matrixFilter.outputImage
					 forKey:kCIInputImageKey];


    [self.vibrance setValue:self.toneCurve.outputImage
					 forKey:kCIInputImageKey];

	return self.vibrance.outputImage;
}

-(void)finishProcessing
{
	// most of what we fo here is setting the imput images to nil to keep memory down
	[self.toneCurve setValue:nil
					  forKey:kCIInputImageKey];

	[self.matrixFilter setValue:nil
						 forKey:kCIInputImageKey];

	[self.vibrance setValue:nil
					forKey:kCIInputImageKey];
}


@end
