//
//  Post+coolstuff.h
//  xtendr
//
//  Created by Tony Million on 19/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import "Post.h"

#import	"XTMention.h"
#import	"XTHashtag.h"

@interface Post (coolstuff)

+(Post*)postByID:(NSString*)id inContext:(NSManagedObjectContext*)context;
+(Post*)postByID:(NSString*)id inContext:(NSManagedObjectContext*)context createIfNecessary:(BOOL)create;

+(NSUInteger)topPostID;

-(NSDictionary*)entities;

-(NSArray*)mentions;
-(NSArray*)hashtags;

@end
