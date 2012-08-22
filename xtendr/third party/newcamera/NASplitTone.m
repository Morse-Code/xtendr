//
//  NASplitTone.m
//  zummzumm
//
//  Created by Tony Million on 11/08/2012.
//  Copyright (c) 2012 OmniTyke. All rights reserved.
//

#import "NASplitTone.h"

@interface NASplitTone ()

@property(strong) CIFilter *lightDark;
@property(strong) CIFilter *monochromeFilter;
@property(strong) CIFilter *screenBlend;
@property(strong) CIFilter *hueFilter;

@end

@implementation NASplitTone

+(NSString*)name
{
	return @"SplitTone";
}

+(NSString*)identifier
{
	return @"com.fx.splittone";
}

-(id)init
{
    self = [super init];
    if(self)
    {
        self.lightDark = [CIFilter filterWithName:@"CIFalseColor"];

        [self.lightDark setDefaults];

        CIColor *myBlue = [CIColor colorWithRed:0.0 green:0.0 blue:0.6 alpha:0.5];
        CIColor *myRed = [CIColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:0.5];

        [self.lightDark setValue:myBlue forKey:@"inputColor0"];
        [self.lightDark setValue:myRed forKey:@"inputColor1"];

        self.monochromeFilter = [CIFilter filterWithName:@"CIColorMonochrome"]; // CIImage
        [self.monochromeFilter setDefaults];
        [self.monochromeFilter setValue:[CIColor colorWithRed:0.621717
                                                   green:0.621717
                                                    blue:0.0]
                            forKey:@"inputColor"];
        [self.monochromeFilter setValue:[NSNumber numberWithFloat:0.8] forKey:@"inputIntensity"];

		self.screenBlend = [CIFilter filterWithName:@"CIScreenBlendMode"];

        self.hueFilter = [CIFilter filterWithName:@"CIHueAdjust"];
        [self.hueFilter setDefaults];
        [self.hueFilter setValue:[NSNumber numberWithFloat:-0.3662509]
						  forKey:@"inputAngle"];


	}
	return self;
}

-(CIImage*)processImage:(CIImage*)inputImage
{
    @autoreleasepool
    {
		[self.lightDark setValue:inputImage
						  forKey:kCIInputImageKey];

		[self.monochromeFilter setValue:inputImage
								 forKey:kCIInputImageKey];


        [self.screenBlend setValue:self.lightDark.outputImage
							forKey:kCIInputImageKey];

        [self.screenBlend setValue:self.monochromeFilter.outputImage
                       forKey:kCIInputBackgroundImageKey];

		[self.hueFilter setValue:self.screenBlend.outputImage
						  forKey:kCIInputImageKey];



        return self.hueFilter.outputImage;
    }
}

-(void)finishProcessing
{
	[self.lightDark setValue:nil
					  forKey:kCIInputImageKey];

	[self.monochromeFilter setValue:nil
							 forKey:kCIInputImageKey];


	[self.screenBlend setValue:nil
						forKey:kCIInputImageKey];

	[self.screenBlend setValue:nil
						forKey:kCIInputBackgroundImageKey];

	[self.hueFilter setValue:nil
					  forKey:kCIInputImageKey];

}

@end

