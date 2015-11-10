//
//  NSString+DateParsers.m
//  MovieRama
//
//  Created by George Danikas on 04/11/15.
//  Copyright © 2015 George Danikas. All rights reserved.
//

#import "NSString+DateParsers.h"

static NSDateFormatter *dateFormatter = nil;

@implementation NSString (DateParsers)

- (void)setDateFormatter {
    if (dateFormatter == nil) {
        dateFormatter = [NSDateFormatter new];
        dateFormatter.dateFormat = @"yyyy-MM-dd";
    }
}

- (NSDate *)parseDate {
    [self setDateFormatter];
    return [dateFormatter dateFromString:self];
}

@end
