//
//  Actor+CoreDataProperties.h
//  MovieRama
//
//  Created by George Danikas on 06/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

#import "Actor.h"

NS_ASSUME_NONNULL_BEGIN

@interface Actor (CoreDataProperties)

@property (nullable, nonatomic, retain) NSString *name;
@property (nullable, nonatomic, retain) NSString *characters;
@property (nullable, nonatomic, retain) Movie *movie;

@end

NS_ASSUME_NONNULL_END
