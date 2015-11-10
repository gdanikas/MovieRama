//
//  Movie.h
//  MovieRama
//
//  Created by George Danikas on 04/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Actor;

NS_ASSUME_NONNULL_BEGIN

@interface Movie : NSManagedObject

- (void)updateModelWithAPIFetchedData:(NSDictionary *)dataDict;
- (NSString *)durationToString;

@end

NS_ASSUME_NONNULL_END

#import "Movie+CoreDataProperties.h"
