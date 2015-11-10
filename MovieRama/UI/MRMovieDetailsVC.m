//
//  MRMovieDetailsVC.m
//  MovieRama
//
//  Created by George Danikas on 05/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import "MRMovieDetailsVC.h"
#import "MRMovieDetailsInfoCell.h"
#import "MRSimilarMoviesCollectionCell.h"
#import "MRMovieDetailsSimilarMoviesCell.h"
#import "MRMovieDetailsReviewCell.h"
#import "APIClient.h"
#import "NSDate+Formatters.h"
#import "AppDelegate.h"
#import <SDWebImage/UIImageView+WebCache.h>
#import "NSString+DateParsers.h"

#import "Movie.h"
#import "Actor.h"

#pragma mark Review class
@interface Review : NSObject

@property (nonatomic) NSString *critic;
@property (nonatomic) NSString *publication;
@property (nonatomic) NSString *quote;
@property (nonatomic) NSDate *reviewDate;

- (void)updatePropertiesWithData:(NSDictionary *)dataDict;
- (NSString *)authorDetails;
- (NSString *)detailsInfo;

@end

@implementation Review

- (void)updatePropertiesWithData:(NSDictionary *)dataDict {
    if (dataDict[@"critic"] && [dataDict[@"critic"] isKindOfClass:[NSString class]])
        self.critic = dataDict[@"critic"];
    
    if (dataDict[@"publication"] && [dataDict[@"publication"] isKindOfClass:[NSString class]])
        self.publication = dataDict[@"publication"];
    
    if (dataDict[@"quote"] && [dataDict[@"quote"] isKindOfClass:[NSString class]])
        self.quote = dataDict[@"quote"];
    
    if (dataDict[@"date"] && dataDict[@"date"] != (NSString *) [NSNull null])
        self.reviewDate = [dataDict[@"date"] parseDate];
}

- (NSString *)authorDetails {
    NSMutableString *details = [NSMutableString new];
    
    if (self.critic)
        [details appendString:self.critic];
    
    if (self.publication) {
        if (details.length > 0)
            [details appendString:[NSString stringWithFormat:@", %@", self.publication]];
        else
            [details appendString:self.publication];
    }

    return details;
}

- (NSString *)detailsInfo {
    NSMutableString *details = [NSMutableString stringWithString:[self authorDetails]];

    if (self.reviewDate) {
        if (details.length > 0)
            [details appendString:[NSString stringWithFormat:@" | %@", [self.reviewDate toDateString]]];
        else
            [details appendString:[self.reviewDate toDateString]];
    }
    
    return details;
}

@end
    
@interface MRMovieDetailsVC () <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (nonatomic) NSString *remindMeBtnTitle;
@property (nonatomic) NSMutableArray *reviewsArray;
@property (nonatomic) NSString *userISOcountryCode;
@property (nonatomic) NSString *casting;

@end

@implementation MRMovieDetailsVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.theMovie.title;
    
    // Initialize
    self.reviewsArray = [[NSMutableArray alloc] init];
    
    self.userISOcountryCode = [ApplicationDelegate userISOcountryCode];
    
    [self populateCastString];

    // Do network tasks
    [self doNetTaskFetchMoviesInfoData];
    [self doNetTaskFetchSimilarMoviesData];
    [self doNetTaskFetchReviewsData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(doNetTaskFetchReviewsData) name:@"ApplicationDidBecomeActive" object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ApplicationDidBecomeActive" object:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)populateCastString {
    NSMutableArray *castNames = [NSMutableArray array];
    for (Actor *actor in self.theMovie.actors) {
        NSString *castStr = actor.name;
        if (castStr && castStr.length > 0 && actor.characters && actor.characters.length > 0) {
            castStr = [castStr stringByAppendingString:[NSString stringWithFormat:@" (as %@)", actor.characters]];
        }
        
        [castNames addObject:castStr];
    }
    
    if (castNames.count > 0) {
        self.casting = [castNames componentsJoinedByString:@", "];
    }
}

