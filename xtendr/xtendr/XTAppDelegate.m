//
//  XTAppDelegate.m
//  xtendr
//
//  Created by Tony Million on 18/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

// http://api.imgur.com/2/upload
// key = key
// type = file
// use multipart form
// imgur key: dda44bbcc35afffc3419cb5ca961ca94

#import "XTAppDelegate.h"

#import "XTProfileController.h"

#import "IIViewDeckController.h"
#import "XTLeftPanelViewController.h"
#import "XTNoCredentialsViewController.h"

#import "XTTimelineViewController.h"
#import "XTProfileViewController.h"

#import "XTHTTPClient.h"

#import "XTSettingsViewController.h"
#import "XTFeedbackViewController.h"
#import "XTSearchViewController.h"

#import "TMImgurUploader.h"
#import "NAEffectsManager.h"

#import "XTHashTagViewController.h"

#import "XTNewPostViewController.h"

NSString *kANAPIClientID	= @"zkQLXuAgUa2SF8Ws3G6SVhdHtsyTkq3x";

@interface XTAppDelegate () <IIViewDeckControllerDelegate>

@property(strong) UIBarButtonItem               *leftActivator;
@property(strong) IIViewDeckController			*viewDeck;
@property(strong) XTLeftPanelViewController		*leftPanelController;

@property(strong) XTTimelineViewController		*myTimelineController;
@property(strong) XTTimelineViewController		*globalTimelineController;
@property(strong) XTTimelineViewController		*mentionsTimelineController;

@property(strong) XTSearchViewController		*searchViewController;

@end

@implementation XTAppDelegate

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

@synthesize userProfilePicCache = _userProfilePicCache;
@synthesize userCoverArtCache	= _userCoverArtCache;

+(XTAppDelegate*)sharedInstance
{
	return (XTAppDelegate*)[UIApplication sharedApplication].delegate;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[TestFlight takeOff:@"b0e0f25f6e562d4dbed0b8bdad6abdc3_MTIyNjc1MjAxMi0wOC0xOCAwOTozNDo0My4yMTkyNzc"];

	// primes the profile!
	[self managedObjectContext];
	[XTProfileController sharedInstance];

	[TMImgurUploader sharedInstance].APIKey = @"dda44bbcc35afffc3419cb5ca961ca94";

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(syncDidSave:)
												 name:NSManagedObjectContextDidSaveNotification
											   object:nil];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.

	[[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navigationbar"]
									   forBarMetrics:UIBarMetricsDefault];

	[[UINavigationBar appearance] setTintColor:[UIColor colorWithRed:0.129
															   green:0.549
																blue:0.898
															   alpha:1.0000]];



	self.leftPanelController = [[XTLeftPanelViewController alloc] init];

	// Override point for customization after application launch.
    self.viewDeck = [[IIViewDeckController alloc] init];
    self.viewDeck.centerhiddenInteractivity = IIViewDeckCenterHiddenNotUserInteractiveWithTapToClose;
    self.viewDeck.leftController            = self.leftPanelController;
	self.viewDeck.delegate					= self;

	self.window.rootViewController			= self.viewDeck;

	self.leftActivator = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"nav-menu-icon.png"]
                                                          style:UIBarButtonItemStylePlain
                                                         target:self.viewDeck
                                                         action:@selector(toggleLeftView)];


    [self configureAppState];

    self.window.backgroundColor = [UIColor blackColor];
    [self.window makeKeyAndVisible];

	[[NSNotificationCenter defaultCenter] addObserverForName:kXTProfileValidityChangedNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
													  [self configureAppState];
												  }];

	dispatch_async(dispatch_get_global_queue(0, 0), ^{
		[[NAEffectsManager sharedInstance] generateThumbnailsFromImage:[UIImage imageNamed:@"thumbnail.jpg"]];
	});


    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
	// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
	// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
	// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
	// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

	[self.userCoverArtCache trimCache];
	[self.userProfilePicCache trimCache];

	//TODO: trim core data stuff
	//[self.managedObjectContext reset];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
	// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
	// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	// Saves changes in the application's managed object context before the application terminates.
	[self saveContext];
}

