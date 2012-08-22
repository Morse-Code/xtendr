//
//  UIImage+NetworkLoad.m
//  xtendr
//
//  Created by Tony Million on 09/06/2012.
//  Copyright (c) 2012 OmniTyke. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

#import "UIImageView+NetworkLoad.h"
#import "TMDiskCache.h"

@implementation UIImage (NetworkLoad)

+(UIImage*)imageWithDataImmediate:(NSData*)data
{
    if(!data)
        return nil;
    
    UIImage *decompressedImage;
    @autoreleasepool {
        UIImage *image = [[UIImage alloc] initWithData:data];
        if(!image)
            return nil;
        
        CGImageRef imageRef = [image CGImage];
        CGRect rect = CGRectMake(0.f, 0.f, CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
        CGContextRef bitmapContext = CGBitmapContextCreate(NULL,
                                                           rect.size.width,
                                                           rect.size.height,
                                                           CGImageGetBitsPerComponent(imageRef),
                                                           CGImageGetBytesPerRow(imageRef),
                                                           CGImageGetColorSpace(imageRef),
                                                           CGImageGetBitmapInfo(imageRef)
                                                           );
		if(!bitmapContext)
		{
			return image;
		}
        CGContextDrawImage(bitmapContext, rect, imageRef);
        CGImageRef decompressedImageRef = CGBitmapContextCreateImage(bitmapContext);
        
        decompressedImage = [UIImage imageWithCGImage:decompressedImageRef];
        CGImageRelease(decompressedImageRef);
        CGContextRelease(bitmapContext);
        
    }
    return decompressedImage;   
}

@end


NSString *const kUIImageViewNetworkLoadDidStartNotification     = @"kUIImageViewNetworkLoadDidStartNotification";
NSString *const kUIImageViewNetworkLoadDidFinishNotification    = @"kUIImageViewNetworkLoadDidFinishNotification";


static char * const kURLAssociationKey      = "kURLAssociationKey";
static char * const kURLSpinnerKey          = "kURLSpinnerKey";
static char * const kURLFinalURLKey         = "kURLFinalURLKey";

@implementation UIImageView (NetworkLoad)

@dynamic finalURL;
@dynamic downloadingURL;

+(NSOperationQueue*)downloadOperationQueue
{
    static NSOperationQueue * downloadQueue;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadQueue = [[NSOperationQueue alloc] init];
        downloadQueue.name = @"com.tonymillion.UIImageViewNetworkLoadQueue";
    });
    
    return downloadQueue;
}

+(NSCache*)downloadCache
{
    static NSCache * downloadCache;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        downloadCache = [[NSCache alloc] init];
        downloadCache.name = @"com.tonymillion.UIImageViewNetworkLoadCache";
    });
    
    return downloadCache;
}

-(UIActivityIndicatorView*)activityIndicator
{
    ///////////////////////////////////////////////////
    //
    // if this view has no activity indicator, add one!
    //
    UIActivityIndicatorView * actview = (UIActivityIndicatorView *)objc_getAssociatedObject(self, kURLSpinnerKey);
    if(!actview)
    {
        actview = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        [self addSubview:actview];
        
        objc_setAssociatedObject(self,
                                 kURLSpinnerKey,
                                 actview,
                                 OBJC_ASSOCIATION_RETAIN);
        
        actview.frame               = self.bounds;
        actview.autoresizingMask    = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        [actview stopAnimating];
    }
    
    actview.frame               = self.bounds;
    
    return actview;
}

-(void)setImageAnimated:(UIImage *)image
{
    CATransition *animation = [CATransition animation];
    animation.duration = 0.188;
    animation.type = kCATransitionFade;
    [[self layer] addAnimation:animation forKey:@"imageFade"];
    [self setImage:image];
}


-(void)setFinalURL:(NSURL*)url
{
    objc_setAssociatedObject(self,
                             kURLFinalURLKey,
                             url,
                             OBJC_ASSOCIATION_RETAIN);
}

-(NSURL*)finalURL
{
    return objc_getAssociatedObject(self, kURLFinalURLKey);
}


-(void)setDownloadingURL:(NSURL *)downloadingURL
{
    objc_setAssociatedObject(self,
                             kURLAssociationKey,
                             downloadingURL,
                             OBJC_ASSOCIATION_RETAIN);
}

-(NSURL*)downloadingURL
{
    return objc_getAssociatedObject(self, kURLAssociationKey);
}


