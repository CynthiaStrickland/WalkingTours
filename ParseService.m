//
//  ParseService.m
//  WalkingTours
//
//  Created by Lindsey on 12/15/15.
//  Copyright © 2015 Lindsey Boggio. All rights reserved.
//

#import "ParseService.h"
#import <Parse/Parse.h>
#import "Tour.h"
#import "Location.h"

@implementation ParseService

+ (void)saveToParse:(Tour *)tour locations:(NSArray *)locations completion:(tourSaveCompletion)completion {
    NSArray *saveArray = [NSArray arrayWithObjects:tour, locations, nil];
    [PFObject saveAllInBackground:saveArray block:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            completion(YES, nil);
        } else {
            completion(NO, error);
        }
    }];
}

+ (void)fetchLocationsWithTourId:(NSString *)tourId completion:(locationsFetchCompletion)completion {
    
    PFQuery *query = [PFQuery queryWithClassName:@"Location"];
    [query whereKey:@"tour" equalTo:[PFObject objectWithoutDataWithClassName:@"Tour" objectId:tourId]];
    
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error.localizedFailureReason);
            completion(NO, nil);
        }
        if (objects) {
            completion(YES, objects);
        }
    }];
}

+ (void)fetchLocationsWithCategories:(NSArray *)categories nearLocation:(CLLocationCoordinate2D)location withinMiles:(float)miles completion:(locationsFetchCompletion)completion {
    NSString *predicateString = @"";
    NSMutableArray *predicateArguments;;
    if (categories.count > 0) {
        predicateString = @"%@ IN categories";
        predicateArguments = [NSMutableArray arrayWithObject:categories[0]];
        if (categories.count > 1) {
            for (int i = 1; i < categories.count; i++) {
                predicateString = [predicateString stringByAppendingString:@" OR %@ IN categories"];
                [predicateArguments addObject:categories[i]];
            }
        }
    }
    NSPredicate *predicate;
    PFQuery *query;
    if (predicateString.length > 0) {
        predicate = [NSPredicate predicateWithFormat:predicateString argumentArray:predicateArguments];
    }
    if (predicate) {
        query = [PFQuery queryWithClassName:@"Location" predicate:predicate];
    } else {
        query = [PFQuery queryWithClassName:@"Location"];
    }
    [query whereKey:@"location" nearGeoPoint:[PFGeoPoint geoPointWithLatitude:location.latitude longitude:location.longitude] withinMiles:miles];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error.localizedFailureReason);
            completion(NO, nil);
        }
        if (objects) {
            completion(YES, objects);
        }
    }];
}

+ (void)fetchToursNearLocation:(CLLocationCoordinate2D)location completion:(toursFetchCompletion)completion {
    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:location.latitude longitude:location.longitude];
    PFQuery *query = [PFQuery queryWithClassName:@"Tour"];
    [query whereKey:@"startLocation" nearGeoPoint:geoPoint];
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error.localizedFailureReason);
            completion(NO, nil);
        }
        if (objects) {
            completion(YES, objects);
        }
    }];
}

+ (void)searchToursNearLocation:(CLLocationCoordinate2D)location withinMiles:(float)miles withSearchTerm:(NSString *)searchTerm completion:(toursFetchCompletion) completion {
    PFQuery *unfilteredQuery = [PFQuery queryWithClassName:@"Tour"];
    [unfilteredQuery whereKey:@"startLocation" nearGeoPoint:[PFGeoPoint geoPointWithLatitude:location.latitude longitude:location.longitude] withinMiles:miles];
    [unfilteredQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (error) {
            NSLog(@"%@", error.localizedFailureReason);
            completion(NO, nil);
        }
        if (objects) {
            if (!searchTerm.length > 0) {
                completion(YES, objects);
            } else {
                NSMutableArray *filteredResults;
                for (Tour *tour in objects) {
                    if ([tour.nameOfTour containsString:searchTerm] || [tour.descriptionText containsString:searchTerm]) {
                        if (filteredResults.count == 0) {
                            filteredResults = [NSMutableArray arrayWithObject:tour];
                        } else {
                            [filteredResults addObject:tour];
                        }
                    }
                }
                if (filteredResults.count > 0) {
                    completion(YES, filteredResults);
                } else {
                    completion(NO, nil);
                }
            }
        }
    }];
}

+ (void)searchToursNearLocation:(CLLocationCoordinate2D)location withinMiles:(float)miles withSearchTerm:(NSString *)searchTerm categories:(NSArray *)categories completion:(toursFetchCompletion) completion {
    [ParseService fetchLocationsWithCategories:categories nearLocation:location withinMiles:miles completion:^(BOOL success, NSArray *results) {
        if (success) {
            NSMutableArray *searchResults;
            for (Location *location in results) {
                if (!searchResults.count > 0 || ![searchResults indexOfObject:location.tour.objectId]) {
                    if (searchResults.count == 0) {
                        searchResults = [NSMutableArray arrayWithObject:location.tour.objectId];
                     } else {
                         [searchResults addObject:location.tour.objectId];
                     }
                 }
             }
            if (searchResults.count == 0) {
                completion(NO, nil);
            } else {
                PFQuery *query = [PFQuery queryWithClassName:@"Tour"];
                [query whereKey:@"objectId" containedIn:searchResults];
                [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
                    if (error) {
                        NSLog(@"%@", error.localizedFailureReason);
                        completion(NO, nil);
                    }
                    if (objects) {
                        NSMutableArray *filteredResults;
                        for (Tour *tour in objects) {
                            if ([tour.nameOfTour containsString:searchTerm] || [tour.descriptionText containsString:searchTerm]) {
                                if (filteredResults.count == 0) {
                                    filteredResults = [NSMutableArray arrayWithObject:tour];
                                } else {
                                    [filteredResults addObject:tour];
                                }
                            }
                        }
                        if (filteredResults.count > 0) {
                            completion(YES, objects);
                        } else {
                            completion(NO, nil);
                        }
                    }
                }];
            }
         }
     }];
}

@end
