//
//  Actor.h
//  MovieRama
//
//  Created by George Danikas on 06/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Movie;

NS_ASSUME_NONNULL_BEGIN

@interface Actor : NSManagedObject

- (void)updateModelWithAPIFetchedData:(NSDictionary *)dataDict;

@end

NS_ASSUME_NONNULL_END

#import "Actor+CoreDataProperties.h"
