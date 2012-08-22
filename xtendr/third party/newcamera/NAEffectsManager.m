//
//  NAEffectsManager.m
//  photovidcap
//
//  Created by Tony Million on 01/08/2012.
//  Copyright (c) 2012 Narrato. All rights reserved.
//

#import "NAEffectsManager.h"

#import "NAClassicImageEffect.h"
#import "NABluesImageEffect.h"
#import "NAToasterEffect.h"
#import "NAWonderEffect.h"
#import "NAArbusEffect.h"
#import "NAOrlandoEffect.h"
#import "NAZProEffect.h"
#import "NASplitTone.h"
@interface NAEffectsManager ()

@property(strong) NSMutableArray		*effectsArray;
@property(strong) NSURL					*diskCacheURL;


@end

@implementation NAEffectsManager


static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight)
{
    float fw, fh;
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    CGContextSaveGState(context);
    CGContextTranslateCTM (context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM (context, ovalWidth, ovalHeight);
    fw = CGRectGetWidth (rect) / ovalWidth;
    fh = CGRectGetHeight (rect) / ovalHeight;
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

-(UIImage *)makeRoundCornerImage:(UIImage*)img : (int) cornerWidth : (int) cornerHeight
{
	UIImage * newImage = nil;

	if( nil != img)
	{
		@autoreleasepool {
			int w = img.size.width;
			int h = img.size.height;

			CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
			CGContextRef context = CGBitmapContextCreate(NULL, w, h, 8, 4 * w, colorSpace, kCGImageAlphaPremultipliedFirst);

			CGContextBeginPath(context);
			CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
			addRoundedRectToPath(context, rect, cornerWidth, cornerHeight);
			CGContextClosePath(context);
			CGContextClip(context);

			CGContextDrawImage(context, CGRectMake(0, 0, w, h), img.CGImage);

			CGImageRef imageMasked = CGBitmapContextCreateImage(context);
			CGContextRelease(context);
			CGColorSpaceRelease(colorSpace);

			newImage = [UIImage imageWithCGImage:imageMasked];
			CGImageRelease(imageMasked);
		}
	}

    return newImage;
}


+(NAEffectsManager*)sharedInstance
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
		NSURL * cacheURL = [[[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory
																   inDomains:NSUserDomainMask] lastObject];

		self.diskCacheURL   = [cacheURL URLByAppendingPathComponent:@"effectThumbs/"];
		NSError * error;
		if(![self.diskCacheURL checkResourceIsReachableAndReturnError:&error])
		{
			[[NSFileManager defaultManager] createDirectoryAtURL:self.diskCacheURL
									 withIntermediateDirectories:YES
													  attributes:nil
														   error:NULL];
		}


		self.effectsArray = [NSMutableArray arrayWithCapacity:5];

		[self.effectsArray addObject:[NAImageEffect class]];
		[self.effectsArray addObject:[NAZProEffect class]];
		[self.effectsArray addObject:[NAWonderEffect class]];
		[self.effectsArray addObject:[NAOrlandoEffect class]];
		[self.effectsArray addObject:[NAToasterEffect class]];
		[self.effectsArray addObject:[NAClassicImageEffect class]];
		[self.effectsArray addObject:[NABluesImageEffect class]];
		[self.effectsArray addObject:[NAArbusEffect class]];
		[self.effectsArray addObject:[NASplitTone class]];


	}

	return self;
}

-(void)generateThumbnailsFromImage:(UIImage*)startImage
{
	CIImage * startciImage	= [CIImage imageWithCGImage:startImage.CGImage];
	CIContext * context		= [CIContext contextWithOptions:nil];

	for (Class temp in self.effectsArray)
	{
		NSURL * fullthing = [self.diskCacheURL URLByAppendingPathComponent:[temp identifier]];

		if([[NSFileManager defaultManager] fileExistsAtPath:[fullthing path]])
		{
		}
		else
		{

			@autoreleasepool {
				NAImageEffect * effect = [[temp alloc] init];

				CIImage * result = [effect processImage:startciImage];

				CGImageRef  imgRef =   [context createCGImage:result fromRect:result.extent];

				UIImage     *newimg = [UIImage imageWithCGImage:imgRef];
				CGImageRelease(imgRef);

				[effect finishProcessing];




				NSData * data = UIImagePNGRepresentation([self makeRoundCornerImage:newimg :15 :15]);

				NSError * err;
				if(![data writeToURL:fullthing
							 options:NSDataWritingAtomic
							   error:&err])
				{
					DLog(@"ERROR WRITING THUMBNAIL: %@, %@", fullthing, err);
				}
				else
				{
				}
			}
		}
	}
}

-(void)deleteThumbnails
{
	NSDirectoryEnumerator * enumerator = [[NSFileManager defaultManager] enumeratorAtURL:self.diskCacheURL
															  includingPropertiesForKeys:[NSArray array]
																				 options:0
																			errorHandler:^BOOL(NSURL *url, NSError *error) {
																				DLog(@"Error: %@", error);
																				return YES;
																			}];

	for (NSURL *url in enumerator)
	{
		[[NSFileManager defaultManager] removeItemAtURL:url error:nil];
	}
}


-(NSUInteger)count
{
	return self.effectsArray.count;
}

-(NAImageEffect*)effectAtIndex:(NSUInteger)index
{
	if(index < self.effectsArray.count)
	{
		return [[[self.effectsArray objectAtIndex:index] alloc] init];
	}

	return nil;
}

-(NAImageEffect*)effectWithIdentifier:(NSString*)identifier
{
	if(identifier == nil)
	{
		return [self effectAtIndex:0];
	}

	for (Class temp in self.effectsArray) {
		if([identifier isEqual:[temp identifier]])
		{
			return [[temp alloc] init];
		}
	}

	return nil;
}

-(NSString*)nameForEffectAtIndex:(NSUInteger)index
{
	if(index < self.effectsArray.count)
	{
		return [[self.effectsArray objectAtIndex:index] name];
	}

	return nil;
}

-(NSString*)identifierForEffectAtIndex:(NSUInteger)index
{
	if(index < self.effectsArray.count)
	{
		return [[self.effectsArray objectAtIndex:index] identifier];
	}

	return nil;
}

-(UIImage*)thumbnnailForEffectAtIndex:(NSUInteger)index
{
	NSURL * fullthing = [self.diskCacheURL URLByAppendingPathComponent:[self identifierForEffectAtIndex:index]];

	UIImage * diskBased = [UIImage imageWithData:[NSData dataWithContentsOfURL:fullthing]];
	
	if(diskBased)
	{
		return diskBased;
	}
	
	return nil;
}



@end
