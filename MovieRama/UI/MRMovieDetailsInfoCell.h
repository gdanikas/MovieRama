//
//  MRMovieDetailsInfoCell.h
//  MovieRama
//
//  Created by George Danikas on 05/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MRMovieDetailsInfoCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIImageView *posterImageView;
@property (weak, nonatomic) IBOutlet UILabel *titleLbl;
@property (weak, nonatomic) IBOutlet UILabel *ratingLbl;
@property (weak, nonatomic) IBOutlet UILabel *durationLbl;
@property (weak, nonatomic) IBOutlet UILabel *genreLbl;

+ (MRMovieDetailsInfoCell *)infoCell;

@end
