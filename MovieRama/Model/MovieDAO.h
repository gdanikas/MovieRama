//
//  MovieDAO.h
//  MovieRama
//
//  Created by George Danikas on 07/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface MovieDAO : NSObject

#pragma mark Initialization
+ (instancetype)DAO;

- (NSMutableArray *)syncModelWithAPIFetchedData:(NSArray *)data inTheaters:(NSNumber *)inTheaters forPage:(NSInteger)pageNum withMoc:(NSManagedObjectContext *)moc outputArray:(NSMutableArray *)outputArray;

// Delete old movies of the week with page result greater than given page
- (void)deleteMoviesWithPageGT:(NSInteger)pageNum withMoc:(NSManagedObjectContext *)moc;
- (void)deleteMoviesInTheaters:(NSNumber *)inTheaters withMoc:(NSManagedObjectContext *)moc;
@end
