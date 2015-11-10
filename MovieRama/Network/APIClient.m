//
//  APIClient.m
//  MovieRama
//
//  Created by George Danikas on 04/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import "APIClient.h"
#import "APIConfig.h"
#import "Reachability.h"

NSString *const AppErrorDomain = @"com.gdanikas.ios.MovieRama";

@interface APIClient ()

@property (readwrite, nonatomic, strong) NSURL *apiURL;
@property (readwrite, nonatomic, strong) NSURLSession *session;

@end

@implementation APIClient

#pragma mark Initialization

+ (instancetype)client {
    static dispatch_once_t predicate;
    static APIClient *instance = nil;
    
    dispatch_once(&predicate, ^{
        instance = [[APIClient alloc] init];
    });
    
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    
     // Ensure terminal slash for apiURL path, so that NSURL +URLWithString:relativeToURL: works as expected
    NSURL *url = [NSURL URLWithString:[APIConfig config].host];
    if ([[url path] length] > 0 && ![[url absoluteString] hasSuffix:@"/"]) {
        url = [url URLByAppendingPathComponent:@""];
    }
    
    self.apiURL = url;
    
    // Initialize Session Configuration
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPAdditionalHeaders = @{@"Accept": @"application/json"};
    configuration.timeoutIntervalForRequest = 30.0;
    configuration.timeoutIntervalForResource = 60.0;
    configuration.HTTPMaximumConnectionsPerHost = 5;
    
    self.session = [NSURLSession sessionWithConfiguration:configuration];
    return self;
}


- (BOOL)checkReachability:(NSError **)error {
    Reachability *reachTest = [Reachability reachabilityWithHostname:@"www.apple.com"];
    NetworkStatus internetStatus = [reachTest currentReachabilityStatus];
    
    if (internetStatus == NotReachable) {
        NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
        [userInfo setValue:NSLocalizedString(@"Network Access not available", @"") forKey:NSLocalizedDescriptionKey];
        
        *error = [[NSError alloc] initWithDomain:AppErrorDomain code:AppErrorCodeNetworkUnreachable userInfo:userInfo];
        return NO;
    }
    
    return YES;
}

- (NSError *)createHttpResponseErrorWithCode:(NSInteger)errorCode {
    NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
    [userInfo setValue:NSLocalizedString(@"Could not complete operation. Please try again later!" , @"") forKey:NSLocalizedDescriptionKey];
    
    NSError *error = [[NSError alloc] initWithDomain:AppErrorDomain code:errorCode userInfo:userInfo];
    
    return error;
}

#pragma mark HTTP Requests

- (NSURLSessionDataTask *)requestWithMethod:(NSString *)method
                                       path:(NSString *)requestPath
                                 parameters:(NSData *)parameters
                                    success:(void (^)(NSURLSessionDataTask *task, id data, id responseObject))success
                                    failure:(void (^)(NSURLSessionDataTask *task, NSError *error))failure
{
    NSError *networkError;
    if (![self checkReachability:&networkError]) {
        failure(nil, networkError);
        return nil;
    }
    
    NSString *URLString = [[NSURL URLWithString:requestPath relativeToURL:self.apiURL] absoluteString];
    NSURL *url = [NSURL URLWithString:URLString];
    
    // Intialize URL request
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:method.uppercaseString];
    [request setHTTPBody:parameters];
    [request setHTTPShouldHandleCookies:NO];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSURLSessionDataTask *task = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *responseObject, NSError *error) {
        if (error) {
            if (failure) {
                failure(task, error);
            }
        } else {
            if (success) {
                NSHTTPURLResponse *httpResp = (NSHTTPURLResponse *)responseObject;
                
                // Bad Request or Unauthorized
                if (httpResp.statusCode == 400 || httpResp.statusCode == 403) {
                    if (!error) {
                        NSMutableDictionary* userInfo = [NSMutableDictionary dictionary];
                        [userInfo setValue:NSLocalizedString(@"Could not complete operation. Please try again later!", @"") forKey:NSLocalizedDescriptionKey];
                        
                        error = [[NSError alloc] initWithDomain:AppErrorDomain code:httpResp.statusCode userInfo:userInfo];
                    }
                    
                    failure(nil, error);
                }
                else {
                    success(task, data, responseObject);
                }
            }
        }
    }];
    
    [task resume];
    return task;
}

#pragma mark Methods

- (NSURLSessionDataTask *)getRequest:(RequestType)requestType withParameters:(NSDictionary *)parameters withBlock:(APIResponseBlock)block {
    
    NSString *endpoint;
    switch (requestType) {
        case RequestType_InTheaters:
            endpoint = @"lists/movies/in_theaters.json";
            break;
            
        case RequestType_MoviesInfo:
            endpoint = @"movies/:id.json";
            break;
            
        case RequestType_MoviesReviews:
            endpoint = @"movies/:id/reviews.json";
            break;
            
        case RequestType_MoviesSimilar:
            endpoint = @"movies/:id/similar.json";
            break;
            
        case RequestType_MoviesSearch:
            endpoint = @"movies.json";
            break;
            
        default:
            break;
    }
    
    // Append api key
    endpoint = [endpoint stringByAppendingString:[NSString stringWithFormat:@"?apikey=%@", [APIConfig config].apiKey]];

    // Append rest of url parameters
    if (parameters) {
        for (id key in parameters) {
            // Check if parameter key applies to endpoint URL format
            if ([key hasPrefix:@":"] && [endpoint containsString:key])
                endpoint = [endpoint stringByReplacingOccurrencesOfString:key withString:[parameters valueForKey:key]];
            else
                endpoint = [endpoint stringByAppendingString:[NSString stringWithFormat:@"&%@=%@", key, [[parameters valueForKey:key] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        }
    }
    
    return [self requestWithMethod:@"GET"
                              path:endpoint
                        parameters:nil
                           success:^(NSURLSessionDataTask *task, id data, id responseObject) {
                               NSHTTPURLResponse *httpResp = (NSHTTPURLResponse*) responseObject;
                               
                               // Success
                               if (httpResp.statusCode == 200) {
                                   NSError *jsonError;
                                   NSDictionary *jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
                                   NSLog(@"Response JSON: %@", jsonDictionary);
                                   
                                   if (!jsonError) {
                                       if (block) {
                                           block(jsonDictionary, nil);
                                       }
                                   }
                                   else {
                                       // JSON Parse ERROR
                                       if (block) {
                                           block(nil, jsonError);
                                       }
                                   }

                               } else {
                                   // HTTP Response status code: failed
                                   NSError *error = [self createHttpResponseErrorWithCode:httpResp.statusCode];
                                   if (block) {
                                       block(nil, error);
                                   }
                               }
        
                           } failure:^(NSURLSessionDataTask *task, NSError *error) {
                               if (block) {
                                   block(nil, error);
                               }
                           }];
    
}

@end
