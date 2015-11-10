//
//  APIConfig.h
//  MovieRama
//
//  Created by George Danikas on 04/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface APIConfig : NSObject

+ (instancetype)config;

@property (nonatomic, copy, readonly) NSString* host;
@property (nonatomic, copy, readonly) NSString* version;
@property (nonatomic, copy, readonly) NSString* apiKey;

@end
