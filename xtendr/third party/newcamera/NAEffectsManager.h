//
//  NAEffectsManager.h
//  photovidcap
//
//  Created by Tony Million on 01/08/2012.
//  Copyright (c) 2012 Narrato. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "NAImageEffect.h"

@interface NAEffectsManager : NSObject

+(NAEffectsManager*)sharedInstance;

-(void)generateThumbnailsFromImage:(UIImage*)startImage;
-(void)deleteThumbnails;

-(NSUInteger)count;

-(NAImageEffect*)effectAtIndex:(NSUInteger)index;
-(NAImageEffect*)effectWithIdentifier:(NSString*)identifier;

-(NSString*)nameForEffectAtIndex:(NSUInteger)index;
-(NSString*)identifierForEffectAtIndex:(NSUInteger)index;
-(UIImage*)thumbnnailForEffectAtIndex:(NSUInteger)index;


@end
