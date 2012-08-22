//
//  NAImageEffect.h
//  photovidcap
//
//  Created by Tony Million on 31/07/2012.
//  Copyright (c) 2012 Narrato. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreImage/CoreImage.h>

@interface NAImageEffect : NSObject

+(NSString*)name;
+(NSString*)identifier;

-(NSString*)name;
-(NSString*)identifier;

-(CIImage*)processImage:(CIImage*)inputImage;
-(void)finishProcessing;

@end