-(BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	DLog(@"openURL: %@, host:%@", url, url.host);

	//This handles login - it *should* work across in-app AND external safari!
	if([url.host isEqualToString:@"authcomplete"])
	{
		NSMutableDictionary *parameters = [[NSMutableDictionary alloc] init];
		if([[url.fragment componentsSeparatedByString:@"="] count] > 1)
		{
			[parameters setObject:[[url.fragment componentsSeparatedByString:@"="] objectAtIndex:1]
						   forKey:[[url.fragment componentsSeparatedByString:@"="] objectAtIndex:0]];
		}

		if([parameters objectForKey:@"access_token"])
        {
			DLog(@"access_token = %@", [parameters objectForKey:@"access_token"]);
			[[XTProfileController sharedInstance] loginWithToken:[parameters objectForKey:@"access_token"]];
        }
	}
	else if([url.host isEqualToString:@"showuser"])
	{
		DLog(@"SHOWUSER: %@", url.path);

		NSString *userID = [url.path substringFromIndex:1];
		XTProfileViewController * pvc = [[XTProfileViewController alloc] initWithUserID:userID];

		UINavigationController * temp = (UINavigationController*)self.viewDeck.centerController;

		[temp pushViewController:pvc
						animated:YES];
	}
	else if([url.host isEqualToString:@"showhashtag"])
	{
		DLog(@"showhashtag: %@", url.path);

		NSString *hashtag = [url.path substringFromIndex:1];

		XTHashTagViewController * htvc = [[XTHashTagViewController alloc] initWithHashtag:hashtag];

		UINavigationController * temp = (UINavigationController*)self.viewDeck.centerController;

		[temp pushViewController:htvc
						animated:YES];
	}
	else if([url.host isEqualToString:@"newpost"])
	{
		XTNewPostViewController * npvc = [[XTNewPostViewController alloc] init];

		[self.viewDeck.centerController presentViewController:[[UINavigationController alloc] initWithRootViewController:npvc]
													 animated:YES
												   completion:nil];

	}


	return YES;
}

#pragma mark - TMDiskCache things

-(TMDiskCache*)userProfilePicCache
{
	if(!_userProfilePicCache)
	{
		_userProfilePicCache = [[TMDiskCache alloc] initWithDirectoryName:@"userprofilepics"
															 andCacheSize:5];
	}

	return _userProfilePicCache;
}

-(TMDiskCache*)userCoverArtCache
{
	if(!_userCoverArtCache)
	{
		_userCoverArtCache = [[TMDiskCache alloc] initWithDirectoryName:@"usercoverart"
														   andCacheSize:20];
	}

	return _userCoverArtCache;
}


#pragma mark - view switching stuff

-(void)switchToViewController:(UIViewController*)vc
{
    if([self.viewDeck leftControllerIsOpen])
    {
        [self.viewDeck closeLeftViewBouncing:^(IIViewDeckController *controller) {
            self.viewDeck.centerController = [[UINavigationController alloc] initWithRootViewController:vc];
        }];
    }
    else
    {
		[self.viewDeck setCenterController:[[UINavigationController alloc] initWithRootViewController:vc]];
    }

	[[NSUserDefaults standardUserDefaults] setInteger:vc.tabBarItem.tag
											   forKey:@"visibleviewcontroller"];
	[[NSUserDefaults standardUserDefaults] synchronize];

    vc.navigationItem.leftBarButtonItem = self.leftActivator;
}

-(void)switchToMyTimelineView
{
	if(!self.myTimelineController)
	{
		self.myTimelineController = [[XTTimelineViewController alloc] init];
		self.myTimelineController.timelineMode = kMyTimelineMode;

	}
	[self switchToViewController:self.myTimelineController];
}

-(void)switchToGlobalTimelineView
{
	if(!self.globalTimelineController)
	{
		self.globalTimelineController = [[XTTimelineViewController alloc] init];
		self.globalTimelineController.timelineMode = kGlobalTimelineMode;
	}
	[self switchToViewController:self.globalTimelineController];
}

