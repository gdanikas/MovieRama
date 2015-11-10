//
//  MRMoviesListVC.m
//  MovieRama
//
//  Created by George Danikas on 04/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import "MRMoviesListVC.h"
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

@interface MRMoviesListVC () <UITableViewDataSource, UITableViewDelegate, UISearchBarDelegate, CLLocationManagerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loadDataActivityIndicator;

@property (strong, nonatomic) NSFetchedResultsController *frc;
@property (nonatomic) NSMutableArray *moviesArray;
@property (nonatomic) NSUInteger pageLimit;
@property (nonatomic) NSUInteger currentPage;
@property (nonatomic) NSUInteger totalMovies;
@property (nonatomic) CLLocationManager *locationManager;
@property (nonatomic) NSString *userISOcountryCode;
@property (nonatomic) NSURLSessionDataTask *sessionDataTask;

@end

@implementation MRMoviesListVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Initialize
    self.moviesArray = [NSMutableArray array];
    self.currentPage = 1;
    self.totalMovies = 0;
    
    //Hide empty cells
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.tableView.rowHeight = 100.0;
    
    //Fetch Movies from CD
    [self performFetchForPage:self.currentPage];
    
    // Set tableView infinite indicator
    self.tableView.infiniteScrollIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleGray];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(findUserLocation) name:@"ApplicationDidBecomeActive" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // Add infinite scroll handler for movies of the week
    __weak typeof(self) weakSelf = self;
    [self.tableView addInfiniteScrollWithHandler:^(UITableView *tableView) {
        self.currentPage++;
        
        [weakSelf performFetchForPage:self.currentPage];
        [weakSelf doNetTaskFetchData:^{
            // Finish infinite scroll animations
            [tableView finishInfiniteScroll];
        }];
    }];
    
    // Detect the user current country
    [self findUserLocation];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // Calculate page limit according to available screen height
    self.pageLimit = ceil(self.tableView.bounds.size.height / self.tableView.rowHeight) + 5;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ApplicationDidBecomeActive" object:nil];
}

- (void)findUserLocation {
    // Initialize location manager
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    
    // Requests permission to use location services
    if ([self.locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
        [self.locationManager requestWhenInUseAuthorization];
    }
    
    // Start updating user location
    [self.locationManager startUpdatingLocation];
}

#pragma mark - Location manager delegate
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
    // Cancel running URL session data task
    if (self.sessionDataTask && self.sessionDataTask.state == NSURLSessionTaskStateRunning) {
        [self.sessionDataTask cancel];
        self.sessionDataTask = nil;
    }
    
    [self doNetTaskFetchData:nil];
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
    CLLocation *currentLocation = [locations objectAtIndex:0];
    [manager stopUpdatingLocation];
    
    CLGeocoder *geocoder = [[CLGeocoder alloc] init] ;
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
         if (!(error)) {
             CLPlacemark *placemark = [placemarks objectAtIndex:0];
             self.userISOcountryCode = placemark.ISOcountryCode;
             
             ApplicationDelegate.userISOcountryCode = self.userISOcountryCode;
         }
        
        // Cancel running URL session data task
        if (self.sessionDataTask && self.sessionDataTask.state == NSURLSessionTaskStateRunning) {
            [self.sessionDataTask cancel];
            self.sessionDataTask = nil;
        }
        
        [self doNetTaskFetchData:nil];
    }];
}

#pragma mark - Core Data

- (void)performFetchForPage:(NSUInteger)page {
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Movie"];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"inTheaters = %@ && resultPage = %@", @YES, [NSNumber numberWithUnsignedInteger:page]];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"fetchedAt" ascending:YES]]];
    [fetchRequest setReturnsObjectsAsFaults:NO];
    
    NSArray *fetchedObjects = [[ApplicationDelegate managedObjectContext] executeFetchRequest:fetchRequest error:nil];
    if (page == 1)
        self.moviesArray = [fetchedObjects mutableCopy];
    else
        [self.moviesArray addObjectsFromArray:fetchedObjects];
        
    if (self.moviesArray.count > 0)
        [self.loadDataActivityIndicator stopAnimating];
    
    [self.tableView reloadData];
}

#pragma mark - Fetch Movies from API server

- (void)doNetTaskFetchData:(void(^)(void))completion {
    // Create GET params
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:
                                        @{@"page_limit": [NSNumber numberWithUnsignedInteger:self.pageLimit].stringValue,
                                          @"page": [NSNumber numberWithUnsignedInteger:self.currentPage].stringValue}
                                   ];
    if (self.userISOcountryCode)
        [params setObject:self.userISOcountryCode forKey:@"country"];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.sessionDataTask = [[APIClient client] getRequest:RequestType_InTheaters withParameters:params withBlock:^(id response, NSError *error) {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            [self.loadDataActivityIndicator stopAnimating];
            
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
         self.moviesArray = [[MovieDAO DAO] syncModelWithAPIFetchedData:data inTheaters:@YES forPage:self.currentPage withMoc:moc outputArray:self.moviesArray];

         if (data.count == 0 || self.moviesArray.count == self.totalMovies) {
             [self.tableView removeInfiniteScroll];
             [[MovieDAO DAO] deleteMoviesWithPageGT:self.currentPage withMoc:moc];
         }

         [self.tableView reloadData];
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

#pragma mark - Search bar delegate

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar {
    UINavigationController *nc = (UINavigationController *)[self.storyboard instantiateViewControllerWithIdentifier:@"searchMoviesNC"];
    [self presentViewController:nc animated:YES completion:nil];
    
    return NO;
}

@end
