//
//  NAArbusEffect.m
//  photovidcap
//
//  Created by Tony Million on 02/08/2012.
//  Copyright (c) 2012 Narrato. All rights reserved.
//

#import "NAArbusEffect.h"

@interface NAArbusEffect ()

@property(strong) CIFilter *greyFilter;


@end

@implementation NAArbusEffect

+(NSString*)name
{
	return @"Arbus";
}

+(NSString*)identifier
{
	return @"com.fx.arbus";
}

-(id)init
{
	self = [super init];
	if(self)
	{
		self.greyFilter = [CIFilter filterWithName:@""];
	}
	return self;
}

-(CIImage*)processImage:(CIImage*)inputImage
{
	CIImage *blackAndWhite = [CIFilter filterWithName:@"CIColorControls" keysAndValues:
							  kCIInputImageKey, inputImage,
							  @"inputBrightness", [NSNumber numberWithFloat:-0.01],
							  @"inputContrast", [NSNumber numberWithFloat:1.0],
							  @"inputSaturation", [NSNumber numberWithFloat:0.0], nil].outputImage;
	
    CIImage *output = [CIFilter filterWithName:@"CIExposureAdjust" keysAndValues:
					   kCIInputImageKey, blackAndWhite,
					   @"inputEV", [NSNumber numberWithFloat:0.3], nil].outputImage;

	return output;

}

@end
