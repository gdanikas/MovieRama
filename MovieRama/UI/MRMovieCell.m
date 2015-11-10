//
//  MRMovieCell.m
//  MovieRama
//
//  Created by George Danikas on 06/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import "MRMovieCell.h"

@implementation MRMovieCell

+ (MRMovieCell *)movieCell {
    return [[[NSBundle mainBundle] loadNibNamed:@"MRMovieCell" owner:self options:nil] objectAtIndex:0];
}
- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
