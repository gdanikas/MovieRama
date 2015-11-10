//
//  MRMovieDetailsReviewCell.m
//  MovieRama
//
//  Created by George Danikas on 05/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import "MRMovieDetailsReviewCell.h"

@implementation MRMovieDetailsReviewCell

+ (MRMovieDetailsReviewCell *)reviewCell {
    return [[[NSBundle mainBundle] loadNibNamed:@"MRMovieDetailsReviewCell" owner:self options:nil] objectAtIndex:0];
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
