//
//  Post+coolstuff.m
//  xtendr
//
//  Created by Tony Million on 19/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import "Post+coolstuff.h"

@implementation Post (coolstuff)

+(Post*)postByID:(NSString*)id inContext:(NSManagedObjectContext*)context
{
	NSFetchRequest *request= [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post"
											  inManagedObjectContext:context];
	[request setEntity:entity];

	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"id = %@", id];
	[request setPredicate:predicate];
	[request setFetchLimit:1];

	NSError *error;
	//so if the object isn't in core data it returns a 0 length array
	// at which point lastObject returns nil
	// yay
	Post * entry = [[context executeFetchRequest:request
										   error:&error] lastObject];

	return entry;
}

+(Post*)postByID:(NSString*)ID inContext:(NSManagedObjectContext*)context createIfNecessary:(BOOL)create
{
	Post * temp = [Post postByID:ID inContext:context];

	if(!temp && create)
	{
		//TODO: create object and assign ID
		temp = [NSEntityDescription insertNewObjectForEntityForName:@"Post"
											 inManagedObjectContext:context];
		temp.id		= ID;
		temp.intid	= [NSNumber numberWithLongLong:[ID longLongValue]];

	}

	return temp;
}

-(NSDictionary*)entities
{
	return self.entities;
}

-(NSArray*)mentions
{
	NSDictionary * entities = self.entities_dict;
	NSMutableArray *mentions = [NSMutableArray arrayWithCapacity:4];

	for (NSDictionary * mentionDict in [entities objectForKey:@"mentions"]) {
		XTMention * mention = [[XTMention alloc] initWithAttributes:mentionDict];
		[mentions addObject:mention];
	}

	return mentions;
}

-(NSArray*)hashtags
{
	NSDictionary * entities = self.entities_dict;
	NSMutableArray *hashtags = [NSMutableArray arrayWithCapacity:4];

	for (NSDictionary * mentionDict in [entities objectForKey:@"hashtags"]) {
		XTHashTag * hashtag = [[XTHashTag alloc] initWithAttributes:mentionDict];
		[hashtags addObject:hashtag];
	}

	return hashtags;
}

+(NSUInteger)topPostID
{
	NSUInteger returnval = -1;
	
	NSManagedObjectContext * context = [[NSManagedObjectContext alloc] init];
	[context setPersistentStoreCoordinator:[XTAppDelegate sharedInstance].persistentStoreCoordinator];

	// Create and configure a fetch request.
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];

    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Post"
                                              inManagedObjectContext:[XTAppDelegate sharedInstance].managedObjectContext];

    [fetchRequest setEntity:entity];

    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"intid" ascending:NO];
    NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:sortDescriptor, nil];
    [fetchRequest setSortDescriptors:sortDescriptors];

	[fetchRequest setFetchLimit:1];
	[fetchRequest setFetchBatchSize:1];


	NSError * error;
	NSArray * result = [context executeFetchRequest:fetchRequest error:&error];
	if(result)
	{
		Post * post = [result lastObject];
		returnval = [post.intid unsignedIntegerValue];
	}

	context = nil;

	return returnval;
}


@end
