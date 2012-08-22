//
//  XTPostController.h
//  xtendr
//
//  Created by Tony Million on 19/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XTPostController : NSObject

+(XTPostController*)sharedInstance;

-(void)addPostArray:(NSArray*)postArray fromMyStream:(BOOL)myStream fromMentions:(BOOL)mentions;
-(void)addPostArray:(NSArray*)postArray fromMyStream:(BOOL)myStream fromMentions:(BOOL)mentions completion:(void (^)(void))completion;

-(void)addPost:(NSDictionary*)post fromMyStream:(BOOL)myStream fromMentions:(BOOL)mentions;

@end