#pragma mark - Fetch Movie Detailss from API server

- (void)doNetTaskFetchMoviesInfoData {
    // Create GET params
    NSDictionary *params = @{@":id": self.theMovie.movieId.stringValue};
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[APIClient client] getRequest:RequestType_MoviesInfo withParameters:params withBlock:^(id response, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            // Show Error notification except user net task explicit cancelation
            if (error) {
                if (error.code != -999)
                    [[ApplicationDelegate rootVC] handleAppError:error];
            }
            else {
                [self.theMovie updateModelWithAPIFetchedData:response];
                
                // Save context
                [[ApplicationDelegate managedObjectContext] save:nil];
                
                [self.tableView reloadData];
            }
        }];
    }];
}

- (void)doNetTaskFetchSimilarMoviesData {
    // Create GET params
    NSDictionary *params = @{@":id": self.theMovie.movieId.stringValue};
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[APIClient client] getRequest:RequestType_MoviesSimilar withParameters:params withBlock:^(id response, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            // Show Error notification except user net task explicit cancelation
            if (error) {
                if (error.code != -999)
                    [[ApplicationDelegate rootVC] handleAppError:error];
            }
            else {
                NSArray *moviesArray = response[@"movies"];
                if (moviesArray && [moviesArray isKindOfClass:[NSArray class]]) {
                    NSManagedObjectContext *moc = [ApplicationDelegate managedObjectContext];
                    
                    // Sync API fetched data with CD
                    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Movie"];
                    NSMutableArray *storedMovies = [NSMutableArray arrayWithArray:[moc executeFetchRequest:fetchRequest error:nil]];
                    NSMutableArray *similarMovies = [NSMutableArray array];
                    
                    for (NSDictionary *movieDict in moviesArray) {
                        // Check if current fetched Movie already exist in DB
                        NSNumber *movieID;
                        if (movieDict[@"id"] && ![movieDict[@"id"] isKindOfClass:[NSNull class]]) {
                            if ([movieDict[@"id"] isKindOfClass:[NSNumber class]])
                                movieID = movieDict[@"id"];
                            else
                                movieID = [NSNumber numberWithInteger:[movieDict[@"id"] integerValue]];
                        }
                        
                        BOOL found = NO;
                        for (Movie *storedObject in storedMovies) {
                            if (storedObject.movieId.integerValue == movieID.integerValue) {
                                // Fetched Movie found in Stored ones
                                found = YES;
                                [storedObject updateModelWithAPIFetchedData:movieDict];
                                [similarMovies addObject:storedObject];
                                
                                // This Movie is still present, remove it from stored Movies Array
                                [storedMovies removeObject:storedObject];
                                break;
                            }
                        }
                        
                        // If fetched Movie does NOT exist, create and add it
                        if (!found) {
                            // Create new similar movie entity
                            Movie *newMovie = (Movie *)[NSEntityDescription insertNewObjectForEntityForName:@"Movie" inManagedObjectContext:moc];
                            [newMovie updateModelWithAPIFetchedData:movieDict];
                            newMovie.inTheaters = @NO;
                            
                            [similarMovies addObject:newMovie];
                        }
                    }
                    
                    // Update similar movies set
                    self.theMovie.similarMovies = [NSSet setWithArray:similarMovies];
                    
                    // Save context
                    [moc save:nil];

                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:4] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }
        }];
    }];
}

