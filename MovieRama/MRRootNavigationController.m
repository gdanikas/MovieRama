//
//  MRRootNavigationController.m
//  MovieRama
//
//  Created by George Danikas on 06/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import "MRRootNavigationController.h"
#import "APIClient.h"

@interface MRRootNavigationController () <UIAlertViewDelegate>

// The queued alert views
@property (nonatomic) NSMutableArray *alertViewsIDs;

@end

@implementation MRRootNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // Initialize arrays
    self.alertViewsIDs = [NSMutableArray array];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)handleAppError:(NSError *)error {
    // Only one active alert
    if ([self.alertViewsIDs count] >= 1 || error.code == AppErrorCodeNetworkUnreachable)
        return;
    
    // Show Alert
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", @"Global Error alerts")
                                                    message:error.localizedDescription
                                                   delegate:self
                                          cancelButtonTitle:nil
                                          otherButtonTitles:NSLocalizedString(@"OK", @"Global Error alerts"),nil];
    [alert show];
    
    
    [self.alertViewsIDs addObject:@"AppError"];
}

#pragma mark - Alert view delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *alertID;
    
    if (self.alertViewsIDs.count > 0)
        alertID = self.alertViewsIDs[0];
    
    if (alertID) {
        [self.alertViewsIDs removeObjectAtIndex:0];
    }
}

@end
