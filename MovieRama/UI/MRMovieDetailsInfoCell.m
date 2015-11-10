//
//  MRMovieDetailsInfoCell.m
//  MovieRama
//
//  Created by George Danikas on 05/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import "MRMovieDetailsInfoCell.h"

@implementation MRMovieDetailsInfoCell

+ (MRMovieDetailsInfoCell *)infoCell {
    return [[[NSBundle mainBundle] loadNibNamed:@"MRMovieDetailsInfoCell" owner:self options:nil] objectAtIndex:0];
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
