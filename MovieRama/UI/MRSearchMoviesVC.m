//
//  MRSearchMoviesVC.m
//  MovieRama
//
//  Created by George Danikas on 06/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import "MRSearchMoviesVC.h"
#import "MRMovieCell.h"
#import "MRMovieDetailsVC.h"
#import "UIScrollView+InfiniteScroll.h"
#import "APIClient.h"
#import "AppDelegate.h"
#import "NSDate+Formatters.h"
#import <MapKit/MapKit.h>
#import <SDWebImage/UIImageView+WebCache.h>

#import "Movie.h"
#import "Actor.h"
#import "MovieDAO.h"

@interface MRSearchMoviesVC () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, UIScrollViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (nonatomic) NSMutableArray *moviesArray;
@property (nonatomic) NSUInteger pageLimit;
@property (nonatomic) NSUInteger currentPage;
@property (nonatomic) NSUInteger totalMovies;
@property (nonatomic) NSURLSessionDataTask *searchMoviesSessionDataTask;
@property (nonatomic) NSString *searchText;

@end

@implementation MRSearchMoviesVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Set search bar return key to Done
    self.searchBar.returnKeyType = UIReturnKeyDone;
    
    // Disable search bat until pageLimit is calculated
    [self.searchBar setUserInteractionEnabled:YES];
    
    //Hide empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.rowHeight = 100.0;
    
    // Set tableView infinite indicator
    self.tableView.infiniteScrollIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
    
    [self resetSearchParams];
    
    // Focus search bar
    [self.searchBar becomeFirstResponder];
    
    // Set controller as the delegate of underlying tableView's scrollView
    // to catch scroll events
    for (UIView *view in self.tableView.subviews) {
        if ([view isKindOfClass:[UIScrollView class]]) {
            [(UIScrollView *)view setDelegate:self];
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Calculate page limit according to available screen height
    self.pageLimit = ceil(self.tableView.bounds.size.height / self.tableView.rowHeight) + 5;
    [self.searchBar setUserInteractionEnabled:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)resetSearchParams {
    self.moviesArray = [NSMutableArray array];
    self.currentPage = 1;
    self.totalMovies = 0;
    
    // Add infinite scroll handler for search movies
    __weak typeof(self) weakSelf = self;
    [self.tableView addInfiniteScrollWithHandler:^(UITableView *tableView) {
        [weakSelf searchMovie:self.searchText withCompletion:^{
            // Finish infinite scroll animations
            [tableView finishInfiniteScroll];
        }];
    }];
}

#pragma mark - Scroll view delegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.searchBar resignFirstResponder];
    
    // Keep Search bar cancel button enabled
    for (UIView *view in self.searchBar.subviews) {
        for (id subview in view.subviews) {
            if ([subview isKindOfClass:[UIButton class]]) {
                [subview setEnabled:YES];
                break;
            }
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.moviesArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    MRMovieCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MovieCell"];
    if (cell == nil)
        cell = [MRMovieCell movieCell];
    
    Movie *theMovie = [self.moviesArray objectAtIndex:indexPath.row];
    
    if (theMovie.releaseDate) {
        cell.releaseDateLbl.text = [theMovie.releaseDate toSimpleDateString];
        cell.releaseDateContView.alpha = 0.7;
    }
    else
        cell.releaseDateContView.alpha = 0.0;
    
    cell.titleLbl.text = theMovie.title;
    cell.ratingLbl.text = theMovie.rating;
    cell.castLbl.text = theMovie.cast;
    
    cell.durationLbl.text = [theMovie durationToString];
    if (cell.durationLbl.text.length > 0 && theMovie.rating && theMovie.rating.length > 0)
        cell.ratingLbl.text = [cell.ratingLbl.text stringByAppendingString:@", "];
    
    // Set movie poster
    cell.posterImageView.contentMode = UIViewContentModeCenter;
    [cell.posterImageView sd_setImageWithURL:[NSURL URLWithString:theMovie.poster]
                            placeholderImage:[UIImage imageNamed:@"clapboard icon"]
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

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Movie *theMovie = [self.moviesArray objectAtIndex:indexPath.row];
    
    MRMovieDetailsVC *detailsVC = [self.storyboard instantiateViewControllerWithIdentifier:@"movieDetailsVC"];
    detailsVC.theMovie = theMovie;

    [self.navigationController pushViewController:detailsVC animated:YES];
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
}

- (BOOL)textView:(UITextView *)txtView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if( [text rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet]].location == NSNotFound ) {
        return YES;
    }
    
    [txtView resignFirstResponder];
    return NO;
}

#pragma mark - Search bar delegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    // DELTE result movies from CD
    [[MovieDAO DAO] deleteMoviesInTheaters:@NO withMoc:[ApplicationDelegate managedObjectContext]];
    
    [searchBar resignFirstResponder];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    self.searchText = searchText;
    
    // Cancel running URL session data task
    if (self.searchMoviesSessionDataTask && self.searchMoviesSessionDataTask.state == NSURLSessionTaskStateRunning) {
        [self.searchMoviesSessionDataTask cancel];
        self.searchMoviesSessionDataTask = nil;
    }
    
    [self resetSearchParams];
    
    if (searchText.length == 0)
        [self.tableView reloadData];
    else
        [self searchMovie:searchText withCompletion:nil];
}

- (void)searchMovie:(NSString *)searchText withCompletion:(void(^)(void))completion {
    if (!self.searchText || (self.searchText && self.searchText.length == 0))
        return;
    
    // Create GET params
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:
                                   @{@"q": searchText,
                                     @"page_limit": [NSNumber numberWithUnsignedInteger:self.pageLimit].stringValue,
                                     @"page": [NSNumber numberWithUnsignedInteger:self.currentPage].stringValue}
                                   ];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.searchMoviesSessionDataTask = [[APIClient client] getRequest:RequestType_MoviesSearch withParameters:params withBlock:^(id response, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            
            // Show Error notification except user net task explicit cancelation
            if (error) {
                if (error.code != -999)
                    [[ApplicationDelegate rootVC] handleAppError:error];
            }
            else {
                // Get total movies
                if (response[@"total"] && ![response[@"total"] isKindOfClass:[NSNull class]]) {
                    if ([response[@"total"] isKindOfClass:[NSNumber class]])
                        self.totalMovies = [response[@"total"] integerValue];
                }
                
                [self processData:response[@"movies"]];
            }
            
            if (completion) {
                completion();
            }
        }];
    }];
}

#pragma mark Fetched Data Processing

- (void)processData:(NSArray *)data {
    if (data && [data isKindOfClass:[NSArray class]]) {
        NSManagedObjectContext *moc = [ApplicationDelegate managedObjectContext];
        self.moviesArray = [[MovieDAO DAO] syncModelWithAPIFetchedData:data inTheaters:@NO forPage:0 withMoc:moc outputArray:self.moviesArray];
        
        if (data.count == 0 || self.moviesArray.count == self.totalMovies)
            [self.tableView removeInfiniteScroll];
        else
            self.currentPage++;
        
        [self.tableView reloadData];
    }
}

@end