- (void)doNetTaskFetchReviewsData {
    // Create GET params
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:
                                   @{@":id": self.theMovie.movieId.stringValue,
                                     @"page_limit": @"2"}
                                   ];
    
    if (self.userISOcountryCode)
        [params setObject:self.userISOcountryCode forKey:@"country"];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    [[APIClient client] getRequest:RequestType_MoviesReviews withParameters:params withBlock:^(id response, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            // Show Error notification except user net task explicit cancelation
            if (error) {
                if (error.code != -999)
                    [[ApplicationDelegate rootVC] handleAppError:error];
            }
            else {
                NSArray *reviewsArray = response[@"reviews"];
                if (reviewsArray && [reviewsArray isKindOfClass:[NSArray class]]) {
                    // Clear reviews array
                    [self.reviewsArray removeAllObjects];
                    
                    for (NSDictionary *reviewDict in reviewsArray) {
                        // Create new similar movie entity
                        Review *newReview = [[Review alloc] init];
                        [newReview updatePropertiesWithData:reviewDict];
                        
                        [self.reviewsArray addObject:newReview];
                    }
                    
                    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:5] withRowAnimation:UITableViewRowAnimationAutomatic];
                }
            }
        }];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 6;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Movie synopsis & director section
    if (section == 2 &&
        (self.theMovie.synopsis && self.theMovie.synopsis.length > 0) &&
        (self.theMovie.directors && self.theMovie.directors.length > 0))
        return 2;
    
    // Movie reviews section
    else if (section == 5)
        return self.reviewsArray.count;
    
    return 1;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    
    switch (section) {
        case 1: {
            if (self.theMovie.releaseDate) {
                title = NSLocalizedString(@"Release date", @"Movie Details VC");
                if (self.theMovie.releaseDateType && self.theMovie.releaseDateType.length > 0) {
                    title = [title stringByAppendingString:[NSString stringWithFormat:@" (%@)", self.theMovie.releaseDateType]];
                }
            }
            break;
        }
        case 2: {
            if ((self.theMovie.synopsis && self.theMovie.synopsis.length > 0) ||
                (self.theMovie.directors && self.theMovie.directors.length > 0))
                title = NSLocalizedString(@"More info", @"Movie Details VC");
            break;
        }
        case 3: {
            if (self.casting && self.casting.length > 0)
                title = NSLocalizedString(@"Cast", @"Movie Details VC");
            break;
        }
        case 4: {
            if (self.theMovie.similarMovies.count > 0)
                title = NSLocalizedString(@"More like this", @"Movie Details VC");
            break;
        }
        case 5: {
            if (self.reviewsArray.count > 0)
                title = NSLocalizedString(@"Critic reviews", @"Movie Details VC");
            break;
        }
        default:
            break;
    }

    return title;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    cell.contentView.backgroundColor = [UIColor clearColor];
    
    // Similar movies section
    if ([cell isKindOfClass:[MRMovieDetailsSimilarMoviesCell class]]) {
        MRMovieDetailsSimilarMoviesCell *similarMoviesCell = (MRMovieDetailsSimilarMoviesCell *)cell;
        
        // Set up collection view
        UINib *nib = [UINib nibWithNibName:@"MRSimilarMoviesCollectionCell" bundle: nil];
        [similarMoviesCell.collectionView registerNib:nib forCellWithReuseIdentifier:@"SimilarMoviesCollectionCell"];
        similarMoviesCell.collectionView.dataSource = self;
        similarMoviesCell.collectionView.delegate = self;
        
        [similarMoviesCell.collectionView reloadData];

    // Movie synopsis & director section
    } else if (indexPath.section == 2 && indexPath.row == 1) {
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(0, 1.0, cell.contentView.frame.size.width, 1.0)];
        separator.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [cell.contentView addSubview:separator];
    
    // Movie reviews section
    } else if (indexPath.section == 5 && indexPath.row > 0 && indexPath.row < self.reviewsArray.count) {
        UIView *separator = [[UIView alloc] initWithFrame:CGRectMake(12.0, 1.0, cell.contentView.frame.size.width - 12.0, 1.0)];
        separator.backgroundColor = [UIColor groupTableViewBackgroundColor];
        [cell.contentView addSubview:separator];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
    
    switch (indexPath.section) {
        // Movie info section
        case 0: {
            MRMovieDetailsInfoCell *infoCell = [tableView dequeueReusableCellWithIdentifier:@"InfoCell"];
            if (infoCell == nil)
                infoCell = [MRMovieDetailsInfoCell infoCell];
            
            // Set movie poster
            infoCell.posterImageView.contentMode = UIViewContentModeCenter;
            [infoCell.posterImageView sd_setImageWithURL:[NSURL URLWithString:self.theMovie.poster]
                                    placeholderImage:[UIImage imageNamed:@"clapboard icon"]
                                             options:0
                                            progress:nil
                                           completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                               if (image) {
                                                   infoCell.posterImageView.contentMode = UIViewContentModeScaleAspectFill;
                                                   infoCell.posterImageView.clipsToBounds = YES;
                                               }
                                           }];

            
            infoCell.posterImageView.layer.borderWidth = 2.0;
            infoCell.posterImageView.layer.borderColor = [UIColor darkGrayColor].CGColor;
            
            infoCell.titleLbl.text = self.theMovie.title;
            
            infoCell.ratingLbl.text = self.theMovie.rating;
            infoCell.durationLbl.text = [self.theMovie durationToString];
            
            if (infoCell.durationLbl.text.length > 0 && self.theMovie.rating && self.theMovie.rating.length > 0)
                infoCell.ratingLbl.text = [infoCell.ratingLbl.text stringByAppendingString:@", "];
            
            infoCell.genreLbl.text = self.theMovie.genres;

            cell = infoCell;
            break;
        }
            
        // Movie release date section
        case 1: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"RemindMeCell" forIndexPath:indexPath];
            if (self.theMovie.releaseDate) {
                UILabel *lbl = (UILabel *)[cell viewWithTag:1];
                lbl.text = [self.theMovie.releaseDate toDateString];
                
                UIButton *remindMeBtn = (UIButton *)[cell viewWithTag:2];
                if (remindMeBtn) {
                    [self setRemindMeBtn:remindMeBtn];
                    
                    if ([self.theMovie.releaseDate compare:[NSDate date]] == NSOrderedDescending)
                        remindMeBtn.alpha = 1.0;
                    else
                        remindMeBtn.alpha = 0.0;
                }
            }
            
            break;
        }
            
        // Movie synopsis & director section
        case 2: {
            switch (indexPath.row) {
                case 0: {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"BasicCell" forIndexPath:indexPath];
                    if (self.theMovie.synopsis && self.theMovie.synopsis.length > 0) {
                        UILabel *lbl = (UILabel *)[cell viewWithTag:1];
                        lbl.text = self.theMovie.synopsis;
                    } else if (self.theMovie.directors && self.theMovie.directors.length > 0) {
                        cell = [tableView dequeueReusableCellWithIdentifier:@"DirectorCell" forIndexPath:indexPath];
                        UILabel *lbl = (UILabel *)[cell viewWithTag:2];
                        lbl.text = self.theMovie.directors;
                    }
                    
                    break;
                }
                case 1: {
                    cell = [tableView dequeueReusableCellWithIdentifier:@"DirectorCell" forIndexPath:indexPath];
                    UILabel *lbl = (UILabel *)[cell viewWithTag:2];
                    lbl.text = self.theMovie.directors;
                    
                    break;
                }
                    
                default:
                    break;
            }

            break;
        }
        
        // Movie cast section
        case 3: {
            cell = [tableView dequeueReusableCellWithIdentifier:@"BasicCell" forIndexPath:indexPath];
            if (self.casting && self.casting.length > 0) {
                UILabel *lbl = (UILabel *)[cell viewWithTag:1];
                lbl.text = self.casting;
                
                // Bolding actor names
                NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.casting];
                UIFontDescriptor *fontDescriptor = lbl.font.fontDescriptor;
                fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
                
                for (Actor *actor in self.theMovie.actors) {
                    NSRange boldRange = [self.casting rangeOfString:actor.name];
                    [attributedString addAttribute: NSFontAttributeName value:[UIFont fontWithDescriptor:fontDescriptor size:fontDescriptor.pointSize] range:boldRange];
                }
                
                lbl.attributedText = attributedString;
            }
            
            break;
        }
            
        // Similar movies section
        case 4: {
            MRMovieDetailsSimilarMoviesCell *similarMoviesCell = [tableView dequeueReusableCellWithIdentifier:@"SimilarMoviesCell"];
            if (similarMoviesCell == nil)
                similarMoviesCell = [MRMovieDetailsSimilarMoviesCell similarMoviesCell];

            cell = similarMoviesCell;
            
            break;
        }
            
        // Movie reviews section
        case 5: {
            MRMovieDetailsReviewCell *reviewCell = [tableView dequeueReusableCellWithIdentifier:@"ReviewCell"];
            if (reviewCell == nil)
                reviewCell = [MRMovieDetailsReviewCell reviewCell];
            
            Review *theReview = [self.reviewsArray objectAtIndex:indexPath.row];
            reviewCell.quoteLbl.text = theReview.quote;
            reviewCell.detailsLbl.text = theReview.detailsInfo;
            
            // Bolding author details
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:reviewCell.detailsLbl.text];
            UIFontDescriptor *fontDescriptor = reviewCell.detailsLbl.font.fontDescriptor;
            fontDescriptor = [fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
            
            NSRange boldRange = [reviewCell.detailsLbl.text rangeOfString:theReview.authorDetails];
            [attributedString addAttribute: NSFontAttributeName value:[UIFont fontWithDescriptor:fontDescriptor size:fontDescriptor.pointSize] range:boldRange];
            reviewCell.detailsLbl.attributedText = attributedString;
            
            cell = reviewCell;
            break;
        }
            
        default:
            break;
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGFloat height;
    
    switch (indexPath.section) {
        // Movie info section
        case 0: {
            height = 120.0;
            break;
        }
        
        // Movie release date section
        case 1: {
            if (self.theMovie.releaseDate)
                height = 44.0;
            else
                height = 0;
            break;
        }
            
        // Movie synopsis & director section
        case 2: {
            if ((self.theMovie.synopsis && self.theMovie.synopsis.length > 0) ||
                (self.theMovie.directors && self.theMovie.directors.length > 0))
                height = UITableViewAutomaticDimension;
            else
                height = 0;
            break;
        }
            
        // Movie cast section
        case 3: {
            if (self.casting && self.casting.length > 0)
                height = UITableViewAutomaticDimension;
            else
                height = 0;
            break;
        }
            
        // Similar movies section
        case 4: {
            if (self.theMovie.similarMovies.count > 0)
                height = 95.0;
            else
                height = 0;
        
            break;
        }
            
        // Movie reviews section
        case 5: {
            if (self.reviewsArray.count > 0)
                height = UITableViewAutomaticDimension;
            else
                height = 0;
            break;
        }
        default:
            break;
    }
    
    return height;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (section == 0 || ![self sectionHasData:section])
        return CGFLOAT_MIN;
    
    return 22.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    if (![self sectionHasData:section])
        return CGFLOAT_MIN;
    
    return 22.0;
}

