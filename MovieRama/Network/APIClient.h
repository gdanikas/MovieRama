//
//  APIClient.h
//  MovieRama
//
//  Created by George Danikas on 04/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    // ====> Network unreachable related Error Codes:
    //Code: 100     "Network Unreachable"
    AppErrorCodeNetworkUnreachable = 100
    
} AppErrorCode;

typedef enum {
    // ---- GET ----
    
    // Movie Lists
    RequestType_InTheaters,
    
    // Detailed Info
    RequestType_MoviesInfo,
    RequestType_MoviesReviews,
    RequestType_MoviesSimilar,
    
    // Search
    RequestType_MoviesSearch
} RequestType;

@interface APIClient : NSObject

typedef void (^APIResponseBlock)(id response, NSError *error);
- (NSURLSessionDataTask *)getRequest:(RequestType)requestType withParameters:(NSDictionary *)parameters withBlock:(APIResponseBlock)block;

#pragma mark Initialization
+ (instancetype)client;

@end
