//
//  XTPostController.m
//  xtendr
//
//  Created by Tony Million on 19/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import "XTPostController.h"

#import "Post.h"
#import "Post+coolstuff.h"

#import "XTUserController.h"

@interface XTPostController ()

@property(strong) NSDateFormatter		*ISO8601Formatter;

@end

@implementation XTPostController
{
	dispatch_queue_t	_addQueue;
}

+(XTPostController*)sharedInstance
{
	static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init]; // or some other init method
    });
    return _sharedObject;
}

-(id)init
{
	self = [super init];

	if(self)
	{
		_addQueue = dispatch_queue_create("com.tonymillion.postaddqueue", DISPATCH_QUEUE_SERIAL);
		self.ISO8601Formatter = [[NSDateFormatter alloc] init];
		[self.ISO8601Formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
		[self.ISO8601Formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

	}

	return self;
}

//everything funnels in here
-(Post*)internalPostStuff:(NSDictionary*)postDict
			   inContext:(NSManagedObjectContext*)context
			   isMention:(BOOL)isMention
			  isMyStream:(BOOL)isMyStream
{
	NSString * ID = [postDict valueForKey:@"id"];

	Post * post = [Post postByID:ID inContext:context];
	if(post)
	{
		//merge user
		// The idea behind this is to try and NOT touch anything inside of the managedobject
		// if we can at all help it as then it'll have to be written to disk
		// which will lock up the UI now and again!
		//DLog(@"Merge post");
		if(!post.thread_id)
		{
			post.thread_id		= [postDict objectForKey:@"thread_id"];
		}
		
		if(post.num_replies && [postDict objectForKey:@"num_replies"])
		{
			if(![post.num_replies isEqual:[postDict objectForKey:@"num_replies"]])
				post.num_replies	= [postDict objectForKey:@"num_replies"];
		}
		else
		{
			post.num_replies	= [postDict objectForKey:@"num_replies"];
		}
	}
	else
	{
		//create user
		//DLog(@"Create post: %@", ID);
		post = [Post postByID:ID inContext:context createIfNecessary:YES];

		//right now we dont do ANY merging or whatever, we just overwrite with what we have
		//TODO: extract user object and link!
		if(!post.user)
		{
			NSDictionary * userDict = [postDict objectForKey:@"user"];
			if(userDict)
			{
				User * user = [[XTUserController sharedInstance] insertUser:userDict
																  inContext:context];
				if(user)
				{
					//[user.managedObjectContext save:nil];
					post.user = user;
					post.userid = user.id;
				}
				else
				{
					DLog(@"Could not create user: %@", [userDict objectForKey:@"id"]);
				}
			}
			else
			{
				DLog(@"User not present for postid: %@", post.id);
			}
		}

		if(!post.created_at)
		{
			NSString * createdatstring = [postDict objectForKey:@"created_at"];
			post.created_at		= [self.ISO8601Formatter dateFromString:createdatstring];
		}
		
		if([postDict objectForKey:@"text"])
			post.text			= [postDict objectForKey:@"text"];
		if([postDict objectForKey:@"html"])
			post.html			= [postDict objectForKey:@"html"];


		//YUCK WHAT ABOUT THIS
		if(!post.annotations_dict)
			post.annotations_dict	= [postDict objectForKey:@"annotations"];

		if(!post.entities_dict)
			post.entities_dict		= [postDict objectForKey:@"entities"];

		if(!post.source_link || !post.source_name)
		{
			NSDictionary * source = [postDict objectForKey:@"source"];
			post.source_link	= [source objectForKey:@"link"];
			post.source_name	= [source objectForKey:@"name"];
		}

		if(!post.reply_to)
			post.reply_to		= [postDict objectForKey:@"reply_to"];

		if(!post.thread_id)
			post.thread_id		= [postDict objectForKey:@"thread_id"];

		//END OF CREATE
	}
	

	if([postDict objectForKey:@"is_deleted"])
	{
		if(![post.is_deleted isEqual:[postDict objectForKey:@"is_deleted"]])
			post.is_deleted		= [postDict objectForKey:@"is_deleted"];
	}
	else
	{
		if(!post.is_deleted)
			post.is_deleted		= [NSNumber numberWithBool:NO];
	}

	//Ok so what we do here, is as we're merging the post
	// if this isn't set, then lets see if it came from a list
	// if so set the bool for that list
	// if not drop out!
	// BUT WE ONLY DO THIS IF IT HASN'T ALREADY BEEN SET INNIT!
	if(post.is_mention == nil)
	{
		if(isMention)
		{
			post.is_mention = [NSNumber numberWithBool:YES];
		}
	}

	if(post.is_mystream == nil)
	{
		if(isMyStream)
		{
			post.is_mystream = [NSNumber numberWithBool:YES];
		}
	}


	//DO NOT SAVE HERE

	return post;
}

-(void)backgroundAddPostArray:(NSArray*)postArray fromMyStream:(BOOL)myStream fromMentions:(BOOL)mentions
{
	NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
	[context setPersistentStoreCoordinator:[XTAppDelegate sharedInstance].persistentStoreCoordinator];

	for (NSDictionary * postDict in postArray)
	{
		[self internalPostStuff:postDict inContext:context isMention:mentions isMyStream:myStream];
	}

	NSError * error;
	if([context hasChanges] && ![context save:&error])
	{
		DLog(@"user save error: %@", error);
	}
	context = nil;
}

-(void)backgroundAddPost:(NSDictionary*)postDict fromMyStream:(BOOL)myStream fromMentions:(BOOL)mentions
{
	NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
	[context setPersistentStoreCoordinator:[XTAppDelegate sharedInstance].persistentStoreCoordinator];

	[self internalPostStuff:postDict inContext:context isMention:mentions isMyStream:myStream];

	NSError * error;
	if([context hasChanges] && ![context save:&error])
	{
		DLog(@"user save error: %@", error);
	}
	context = nil;
}

-(void)addPostArray:(NSArray*)postArray fromMyStream:(BOOL)myStream fromMentions:(BOOL)mentions
{
	if(postArray.count == 0)
		return;

	dispatch_async(_addQueue, ^{
		[self backgroundAddPostArray:postArray fromMyStream:myStream fromMentions:mentions];
	});
}

-(void)addPostArray:(NSArray*)postArray fromMyStream:(BOOL)myStream fromMentions:(BOOL)mentions completion:(void (^)(void))completion
{
	if(postArray.count == 0)
		return;

	dispatch_async(_addQueue, ^{
		[self backgroundAddPostArray:postArray fromMyStream:myStream fromMentions:mentions];

		dispatch_async(dispatch_get_main_queue(), completion);
	});
}


-(void)addPost:(NSDictionary*)postDict fromMyStream:(BOOL)myStream fromMentions:(BOOL)mentions
{
	dispatch_async(_addQueue, ^{
		[self backgroundAddPost:postDict fromMyStream:myStream fromMentions:mentions];
	});
}

@end