-(void)loadWithRequest:(NSMutableURLRequest*)request
      placeholderImage:(UIImage *)placeholderImage
			 fromCache:(TMDiskCache*)cache
{
	self.image = placeholderImage;

    ///////////////////////////////////////////////////
    //
    // see if we have this in the cache as a UIImage
    //
    UIImage * cachedImage = [[UIImageView downloadCache] objectForKey:request.URL.absoluteString];
    if(cachedImage)
    {
        if([cachedImage isKindOfClass:[UIImage class]])
        {
            self.downloadingURL = nil;            
            self.finalURL       = request.URL;
            
            
            // Dont animate here, we can set the image immediately and haven't even loaded the placeholder
            [self setImage:cachedImage];
            [[self activityIndicator] stopAnimating];
            
            return;
        }
    }

	///////////////////////////////////////////////////
    //
    // finally, download it, I suppose
    //

    @synchronized(self)
    {
        self.downloadingURL = request.URL;
        self.finalURL = nil;
    }

    ///////////////////////////////////////////////////
    //
    // before we download it see if we have it in the URL cache
    //
    // we dont do it any more, but might in the future!
    if(cache)
	{
		NSData * data = [cache dataForURL:request.URL];
		if(data)
		{

			dispatch_async(dispatch_get_global_queue(0, 0), ^{
				UIImage * remoteImage = [UIImage imageWithDataImmediate:data];

				if(remoteImage)
				{
					dispatch_async(dispatch_get_main_queue(), ^{

						if(![self.downloadingURL.absoluteString isEqualToString:request.URL.absoluteString])
						{
							// drop out if they dont match, means another image is being downloaded!
							return;
						}

						[[self activityIndicator] stopAnimating];
						[self setImageAnimated:remoteImage];

						self.downloadingURL = nil;

					});

					[[UIImageView downloadCache] setObject:remoteImage
													forKey:request.URL.absoluteString
													  cost:50];

					self.finalURL = request.URL;

				}
			});
			
			return;
		}
	}


    ///////////////////////////////////////////////////
    //
    // tell the watchers
    //

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kUIImageViewNetworkLoadDidStartNotification
                                                            object:self];
        [[self activityIndicator] startAnimating];

        [self setImage:placeholderImage];
    });
    
    ///////////////////////////////////////////////////
    //
    // Network
    //
    
    [NSURLConnection sendAsynchronousRequest:request 
                                       queue:[UIImageView downloadOperationQueue]
                           completionHandler:^(NSURLResponse *response, NSData *remoteData, NSError *error) {
                               
                               @synchronized(self)
                               {
								   NSHTTPURLResponse * httpResponse = (NSHTTPURLResponse *)response;
                                   ///////////////////////////////////////////////////
                                   //
                                   // first things first, tell the watchers the network IO has finished
                                   //
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       [[NSNotificationCenter defaultCenter] postNotificationName:kUIImageViewNetworkLoadDidFinishNotification
                                                                                           object:self];
                                   });
                                   
    
                                   // check to see if the download was "cancelled"
                                   if(!self.downloadingURL)
                                       return;
                                   
                                   if(![self.downloadingURL.absoluteString isEqualToString:request.URL.absoluteString])
                                   {
                                       // drop out if they dont match, means another image is being downloaded!
                                       return;
                                   }
                                   
                                   
                                   // first things first, tell the watchers the network IO has finished
                                   dispatch_async(dispatch_get_main_queue(), ^{
                                       [[self activityIndicator] stopAnimating];
                                   });
                                   
                                   if(remoteData && httpResponse.statusCode < 300)
                                   {
                                       UIImage * remoteImage = [UIImage imageWithDataImmediate:remoteData];

                                       if(remoteImage)
                                       {                                       
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               [self setImageAnimated:remoteImage];
                                           });
                                           
                                           [[UIImageView downloadCache] setObject:remoteImage 
                                                                           forKey:request.URL.absoluteString
                                                                             cost:50];
                                           
                                           self.finalURL = request.URL;
                                       }
                                   }
                                   else 
                                   {
                                       //TODO: have an error image? - too much?
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           [self setImageAnimated:nil];
                                       });
                                       
                                       //possibly NIL
                                       self.finalURL = request.URL;
                                   }
								   
								   if(cache)
								   {
									   dispatch_async(dispatch_get_global_queue(0, 0), ^{
										   [cache setData:remoteData forURL:request.URL];
									   });
								   }
                                   
                                   // clear associated URL pls
                                   self.downloadingURL = nil;
                               }
                           }];
}

-(void)loadFromURL:(NSURL *)url 
  placeholderImage:(UIImage *)placeholderImage
		 fromCache:(TMDiskCache*)cache

{
    
    if(!url || [url isKindOfClass:[NSNull class]])
    {
        @synchronized(self)
        {
            self.downloadingURL = nil;
            self.finalURL       = nil;
            [self setImage:placeholderImage];
            [[self activityIndicator] stopAnimating];
        }
        return;
    }
    
    
    //get the URL we're associated with!
    if([self.finalURL.absoluteString isEqual:url.absoluteString])
    {
        self.downloadingURL = nil;
        
        return;
    }
    
    NSMutableURLRequest * request = [NSMutableURLRequest requestWithURL:url];
    
    [self loadWithRequest:request 
         placeholderImage:placeholderImage
				fromCache:cache];
}

@end
