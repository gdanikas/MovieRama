//
//  Actor.m
//  MovieRama
//
//  Created by George Danikas on 06/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import "Actor.h"
#import "Movie.h"

@implementation Actor

- (void)updateModelWithAPIFetchedData:(NSDictionary *)dataDict {
    if (dataDict[@"name"] && [dataDict[@"name"] isKindOfClass:[NSString class]])
        self.name = dataDict[@"name"];
    
    NSArray *charactersArray = dataDict[@"characters"];
    if (charactersArray != (NSArray *)[NSNull null]) {
        self.characters = [charactersArray componentsJoinedByString:@", "];
    }
}

@end
