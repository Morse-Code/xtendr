//
//  XTHashTag.h
//  xtendr
//
//  Created by Tony Million on 21/08/2012.
//  Copyright (c) 2012 Tony Million. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XTHashTag : NSObject

@property(readonly) NSString	*name;
@property(readonly) NSRange		range;

-(id)initWithAttributes:(NSDictionary*)attributes;

@end
