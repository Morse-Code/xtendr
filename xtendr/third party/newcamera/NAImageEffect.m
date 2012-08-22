//
//  NAImageEffect.m
//  photovidcap
//
//  Created by Tony Million on 31/07/2012.
//  Copyright (c) 2012 Narrato. All rights reserved.
//

#import "NAImageEffect.h"

@implementation NAImageEffect

+(NSString*)name
{
	return @"No Effect";
}

+(NSString*)identifier
{
	return @"com.fx.nofx";
}

-(NSString*)name
{
	return [[self class] name];
}

-(NSString*)identifier
{
	return [[self class] identifier];
}


-(CIImage*)processImage:(CIImage*)inputImage
{
    return inputImage;
}

-(void)finishProcessing
{
    
}


@end
