//
//  XTUserController.m
//  xtendr
//
//  Created by Tony Million on 19/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import "XTUserController.h"

@interface XTUserController ()

@property(strong) NSDateFormatter		*ISO8601Formatter;

@end

@implementation XTUserController
{
	dispatch_queue_t	_addQueue;
}

+(XTUserController*)sharedInstance
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
		_addQueue = dispatch_queue_create("com.tonymillion.useraddqueue", DISPATCH_QUEUE_SERIAL);

		self.ISO8601Formatter = [[NSDateFormatter alloc] init];
		[self.ISO8601Formatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
		[self.ISO8601Formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

	}

	return self;
}

//everything funnels in here
-(User*)insertUser:(NSDictionary*)userDict inContext:(NSManagedObjectContext*)context
{
	NSString * ID = [userDict valueForKey:@"id"];
	if(!ID)
		return nil;

	User * user = [User userByID:ID inContext:context];
	if(user)
	{
		//merge user
		DLog(@"Merge User");
	}
	else
	{
		//create user
		DLog(@"Create User");
		user = [User userByID:ID
					inContext:context
			createIfNecessary:YES];

		if(!user.created_at)
		{
			user.created_at = [self.ISO8601Formatter  dateFromString:[userDict objectForKey:@"created_at"]];
		}
	}

	//TODO: can a user change their user name?
	if(user.username)
	{
		if(![user.username isEqual:[userDict objectForKey:@"username"]])
			user.username	= [userDict objectForKey:@"username"];
	}
	else
	{
		if([userDict objectForKey:@"username"])
			user.username	= [userDict objectForKey:@"username"];
	}


	
	if(user.name)
	{
		if(![user.name isEqual:[userDict objectForKey:@"name"]])
			user.name	= [userDict objectForKey:@"name"];
	}
	else
	{
		if([userDict objectForKey:@"name"])
			user.name	= [userDict objectForKey:@"name"];
	}


	
	NSDictionary * description = [userDict objectForKey:@"description"];
	if(description)
	{
		if([description objectForKey:@"text"])
		{
			if(user.desc_text)
			{
				// merge it
				if(![user.desc_text isEqual:[description objectForKey:@"text"]])
					user.desc_text = [description objectForKey:@"text"];
			}
			else
			{
				user.desc_text = [description objectForKey:@"text"];
			}
		}

		if([description objectForKey:@"html"])
		{
			if(user.desc_html)
			{
				// merge it
				if(![user.desc_html isEqual:[description objectForKey:@"html"]])
					user.desc_html = [description objectForKey:@"html"];
			}
			else
			{
				user.desc_html = [description objectForKey:@"html"];
			}
		}
	}


	// this can merge
	if(user.follows_you)
	{
		if(![user.follows_you isEqual:[userDict objectForKey:@"follows_you"]])
			user.follows_you	= [userDict objectForKey:@"follows_you"];
	}
	else
	{
		user.follows_you	= [userDict objectForKey:@"follows_you"];
	}

	if(user.you_follow)
	{
		if(![user.you_follow isEqual:[userDict objectForKey:@"you_follow"]])
			user.you_follow		= [userDict objectForKey:@"you_follow"];
	}
	else
	{
		user.you_follow		= [userDict objectForKey:@"you_follow"];
	}

	if(user.you_muted)
	{
		if(![user.you_follow isEqual:[userDict objectForKey:@"you_muted"]])
			user.you_muted		= [userDict objectForKey:@"you_muted"];
	}
	else
	{
		user.you_muted		= [userDict objectForKey:@"you_muted"];
	}
	
	NSDictionary * counts = [userDict objectForKey:@"counts"];
	if(counts)
	{
		if(user.followers)
		{
			if(![user.followers isEqual:[counts objectForKey:@"followers"]])
				user.followers		= [counts objectForKey:@"followers"];
		}
		else
		{
			user.followers		= [counts objectForKey:@"followers"];
		}

		if(user.following)
		{
			if(![user.following isEqual:[counts objectForKey:@"following"]])
				user.following		= [counts objectForKey:@"following"];
		}
		else
		{
			user.following		= [counts objectForKey:@"following"];
		}

		if(user.postcount)
		{
			if(![user.postcount isEqual:[counts objectForKey:@"posts"]])
				if([[counts objectForKey:@"posts"] isKindOfClass:[NSNumber class]])
					user.postcount		= [counts objectForKey:@"posts"];
		}
		else
		{
			user.postcount		= [counts objectForKey:@"posts"];
		}
	}

	if([userDict objectForKey:@"avatar_image"])
	{
		// we only care if the key is included eh
		if(user.avatar_image_dict)
		{
			if(![user.avatar_image_dict isEqualToDictionary:[userDict objectForKey:@"avatar_image"]])
				user.avatar_image_dict = [userDict objectForKey:@"avatar_image"];
		}
		else
		{
			user.avatar_image_dict = [userDict objectForKey:@"avatar_image"];
		}
	}
	
	if([userDict objectForKey:@"cover_image"])
	{
		// we only care if the key is included eh
		if(user.cover_image_dict)
		{
			if(![user.cover_image_dict isEqualToDictionary:[userDict objectForKey:@"cover_image"]])
				user.cover_image_dict = [userDict objectForKey:@"cover_image"];
		}
		else
		{
			user.cover_image_dict = [userDict objectForKey:@"cover_image"];
		}
	}

	//DO NOT SAVE HERE
	return user;
}

//stuff to process on a background thread so we dont hang the UI too much
-(void)backgroundAddUserArray:(NSArray*)userArray
{
	NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
	[context setPersistentStoreCoordinator:[XTAppDelegate sharedInstance].persistentStoreCoordinator];

	for (NSDictionary * userDict in userArray)
	{
		[self insertUser:userDict inContext:context];
	}

	NSError * error;
	if([context hasChanges] && ![context save:&error])
	{
		DLog(@"user save error: %@", error);
	}
	context = nil;
}

-(void)backgroundAddUser:(NSDictionary*)userDict
{
	NSManagedObjectContext * context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSConfinementConcurrencyType];
	[context setPersistentStoreCoordinator:[XTAppDelegate sharedInstance].persistentStoreCoordinator];

	[self insertUser:userDict inContext:context];

	NSError * error;
	if([context hasChanges] && ![context save:&error])
	{
		DLog(@"user save error: %@", error);
	}
	context = nil;
}

//publically accessable functions
-(void)addUsersFromArray:(NSArray*)userDictArray
{
	if(userDictArray.count == 0)
		return;

	dispatch_async(_addQueue, ^{
		[self backgroundAddUserArray:userDictArray];
	});
}

//publically accessable functions
-(void)addUsersFromArray:(NSArray*)userDictArray completion:(void (^)(void))completion
{
	if(userDictArray.count == 0)
		return;

	dispatch_async(_addQueue, ^{
		[self backgroundAddUserArray:userDictArray];
		dispatch_async(dispatch_get_main_queue(), completion);
	});
}

-(void)addUser:(NSDictionary*)userDict
{
	dispatch_async(_addQueue, ^{
		[self backgroundAddUser:userDict];
	});
}

-(void)addUser:(NSDictionary*)userDict  completion:(void (^)(void))completion
{
	dispatch_async(_addQueue, ^{
		[self backgroundAddUser:userDict];
		dispatch_async(dispatch_get_main_queue(), completion);
	});
}

@end
