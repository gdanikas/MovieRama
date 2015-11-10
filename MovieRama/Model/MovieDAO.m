//
//  MovieDAO.m
//  MovieRama
//
//  Created by George Danikas on 07/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import "MovieDAO.h"
#import "Movie.h"
#import "Actor.h"

@implementation MovieDAO

#pragma mark Initialization

+ (instancetype)DAO {
    static dispatch_once_t predicate;
    static MovieDAO *instance = nil;
    
    dispatch_once(&predicate, ^{
        instance = [MovieDAO new];
    });
    
    return instance;
}

- (NSMutableArray *)syncModelWithAPIFetchedData:(NSArray *)data inTheaters:(NSNumber *)inTheaters forPage:(NSInteger)pageNum withMoc:(NSManagedObjectContext *)moc outputArray:(NSMutableArray *)outputArray {
    // Sync API fetched data with CD
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Movie"];
    if (pageNum > 0) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"resultPage = %@", [NSNumber numberWithInteger:pageNum]];
        [fetchRequest setPredicate:predicate];
    }
    
    NSMutableArray *storedObjects = [NSMutableArray arrayWithArray:[moc executeFetchRequest:fetchRequest error:nil]];
    
    for (NSDictionary *movieDict in data) {
        // Check if current fetched Movie already exist in DB
        NSNumber *movieID;
        if (movieDict[@"id"] && ![movieDict[@"id"] isKindOfClass:[NSNull class]]) {
            if ([movieDict[@"id"] isKindOfClass:[NSNumber class]])
                movieID = movieDict[@"id"];
            else
                movieID = [NSNumber numberWithInteger:[movieDict[@"id"] integerValue]];
        }
        
        BOOL found = NO;
        for (Movie *storedObject in storedObjects) {
            if (storedObject.movieId.integerValue == movieID.integerValue) {
                // Fetched Movie found in Stored ones
                found = YES;
                [storedObject updateModelWithAPIFetchedData:movieDict];
                
                if (pageNum > 0)
                    storedObject.resultPage = [NSNumber numberWithInteger:pageNum];
                
                if (![outputArray containsObject:storedObject])
                    [outputArray addObject:storedObject];
                else
                    storedObject.fetchedAt = [NSDate date];
                
                // This Movie is still present, remove it from stored Movies Array
                [storedObjects removeObject:storedObject];
                break;
            }
        }
        
        // If fetched Movie does NOT exist, create and add it
        if (!found) {
            Movie *newMovie = (Movie *)[NSEntityDescription insertNewObjectForEntityForName:@"Movie" inManagedObjectContext:moc];
            [newMovie updateModelWithAPIFetchedData:movieDict];
            newMovie.inTheaters = inTheaters;
            newMovie.fetchedAt = [NSDate date];
            
            if (pageNum > 0)
                newMovie.resultPage = [NSNumber numberWithInteger:pageNum];
            
            NSArray *movieCastArray = movieDict[@"abridged_cast"];
            if (movieCastArray != (NSArray *)[NSNull null]) {
                NSMutableArray *castNames = [NSMutableArray array];
                for (NSDictionary *castItem in movieCastArray) {
                    Actor *newActor = (Actor *)[NSEntityDescription insertNewObjectForEntityForName:@"Actor" inManagedObjectContext:moc];
                    [newActor updateModelWithAPIFetchedData:castItem];
                    newActor.movie = newMovie;
                    
                    [castNames addObject:newActor.name];
                }
                
                if (castNames.count > 0) {
                    // Up to 3 actors
                    castNames = [[castNames subarrayWithRange:NSMakeRange(0, MIN(3, castNames.count))] mutableCopy];
                    newMovie.cast = [castNames componentsJoinedByString:@", "];
                }
            }
            
            [outputArray addObject:newMovie];
        }
    }
    
    if (pageNum > 0) {
        // The remaining stored Movies for current page are not present anymore, should be removed from DB
        for (Movie *storedObject in storedObjects) {
            [moc deleteObject:storedObject];
            [outputArray removeObject:storedObject];
        }
    }
    
    // Save context
    [moc save:nil];
    
    return outputArray;
}

- (void)deleteMoviesWithPageGT:(NSInteger)pageNum withMoc:(NSManagedObjectContext *)moc {
    // Sync API fetched data with CD
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Movie"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"resultPage > %@", [NSNumber numberWithInteger:pageNum]];
    [fetchRequest setPredicate:predicate];
    
    NSMutableArray *storedObjects = [NSMutableArray arrayWithArray:[moc executeFetchRequest:fetchRequest error:nil]];
    
    for (Movie *storedObject in storedObjects) {
        [moc deleteObject:storedObject];
    }
    
    // Save context
    [moc save:nil];
}

- (void)deleteMoviesInTheaters:(NSNumber *)inTheaters withMoc:(NSManagedObjectContext *)moc {
    // Sync API fetched data with CD
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Movie"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTheaters = %@", inTheaters];
    [fetchRequest setPredicate:predicate];
    
    NSMutableArray *storedObjects = [NSMutableArray arrayWithArray:[moc executeFetchRequest:fetchRequest error:nil]];
    
    for (Movie *storedObject in storedObjects) {
        [moc deleteObject:storedObject];
    }
    
    // Save context
    [moc save:nil];
}

@end
