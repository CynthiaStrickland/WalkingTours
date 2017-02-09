//
//  Tour.m
//  WalkingTours
//
//  Created by Cynthia Strickland on 12/14/15.
//  Copyright © 2015 Cynthia Strickland All rights reserved.
//

#import "Tour.h"

@implementation Tour

@dynamic nameOfTour;
@dynamic descriptionText;
@dynamic startLocation;
@dynamic user;



+(void) load {
    [self registerSubclass];
}

+(NSString *)parseClassName {
    return @"Tour";
}


-(id)initWithNameOfTour:(NSString *)nameOfTour
        descriptionText:(NSString *)descriptionText
          startLocation:(PFGeoPoint *)startLocation
                   user:(PFUser *)user{
    
    if ((self = [super init])){
        self.nameOfTour = nameOfTour;
        self.descriptionText = descriptionText;
        self.startLocation = startLocation;
        self.user = user;
    }
    return self;
}


@end