- (BOOL)sectionHasData:(NSInteger)section {
    if ((section == 1 && !self.theMovie.releaseDate) ||                                                                    // Release date section
        (section == 2 && (!self.theMovie.synopsis || (self.theMovie.synopsis && self.theMovie.synopsis.length == 0)) &&
         (!self.theMovie.directors || (self.theMovie.directors && self.theMovie.directors.length == 0))) ||                // Movie synopsis & director section
        (section == 3 && (!self.casting || (self.casting && self.casting.length == 0))) ||               // Movie cast section
        (section == 4 && self.theMovie.similarMovies.count == 0) ||                                                        // Similar movies section
        (section == 5 && self.reviewsArray.count == 0))                                                                    // Movie reviews section
        return NO;
    
    return YES;
}


#pragma mark - CollectionView Data source

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.theMovie.similarMovies.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    MRSimilarMoviesCollectionCell *cell = (MRSimilarMoviesCollectionCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"SimilarMoviesCollectionCell" forIndexPath:indexPath];
    
    Movie *theSimilarMovie = [[self.theMovie.similarMovies allObjects] objectAtIndex:indexPath.row];
    // Set movie poster
    cell.posterImageView.contentMode = UIViewContentModeCenter;
    [cell.posterImageView sd_setImageWithURL:[NSURL URLWithString:theSimilarMovie.poster]
                                placeholderImage:[UIImage imageNamed:@"clapboard small icon"]
                                         options:0
                                        progress:nil
                                       completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                           if (image) {
                                               cell.posterImageView.contentMode = UIViewContentModeScaleAspectFill;
                                               cell.posterImageView.clipsToBounds = YES;
                                           }
                                       }];
    return cell;
}

