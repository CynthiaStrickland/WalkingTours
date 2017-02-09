//
//  Location.m
//  WalkingTours
//
//  Created by Cynthia Strickland on 12/14/15.
//  Copyright © 2015 Cynthia Strickland All rights reserved.
//

#import "Location.h"

@implementation Location

@dynamic locationName;
@dynamic locationAddress;
@dynamic locationDescription;
@dynamic photo;
@dynamic video;
@dynamic categories;
@dynamic location;
@dynamic orderNumber;
@dynamic tour;

+(void) load{
    [self registerSubclass];
}

+(NSString *)parseClassName {
    return @"Location";
}

-(id)initWithLocationName:(NSString *)locationName
          locationAddress:(NSString *)locationAddress
      locationDescription:(NSString *)locationDescription
                    photo:(PFFile *)photo
                    video:(PFFile *)video
               categories:(NSArray *)categories
                 location:(PFGeoPoint *)location
              orderNumber:(int)orderNumber
                     tour:(Tour *)tour{
    
    if ((self = [super init])){
        self.locationName = locationName;
        self.locationAddress = locationAddress;
        self.locationDescription = locationDescription;
        self.photo = photo;
        self.video = video;
        self.categories = categories;
        self.location = location;
        self.orderNumber = orderNumber;
        self.tour = tour;
    }
    return self;
}

@end
