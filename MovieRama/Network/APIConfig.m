//
//  APIConfig.m
//  MovieRama
//
//  Created by George Danikas on 04/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import "APIConfig.h"

#define kConfigHostKey @"host"
#define kConfigVersionKey @"version"
#define kConfigApiKey @"api_key"

@implementation APIConfig

#pragma mark Initialization
+ (instancetype)config {
    static dispatch_once_t predicate;
    static APIConfig *instance = nil;
    
    dispatch_once(&predicate, ^{
        instance = [[APIConfig alloc] init];
    });
    
    return instance;
}

- (id)init {
    self = [super init];
    if (self){
        NSBundle* bundle = [NSBundle bundleForClass:[self class]];
        NSDictionary *config = [[NSDictionary alloc]initWithContentsOfFile:[bundle pathForResource:@"APIConfig" ofType:@"plist"]];
        
        _host = config[kConfigHostKey];
        _version = config[kConfigVersionKey];
        _apiKey = config[kConfigApiKey];
    }
    
    return self;
}

@end