#pragma mark - Actions

- (IBAction)remindMeBtnPressed:(id)sender {
    UIButton *remindMeBtn = (UIButton *)(id)sender;
    remindMeBtn.alpha = 0.0;
    
    UILocalNotification *localNotif;
    
    UIApplication *application = [UIApplication sharedApplication];
    for (UILocalNotification *notif in  application.scheduledLocalNotifications) {
        if (notif.userInfo[@"RemindMeMovie"] == self.theMovie.movieId.stringValue)
            localNotif = notif;
    }
    
    if (localNotif) {
        // Cancel notification
        [[UIApplication sharedApplication] cancelLocalNotification:localNotif];
    } else {
        // Schedule notification
        NSCalendar *calendar = [NSCalendar autoupdatingCurrentCalendar];
        
        // Set local notification date as the day of the the release date of the movie at 10:00 am
        NSDateComponents *dateComps = [calendar components:NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:self.theMovie.releaseDate];
        [dateComps setHour:19];
        [dateComps setMinute:10];
        
        localNotif = [[UILocalNotification alloc] init];
        if (localNotif == nil)
            return;
        
        localNotif.fireDate = [calendar dateFromComponents:dateComps];
        localNotif.timeZone = [NSTimeZone defaultTimeZone];
        
        localNotif.alertBody = [NSString stringWithFormat:NSLocalizedString(@"Hey! Don't Forget! Today is the Opening Day of the movie '%@'", @"Movie Details VC"), self.theMovie.title];
        localNotif.alertAction = NSLocalizedString(@"OK", @"Movie Details VC");
        localNotif.alertTitle = NSLocalizedString(@"Movie Opening", @"Movie Details VC");
        localNotif.soundName = UILocalNotificationDefaultSoundName;
        localNotif.applicationIconBadgeNumber = 1;
        
        NSDictionary *infoDict = [NSDictionary dictionaryWithObject:self.theMovie.movieId.stringValue forKey:@"RemindMeMovie"];
        localNotif.userInfo = infoDict;

        [[UIApplication sharedApplication] scheduleLocalNotification:localNotif];
    }
    
   [self setRemindMeBtn:remindMeBtn];
}

