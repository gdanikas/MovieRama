//
//  MRMovieDetailsReviewCell.h
//  MovieRama
//
//  Created by George Danikas on 05/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MRMovieDetailsReviewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *quoteLbl;
@property (weak, nonatomic) IBOutlet UILabel *detailsLbl;

+ (MRMovieDetailsReviewCell *)reviewCell;

@end
