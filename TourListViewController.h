//
//  TourListViewController.h
//  WalkingTours
//
//  Created by Alberto Vega Gonzalez on 12/15/15.
//  Copyright © 2015 Lindsey Boggio. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LocationTableViewCell.h"
#import "FindToursViewController.h"
@import Parse;
@import ParseUI;


@interface TourListViewController : UIViewController

@property (strong, nonatomic) NSString *currentTour;
@property (weak) id <TourListViewControllerDelegate> delegate;
- (void)setCurrentTour:(NSString*)currentTour;

@end
