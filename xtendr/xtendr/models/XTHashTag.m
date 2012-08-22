//
//  XTHashTag.m
//  xtendr
//
//  Created by Tony Million on 21/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import "XTHashTag.h"

/*
"hashtags": [{
    "name": "newsocialnetwork",
    "pos": 34,
    "len": 17
}]
 */

@implementation XTHashTag

-(id)initWithAttributes:(NSDictionary*)attributes
{
	self = [super init];
	if(self)
	{
		//TODO: error checking here pls
		_name	= [attributes objectForKey:@"name"];

		NSUInteger pos = [[attributes objectForKey:@"pos"] unsignedIntegerValue];
		NSUInteger len = [[attributes objectForKey:@"len"] unsignedIntegerValue];

		_range	= NSMakeRange(pos, len);
	}

	return self;
}


@end