- (void)setRemindMeBtn:(UIButton *)button {
    [button addTarget:self action:@selector(remindMeBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    
    button.layer.borderWidth = 1.0;
    button.layer.cornerRadius = 4.0;
    
    self.remindMeBtnTitle = NSLocalizedString(@"Remind Me", @"Movie Details VC");
    UIColor *btnColor = [UIColor colorWithRed:27.0/255.0 green: 122.0/255.0 blue: 194.0/255.0 alpha: 1.0];
    UIImage *btnImage = [UIImage imageNamed:@"bell icon"];
    
    UIApplication *application = [UIApplication sharedApplication];
    for (UILocalNotification *notif in  application.scheduledLocalNotifications) {
        if (notif.userInfo[@"RemindMeMovie"] == self.theMovie.movieId.stringValue) {
            self.remindMeBtnTitle = NSLocalizedString(@"Forget", @"Movie Details VC");
            btnColor = [UIColor redColor];
            btnImage = nil;
        }
    }
    
    button.layer.borderColor = btnColor.CGColor;
    [button setTitleColor:btnColor forState:UIControlStateNormal];
    [button setTitle:self.remindMeBtnTitle forState:UIControlStateNormal];
    [button setImage:btnImage forState:UIControlStateNormal];
    
    [UIView animateWithDuration:0.3 animations:^{
         button.alpha = 1.0;
    }];
}

@end