-(void)switchToMentionsTimelineView
{
	if(!self.mentionsTimelineController)
	{
		self.mentionsTimelineController = [[XTTimelineViewController alloc] init];
		self.mentionsTimelineController.timelineMode = kMentionsTimelineMode;
	}
	[self switchToViewController:self.mentionsTimelineController];
}

-(void)switchToProfileView
{
	XTProfileViewController * pvc = [[XTProfileViewController alloc] initWithUserID:[XTProfileController sharedInstance].profileUser.id];

	[self switchToViewController:pvc];
}

-(void)switchToSearchController
{
	if(!self.searchViewController)
	{
		self.searchViewController = [[XTSearchViewController alloc] init];
	}

	[self switchToViewController:self.searchViewController];
}

-(void)switchToSettingsView
{
	XTSettingsViewController *svc = [[XTSettingsViewController alloc] init];
	[self switchToViewController:svc];
}

-(void)switchToFeedbackView
{
	XTFeedbackViewController *fvc = [[XTFeedbackViewController alloc] init];
	[self switchToViewController:fvc];
}


#pragma mark - app startup configuration

-(void)logout
{
	[[XTProfileController sharedInstance] logout];

	self.myTimelineController		= nil;
	self.globalTimelineController	= nil;
	self.mentionsTimelineController = nil;

	// clear out all old data!
	[self resetPersistentStore];

}


-(void)configureAppState
{
	if([XTProfileController sharedInstance].isSessionValid)
	{
		self.viewDeck.enabled = YES;

		[self switchToMyTimelineView];

		//set up HTTP header for Auth

		//Adding an Authorization header (preferred) Add the following header to your request: : Bearer [access token] where [access token] is the value of the user's access token.

	}
	else
	{
		[self.viewDeck closeLeftView];
		self.viewDeck.enabled = NO;
		XTNoCredentialsViewController * ncvc = [[XTNoCredentialsViewController alloc] init];
		self.viewDeck.centerController = [[UINavigationController alloc] initWithRootViewController:ncvc];

		[[XTHTTPClient sharedClient] setDefaultHeader:@"Authorization"
												value:nil];

	}
}

#pragma mark - Core Data stack

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			// Replace this implementation with code to handle the error appropriately.
			// abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}



// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"xtendr" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

-(void)resetPersistentStore
{
	NSError *error = nil;

	_managedObjectModel		= nil;
	_managedObjectContext	= nil;

	for (NSPersistentStore *store in [_persistentStoreCoordinator persistentStores])
	{
		if (![_persistentStoreCoordinator removePersistentStore:store
														  error:&error])
		{
			DLog(@"Unresolved error %@, %@", error, [error userInfo]);
		}

		DLog(@"Deleting: %@", store.URL.absoluteString);

		if (![[NSFileManager defaultManager] removeItemAtURL:store.URL
													   error:&error])
		{
			DLog(@" %@, %@", error, [error userInfo]);
		}
	}

	// Delete the reference to non-existing store
	_persistentStoreCoordinator = nil;
}


// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }

    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"xtendr.sqlite"];

    NSError *error = nil;

again:

	_persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:@{	NSInferMappingModelAutomaticallyOption : [NSNumber numberWithBool:YES],
				   NSMigratePersistentStoresAutomaticallyOption : [NSNumber numberWithBool:YES]}
														   error:&error])
    {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);

		DLog(@"DELETING STORE AND RETRYING");
		NSError * error;

		if(![[NSFileManager defaultManager] removeItemAtURL:storeURL
													  error:&error])
		{
			DLog(@"ERROR DELETING STORE: %@", error);
		}

		goto again;
    }

    return _persistentStoreCoordinator;
}

- (void)syncDidSave:(NSNotification *)saveNotification
{
	if ([NSThread isMainThread]) {
		DLog(@"Syncing Save WE ARE main thread");
		[self.managedObjectContext mergeChangesFromContextDidSaveNotification:saveNotification];
	} else {
		DLog(@"Syncing Save on main thread");
		[self performSelectorOnMainThread:@selector(syncDidSave:)
							   withObject:saveNotification
							waitUntilDone:NO];
	}
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)applicationLibraryDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSURL *)applicationCacheDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
