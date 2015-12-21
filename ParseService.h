//
//  ParseService.h
//  WalkingTours
//
//  Created by Lindsey on 12/15/15.
//  Copyright © 2015 Lindsey Boggio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tour.h"

typedef void(^locationsFetchCompletion)(BOOL success, NSArray *results);
typedef void(^toursFetchCompletion)(BOOL success, NSArray *results);
typedef void(^tourSaveCompletion)(BOOL success, NSError *error);

@interface ParseService : NSObject

+ (void)saveToParse:(Tour *)tour locations:(NSArray *)locations completion:(tourSaveCompletion)completion;

+ (void)fetchLocationsWithTourId:(NSString *)tourId completion:(locationsFetchCompletion)completion;

+ (void)fetchToursNearLocation:(CLLocationCoordinate2D)location completion:(toursFetchCompletion)completion;

+ (void)searchToursNearLocation:(CLLocationCoordinate2D)location withinMiles:(float)miles withSearchTerm:(NSString *)searchTerm completion:(toursFetchCompletion) completion;

+ (void)searchToursNearLocation:(CLLocationCoordinate2D)location withinDistance:(float)distance withSearchTerm:(NSString *)searchTerm categories:(NSArray *)categories completion:(toursFetchCompletion) completion;

@end
