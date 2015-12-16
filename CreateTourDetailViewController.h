//
//  CreateTourDetailViewController.h
//  WalkingTours
//
//  Created by Miles Ranisavljevic on 12/14/15.
//  Copyright © 2015 Lindsey Boggio. All rights reserved.
//

#import <UIKit/UIKit.h>
@import CoreLocation;



@protocol LocationControllerDelegate <NSObject>

-(void)locationControllerDidUpdateLocation:(CLLocation *)location;


@end

@interface CreateTourDetailViewController : UIViewController

@property (strong,nonatomic) CLLocationManager *locationManager;
@property (strong,nonatomic) CLLocation *location;
@property (weak, nonatomic) id delegate;


@end
