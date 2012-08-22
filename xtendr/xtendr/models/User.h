//
//  User.h
//  xtendr
//
//  Created by Tony Million on 21/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Post;

@interface User : NSManagedObject

@property (nonatomic, retain) id avatar_image_dict;
@property (nonatomic, retain) id cover_image_dict;
@property (nonatomic, retain) NSDate * created_at;
@property (nonatomic, retain) NSString * desc_html;
@property (nonatomic, retain) NSString * desc_text;
@property (nonatomic, retain) NSNumber * followers;
@property (nonatomic, retain) NSNumber * following;
@property (nonatomic, retain) NSNumber * follows_you;
@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSNumber * intid;
@property (nonatomic, retain) NSString * locale;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * postcount;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSNumber * you_follow;
@property (nonatomic, retain) NSNumber * you_muted;
@property (nonatomic, retain) NSSet *posts;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addPostsObject:(Post *)value;
- (void)removePostsObject:(Post *)value;
- (void)addPosts:(NSSet *)values;
- (void)removePosts:(NSSet *)values;

@end
