//
//  MRMovieDetailsSimilarMoviesCell.h
//  MovieRama
//
//  Created by George Danikas on 05/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MRMovieDetailsSimilarMoviesCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

+ (MRMovieDetailsSimilarMoviesCell *)similarMoviesCell;

@end
