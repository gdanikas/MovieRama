//
//  MRSimilarMoviesCollectionCell.h
//  MovieRama
//
//  Created by George Danikas on 05/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MRSimilarMoviesCollectionCell : UICollectionViewCell

@property (weak, nonatomic) IBOutlet UIImageView *posterImageView;

+ (MRSimilarMoviesCollectionCell *)similarMoviesCollectionCell;

@end
