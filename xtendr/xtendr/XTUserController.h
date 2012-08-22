//
//  XTUserController.h
//  xtendr
//
//  Created by Tony Million on 19/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XTUserController : NSObject

+(XTUserController*)sharedInstance;

-(User*)insertUser:(NSDictionary*)userDict inContext:(NSManagedObjectContext*)context;


-(void)addUsersFromArray:(NSArray*)userDictArray;
-(void)addUser:(NSDictionary*)userDict;

-(void)addUsersFromArray:(NSArray*)userDictArray completion:(void (^)(void))completion;
-(void)addUser:(NSDictionary*)userDict  completion:(void (^)(void))completion;

@end
