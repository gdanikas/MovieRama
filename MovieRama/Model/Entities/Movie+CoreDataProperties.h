//
//  Movie+CoreDataProperties.h
//  MovieRama
//
//  Created by George Danikas on 07/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Movie.h"

NS_ASSUME_NONNULL_BEGIN

@interface Movie (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *cast;
@property (nullable, nonatomic, retain) NSString *directors;
@property (nullable, nonatomic, retain) NSNumber *duration;
@property (nullable, nonatomic, retain) NSDate *fetchedAt;
@property (nullable, nonatomic, retain) NSString *genres;
@property (nullable, nonatomic, retain) NSNumber *inTheaters;
@property (nullable, nonatomic, retain) NSNumber *movieId;
@property (nullable, nonatomic, retain) NSString *poster;
@property (nullable, nonatomic, retain) NSString *rating;
@property (nullable, nonatomic, retain) NSDate *releaseDate;
@property (nullable, nonatomic, retain) NSString *releaseDateType;
@property (nullable, nonatomic, retain) NSNumber *sortOrder;
@property (nullable, nonatomic, retain) NSString *studio;
@property (nullable, nonatomic, retain) NSString *synopsis;
@property (nullable, nonatomic, retain) NSString *title;
@property (nullable, nonatomic, retain) NSNumber *year;
@property (nullable, nonatomic, retain) NSNumber *resultPage;
@property (nullable, nonatomic, retain) NSSet<Actor *> *actors;
@property (nullable, nonatomic, retain) NSSet<Movie *> *similarMovies;

@end

@interface Movie (CoreDataGeneratedAccessors)

- (void)addActorsObject:(Actor *)value;
- (void)removeActorsObject:(Actor *)value;
- (void)addActors:(NSSet<Actor *> *)values;
- (void)removeActors:(NSSet<Actor *> *)values;

- (void)addSimilarMoviesObject:(Movie *)value;
- (void)removeSimilarMoviesObject:(Movie *)value;
- (void)addSimilarMovies:(NSSet<Movie *> *)values;
- (void)removeSimilarMovies:(NSSet<Movie *> *)values;

@end

NS_ASSUME_NONNULL_END
