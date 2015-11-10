//
//  MRSimilarMoviesCollectionCell.m
//  MovieRama
//
//  Created by George Danikas on 05/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import "MRSimilarMoviesCollectionCell.h"

@implementation MRSimilarMoviesCollectionCell

+ (MRSimilarMoviesCollectionCell *)similarMoviesCollectionCell {
    return [[[NSBundle mainBundle] loadNibNamed:@"MRSimilarMoviesCollectionCell" owner:self options:nil] objectAtIndex:0];
}

- (void)awakeFromNib {
    // Initialization code
}

@end
