//
//  Movie.m
//  MovieRama
//
//  Created by George Danikas on 04/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import "Movie.h"
#import "Actor.h"
#import "NSString+DateParsers.h"

@implementation Movie

- (void)updateModelWithAPIFetchedData:(NSDictionary *)dataDict {
    if (dataDict[@"id"] && ![dataDict[@"id"] isKindOfClass:[NSNull class]]) {
        if ([dataDict[@"id"] isKindOfClass:[NSNumber class]])
            self.movieId = dataDict[@"id"];
        else
            self.movieId = [NSNumber numberWithInteger:[dataDict[@"id"] integerValue]];
    }
    
    NSDictionary *releaseDatesDict = dataDict[@"release_dates"];
    if (releaseDatesDict != (NSDictionary *)[NSNull null]) {
        if (releaseDatesDict[@"theater"] && releaseDatesDict[@"theater"] != (NSString *) [NSNull null]) {
            self.releaseDate = [releaseDatesDict[@"theater"] parseDate];
            self.releaseDateType = NSLocalizedString(@"In Theaters", @"Release Date Types");
        }
        else if (releaseDatesDict[@"dvd"] && releaseDatesDict[@"dvd"] != (NSString *) [NSNull null]) {
            self.releaseDate = [releaseDatesDict[@"dvd"] parseDate];
            self.releaseDateType = @"DVD";
        }
    }
    
    if (dataDict[@"title"] && [dataDict[@"title"] isKindOfClass:[NSString class]])
        self.title = dataDict[@"title"];
    
    if (dataDict[@"synopsis"] && [dataDict[@"synopsis"] isKindOfClass:[NSString class]])
        self.synopsis = dataDict[@"synopsis"];
    
    if (dataDict[@"year"] && ![dataDict[@"year"] isKindOfClass:[NSNull class]]) {
        if ([dataDict[@"year"] isKindOfClass:[NSNumber class]])
            self.year = dataDict[@"year"];
        else
            self.year = [NSNumber numberWithInteger:[dataDict[@"year"] integerValue]];
    }
    
    if (dataDict[@"b_billDateStart"] && dataDict[@"b_billDateStart"] != (NSString *) [NSNull null])
        self.releaseDate = [dataDict[@"b_billDateStart"] parseDate];
    
    if (dataDict[@"runtime"] && ![dataDict[@"runtime"] isKindOfClass:[NSNull class]]) {
        if ([dataDict[@"runtime"] isKindOfClass:[NSNumber class]])
            self.duration = dataDict[@"runtime"];
        else
            self.duration = [NSNumber numberWithInteger:[dataDict[@"runtime"] integerValue]];
    }
    
    if (dataDict[@"mpaa_rating"] && [dataDict[@"mpaa_rating"] isKindOfClass:[NSString class]])
        self.rating = dataDict[@"mpaa_rating"];
    
    if (self.rating && [self.rating isEqualToString:@"Unrated"])
        self.rating = @"";
    
    NSDictionary *postersDict = dataDict[@"posters"];
    if (postersDict != (NSDictionary *)[NSNull null]) {
        if (postersDict[@"original"] && postersDict[@"original"] != (NSString *) [NSNull null])
            self.poster = postersDict[@"original"];
        else if (postersDict[@"detailed"] && postersDict[@"detailed"] != (NSString *) [NSNull null])
            self.poster = postersDict[@"detailed"];
        else if (postersDict[@"thumbnail"] && postersDict[@"thumbnail"] != (NSString *) [NSNull null])
            self.poster = postersDict[@"thumbnail"];
        else if (postersDict[@"profile"] && postersDict[@"profile"] != (NSString *) [NSNull null])
            self.poster = postersDict[@"profile"];
    }
    
    NSArray *genresArray = dataDict[@"genres"];
    if (genresArray != (NSArray *)[NSNull null]) {
        self.genres = [genresArray componentsJoinedByString:@" | "];
    }
    
    if (dataDict[@"studio"] && [dataDict[@"studio"] isKindOfClass:[NSString class]])
        self.studio = dataDict[@"studio"];
    
    NSArray *directorsArray = dataDict[@"abridged_directors"];
    NSMutableArray *namesDirectorsNArray = [NSMutableArray array];
    if (directorsArray != (NSArray *)[NSNull null]) {
        for (NSDictionary *directorDict in directorsArray) {
            if (directorDict[@"name"] && [directorDict[@"name"] isKindOfClass:[NSString class]])
                [namesDirectorsNArray addObject:directorDict[@"name"]];
        }
    }
    
    if (namesDirectorsNArray.count > 0)
        self.directors = [namesDirectorsNArray componentsJoinedByString:@", "];
}

- (NSString *)durationToString {
    NSUInteger minutes = self.duration.integerValue;
    
    // Check minutes
    if (minutes == 0) {
        return @"";
    } else if (minutes < 60) {
        return [NSString stringWithFormat:@"%ld %@", (long)minutes, NSLocalizedString(@"min", @"Units")];
    }
    
    NSInteger hours = minutes / 60;
    NSInteger minutesLeft = minutes % 60;
    if (minutesLeft == 0) {
        return [NSString stringWithFormat:@"%ld %@", (long)hours, NSLocalizedString(@"h", @"Units")];
    }
    
    return [NSString stringWithFormat:@"%ld %@ %ld %@", (long)hours, NSLocalizedString(@"h", @"Units"), (long)minutesLeft, NSLocalizedString(@"min", @"Units")];
}

@end
