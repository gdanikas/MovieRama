//
//  NSDate+Formatters.m
//  MovieRama
//
//  Created by George Danikas on 04/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import "NSDate+Formatters.h"

static NSDateFormatter *dateFormatter = nil;
static NSDateFormatter *dateSimpleFormatter = nil;

@implementation NSDate (Formatters)

- (void)setDateFormatter {
    if (dateFormatter == nil) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"dd MMMM YYYY" options:0 locale:[NSLocale currentLocale]]];
    }
}

- (void)setDateSimpleFFormatter {
    if (dateSimpleFormatter == nil) {
        dateSimpleFormatter = [[NSDateFormatter alloc] init];
        [dateSimpleFormatter setDateFormat:[NSDateFormatter dateFormatFromTemplate:@"MMM YYYY" options:0 locale:[NSLocale currentLocale]]];
    }
}

- (NSString *)toDateString {
    [self setDateFormatter];
    return [dateFormatter stringFromDate:self];
}

- (NSString *)toSimpleDateString {
    [self setDateSimpleFFormatter];
    return [dateSimpleFormatter stringFromDate:self];
}

@end
