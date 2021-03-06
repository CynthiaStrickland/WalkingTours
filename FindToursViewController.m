//
//  FindToursViewController.m
//  WalkingTours
//
//  Created by Alberto Vega Gonzalez on 12/14/15.
//  Copyright © 2015 Lindsey Boggio. All rights reserved.
//

#import "FindToursViewController.h"
#import "TourMapViewController.h"
#import "TourListViewController.h"
#import "CreateTourViewController.h"
#import "Location.h"
#import "Tour.h"
#import "Location.h"
#import "POIDetailTableViewCell.h"
#import "ParseService.h"
#import "MyExtension.h"
#import "CustomAnnotation.h"
#import "FourSquareService.h"
@import Parse;
@import ParseUI;
#import <Crashlytics/Answers.h>

@interface FindToursViewController () <MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, TourListViewControllerDelegate, POIDetailTableViewCellDelegate>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) NSMutableArray<CustomAnnotation *> *mapAnnotations;
@property (weak, nonatomic) IBOutlet UITableView *toursTableView;
@property (strong, nonatomic) UIBarButtonItem *searchButton;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (strong, nonatomic) NSMutableArray <id> *mapPoints;
@property (strong, nonatomic) NSMutableArray <Tour *> *toursFromParse;
-(void)setToursFromParse:(NSMutableArray<Tour *> *)toursFromParse;
@property (strong, nonatomic) NSMutableArray <NSString *> *favoriteToursFromParse;
-(void)setFavoriteToursFromParse:(NSMutableArray<NSString *> *)favoriteToursFromParse;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *searchBarBottomConstraint;
@property (weak, nonatomic) IBOutlet UISearchBar *keywordSearchBar;
@property (weak, nonatomic) IBOutlet UILabel *radiusLabel;
@property (weak, nonatomic) IBOutlet UISlider *radiusSlider;
@property (weak, nonatomic) IBOutlet UITableView *searchCategoryTableView;
@property (strong, nonatomic) NSArray *categoryList;
@property (strong, nonatomic) NSMutableArray *selectedCategories;
@property (weak, nonatomic) IBOutlet UIView *searchView;
@property (weak, nonatomic) IBOutlet UIButton *finalSearchButton;
@property (nonatomic) CGRect searchCategoryTableViewFrame;
- (IBAction)finalSearchButtonPressed:(UIButton *)sender;
- (IBAction)radiusSliderChanged:(UISlider *)sender;


@end

@implementation FindToursViewController

- (void)setToursFromParse:(NSArray<Tour *> *)toursFromParse {
    _toursFromParse = [NSMutableArray arrayWithArray:toursFromParse];
    [self updateAnnotationsAfterSearch:toursFromParse];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.searchView.alpha = 0.0;
    self.finalSearchButton.layer.cornerRadius = 5.0;
    self.finalSearchButton.layer.borderWidth = 1.0;
    self.finalSearchButton.layer.borderColor = [UIColor colorWithRed:0.278 green:0.510 blue:0.855 alpha:1.000].CGColor;
    self.keywordSearchBar.delegate = self;
    [self setFavoritesForUser];
    //Location Manager setup
    self.locationManager = [[CLLocationManager alloc]init];
    [self.locationManager requestWhenInUseAuthorization];
    [self.locationManager setDelegate:self];
    [self setUpSearchButton];
    [self setupViewController];
}

- (void)setFavoritesForUser {
    self.favoriteToursFromParse = [[PFUser currentUser] objectForKey:@"favorites"];
}

- (void)fetchToursNearUser {
    CLLocation *location = [self.locationManager location];
    [self setMapForCoordinateWithLatitude:location.coordinate.latitude andLongitude:location.coordinate.longitude];
    CLLocationCoordinate2D coordinate = location.coordinate;
    
    
    [ParseService fetchToursNearLocation:coordinate completion:^(BOOL success, NSArray *results) {
        if (success) {
            [self setToursFromParse:[NSMutableArray arrayWithArray:results]];
            [self.toursTableView reloadData];
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.linkedTour) {
        NSString *tourTemp = self.linkedTour;
        if (self.favoriteToursFromParse) {
            [self.favoriteToursFromParse addObject:tourTemp];
        } else {
            self.favoriteToursFromParse = [NSMutableArray arrayWithObject:tourTemp];
        }
        self.linkedTour = nil;
        [self performSegueWithIdentifier:@"TabBarController" sender:tourTemp];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.favoriteToursFromParse && [PFUser currentUser]) {
        [ParseService setFavoritedTourIds:self.favoriteToursFromParse forUser:[PFUser currentUser]];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.locationManager stopMonitoringSignificantLocationChanges];
}

- (void)setUpSearchButton {
    self.searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchButtonPressed:)];
    self.navigationItem.rightBarButtonItem = self.searchButton;
}

- (void)setupViewController {
    //Setup tableView
    [self.toursTableView setDelegate:self];
    [self.toursTableView setDataSource:self];
    self.searchCategoryTableView.delegate = self;
    self.searchCategoryTableView.dataSource = self;

    self.categoryList = @[NSLocalizedString(@"Restaurant", comment:@"This is a tour category"), NSLocalizedString(@"Cafe", comment:@"This is a tour category"), NSLocalizedString(@"Art", comment:@"This is a tour category"), NSLocalizedString(@"Museum", comment:@"This is a tour category"), NSLocalizedString(@"History", comment:@"This is a tour category"), NSLocalizedString(@"Shopping", comment:@"This is a tour category"), NSLocalizedString(@"Nightlife", comment:@"This is a tour category"), NSLocalizedString(@"Film", comment:@"This is a tour category"), NSLocalizedString(@"Education", comment:@"This is a tour category"), NSLocalizedString(@"Nature", comment:@"This is a tour category")];
    
    
    
    UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"TableViewBackground.png"]];
    [tempImageView setFrame:self.toursTableView.frame];
    
    UINib *nib = [UINib nibWithNibName:@"POIDetailTableViewCell" bundle:nil];
    [[self toursTableView] registerNib:nib forCellReuseIdentifier:@"POIDetailTableViewCell"];
    
    //Setup up MapView
    [self.mapView setDelegate:self];
    [self.mapView setShowsUserLocation: YES];
    

}

- (void)searchButtonPressed:(UIBarButtonItem *)sender {
    if (self.searchView.alpha == 0.0) {
        [UIView animateWithDuration:0.4 animations:^{
            self.searchView.alpha = 1.0;
        }];
    }
}

- (IBAction)finalSearchButtonPressed:(UIButton *)sender {
    CLLocationCoordinate2D current = self.mapView.centerCoordinate;
    [Answers logSearchWithQuery:self.keywordSearchBar.text customAttributes:@{@"categories" : self.selectedCategories, @"location" : [NSString stringWithFormat:@"%f, %f", current.latitude, current.longitude], @"milesRadius" : self.radiusLabel.text}];
    if (self.selectedCategories && self.selectedCategories.count > 0) {
        [ParseService searchToursNearLocation:current withinMiles:self.radiusLabel.text.floatValue withSearchTerm:self.keywordSearchBar.text categories:self.selectedCategories completion:^(BOOL success, NSArray *results) {
            [UIView animateWithDuration:0.4 animations:^{
                self.searchView.alpha = 0.0;
            }];
            if (success) {
                [self setToursFromParse:[NSMutableArray arrayWithArray:results]];
            } else {
                Tour *noTours = [[Tour alloc] initWithNameOfTour:NSLocalizedString(@"No tours found.", comment: nil) descriptionText:@"" startLocation:nil user:nil];
                [self setToursFromParse:[NSMutableArray arrayWithObject:noTours]];
            }
        }];
    } else {
        [ParseService searchToursNearLocation:current withinMiles:self.radiusLabel.text.floatValue withSearchTerm:self.keywordSearchBar.text categories:nil completion:^(BOOL success, NSArray *results) {
            [UIView animateWithDuration:0.4 animations:^{
                self.searchView.alpha = 0.0;
            }];
            if (success) {
                [self setToursFromParse:[NSMutableArray arrayWithArray:results]];
            } else {
                Tour *noTours = [[Tour alloc] initWithNameOfTour:NSLocalizedString(@"No tours found.", comment: nil) descriptionText:@"" startLocation:nil user:nil];
                [self setToursFromParse:[NSMutableArray arrayWithObject:noTours]];
            }
        }];
    }
//    } else {
//        [ParseService searchToursNearLocation:current withinMiles:self.radiusLabel.text.floatValue withSearchTerm:self.keywordSearchBar.text completion:^(BOOL success, NSArray *results) {
//            [UIView animateWithDuration:0.4 animations:^{
//                self.searchView.alpha = 0.0;
//            }];
//            if (success) {
//                [self setToursFromParse:results];
//            } else {
//                Tour *noTours = [[Tour alloc] initWithNameOfTour:@"No tours found." descriptionText:@"" startLocation:nil user:nil];
//                [self setToursFromParse:@[noTours]];
//            }
//        }];
//    }
}

- (IBAction)radiusSliderChanged:(UISlider *)sender {
    self.radiusLabel.text = [NSString stringWithFormat:@"%.1f", sender.value];
}

- (void)updateAnnotationsAfterSearch:(NSArray *)newTours {
    if (self.mapAnnotations.count > 0) {
        [self.mapView removeAnnotations:self.mapAnnotations];
    }
    if (self.mapPoints.count > 0) {
        self.mapPoints = [NSMutableArray new];
    }
    for (Tour *tour in newTours) {
        CustomAnnotation *newPoint = [[CustomAnnotation alloc]init];
        newPoint.coordinate = CLLocationCoordinate2DMake(tour.startLocation.latitude, tour.startLocation.longitude);
        newPoint.title = tour.nameOfTour;
        newPoint.tourId = tour.objectId;
        if (self.mapAnnotations.count == 0) {
            self.mapAnnotations = [NSMutableArray arrayWithObject:newPoint];
        } else {
            [self.mapAnnotations addObject:newPoint];
        }
        CLLocation *location = [[CLLocation alloc] initWithLatitude:newPoint.coordinate.latitude longitude:newPoint.coordinate.longitude];
        
        if (self.mapPoints.count == 0) {
            self.mapPoints = [NSMutableArray arrayWithObject:location];
        } else {
            [self.mapPoints addObject:location];
        }
        [self.mapView addAnnotation:newPoint];
        [self.toursTableView reloadData];
    }
    
}

- (void)setRegionForCoordinate:(MKCoordinateRegion)region {
    [self.mapView setRegion:region animated:YES];
}

- (void)setMapForCoordinateWithLatitude: (double)lat  andLongitude:(double)longa {
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(lat, longa);
    MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(coordinate, 700.0, 700.0);
    [self setRegionForCoordinate:region];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:[MKUserLocation class]]) {
        return nil;
    }
    
    // Add view.
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *) [mapView dequeueReusableAnnotationViewWithIdentifier: @"AnnotationView"];
    annotationView.annotation = annotation;
    
    if (!annotationView) {
        annotationView = [[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:@"AnnotationView"];
    }
    
    //Add a detail disclosure button.
    annotationView.canShowCallout = true;
    annotationView.animatesDrop = true;
    annotationView.pinTintColor = [UIColor colorWithRed:0.278 green:0.510 blue:0.855 alpha:1.000];
    UIButton *rightCalloutButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
    annotationView.rightCalloutAccessoryView = rightCalloutButton;
    
    return annotationView;
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
    [self performSegueWithIdentifier:@"TabBarController" sender:view];
    
}

#pragma mark - CLLocationManager

-(void) startStandardUpdates
{
    
    if (nil == _locationManager)
        _locationManager = [[CLLocationManager alloc] init];
    
    _locationManager.delegate = self;
    _locationManager.desiredAccuracy = kCLLocationAccuracyKilometer;
    
    // Set a movement threshold for new events.
    _locationManager.distanceFilter = 100; // meters
    
    [_locationManager startUpdatingLocation];
}

- (void)startSignificantChangeUpdates {
    if (nil == _locationManager)
        _locationManager = [[CLLocationManager alloc] init];
    
    _locationManager.delegate = self;
    [_locationManager startMonitoringSignificantLocationChanges];
}


- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    if (status == kCLAuthorizationStatusAuthorizedWhenInUse) {
        [self.mapView setShowsUserLocation:YES];
        MKCoordinateRegion currentRegion = MKCoordinateRegionMakeWithDistance(self.locationManager.location.coordinate, 300, 300);
        [self.mapView setRegion:currentRegion];
        [self fetchToursNearUser];
    }
}

#pragma mark - UITableView protocol functions.

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    if (tableView.tag == 0) {
        return self.toursFromParse.count;
    } else {
        return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (tableView.tag == 0) {
        return 1;
    } else {
        return self.categoryList.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    if (tableView.tag == 0) {
        return 5.0;
    } else {
        return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [UIView new];
    if (tableView.tag == 0) {
        [headerView setBackgroundColor:[UIColor clearColor]];
        return headerView;
    } else {
        return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 0) {
        POIDetailTableViewCell *cell = (POIDetailTableViewCell*) [self.toursTableView dequeueReusableCellWithIdentifier:@"POIDetailTableViewCell"];
        cell.accessoryView = nil;
        cell.delegate = self;
        
        [cell.favoriteStarButton setTitle: @"☆" forState:UIControlStateNormal];
        if ([self.favoriteToursFromParse containsObject:self.toursFromParse[indexPath.section].objectId]) {
            [cell.favoriteStarButton setTitle:@"★" forState:UIControlStateNormal];
        }
              
        if (self.toursFromParse[indexPath.section].user == [PFUser currentUser]) {
            float cellHeight = cell.frame.size.height;
            UIButton *editButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, cellHeight, cellHeight)];
            [editButton setImage:[UIImage imageNamed:@"edit.png"] forState:UIControlStateNormal];
            [editButton addTarget:self action:@selector(editButtonTapped:event:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = editButton;
        }
        [cell setTour:[self.toursFromParse objectAtIndex:indexPath.section]];
        return cell;
    } else {
        UITableViewCell *cell = [self.searchCategoryTableView dequeueReusableCellWithIdentifier:@"CategoryTableViewCell" forIndexPath:indexPath];
        cell.textLabel.font = [UIFont fontWithName:@"Futura" size:17.0];
        cell.textLabel.textColor = [UIColor colorWithRed:0.278 green:0.510 blue:0.855 alpha:1.000];
        cell.textLabel.text = self.categoryList[indexPath.row];
        cell.accessoryType = UITableViewCellAccessoryNone;
        if ([self.selectedCategories containsObject:self.categoryList[indexPath.row]]) {
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }
        return cell;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}

-(CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 100;
}

-(void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    cell.layer.cornerRadius = 5;
    cell.layer.masksToBounds = true;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 0) {
        NSString *tourId = self.toursFromParse[indexPath.section].objectId;
        [self performSegueWithIdentifier:@"TabBarController" sender:tourId];
    } else {
        if ([tableView cellForRowAtIndexPath:indexPath].accessoryType == UITableViewCellAccessoryCheckmark) {
            [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
        } else {
            [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
        }
        if (self.selectedCategories.count > 0) {
            if ([self.selectedCategories containsObject:self.categoryList[indexPath.row]]) {
            [self.selectedCategories removeObjectAtIndex:[self.selectedCategories indexOfObject:[self.categoryList objectAtIndex:indexPath.row]]];
            } else {
                [self.selectedCategories addObject:self.categoryList[indexPath.row]];
            }
        } else {
            self.selectedCategories = [NSMutableArray arrayWithObject:self.categoryList[indexPath.row]];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if (tableView.tag == 0 && self.toursFromParse[indexPath.section].user == [PFUser currentUser]) {
        return YES;
    } else {
        return NO;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        Tour *tourToDelete = self.toursFromParse[indexPath.section];
        PFQuery *locationQuery = [PFQuery queryWithClassName:@"Location"];
        [locationQuery whereKey:@"tour" equalTo:tourToDelete];
        [locationQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
            if (error) {
                NSLog(@"Unable to find locations: %@", error.localizedFailureReason);
            }
            if (objects) {
                NSArray *objectsToDelete = [NSArray arrayWithObject:tourToDelete];
                objectsToDelete = [objectsToDelete arrayByAddingObjectsFromArray:objects];
                [PFObject deleteAllInBackground:objectsToDelete block:^(BOOL succeeded, NSError * _Nullable error) {
                    if (error) {
                        NSLog(@"Unable to delete objects: %@", error.localizedFailureReason);
                    }
                    if (succeeded) {
                        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                            [self.toursFromParse removeObjectAtIndex:indexPath.section];
                            [tableView deleteSections:[NSIndexSet indexSetWithIndex:indexPath.section] withRowAnimation:UITableViewRowAnimationFade];
                        }];
                    }
                }];
            }
        }];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    [self editTourAtIndexPath:indexPath];
}

- (void)editTourAtIndexPath:(NSIndexPath *)indexPath {
    Tour *selectedTour = self.toursFromParse[indexPath.section];
    CreateTourViewController *createVC = [self.storyboard instantiateViewControllerWithIdentifier:@"CreateTourViewController"];
    PFQuery *locationQuery = [PFQuery queryWithClassName:@"Location" predicate:[NSPredicate predicateWithFormat:@"tour == %@", selectedTour]];
    [locationQuery findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Unable to fetch locations: %@", error.localizedFailureReason);
        }
        if (objects) {
            NSArray *sortedResults = [objects sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
                Location *locationOne = (Location *)obj1;
                Location *locationTwo = (Location *)obj2;
                if (locationOne.orderNumber > locationTwo.orderNumber) {
                    return NSOrderedDescending;
                }
                if (locationOne.orderNumber < locationTwo.orderNumber) {
                    return NSOrderedAscending;
                }
                return NSOrderedSame;
            }];
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:createVC];
            createVC.tour = selectedTour;
            createVC.locations = [NSMutableArray arrayWithArray:sortedResults];
            createVC.editToursCompletion = ^{
                [self dismissViewControllerAnimated:YES completion:nil];
                //                navController.navigationBarHidden = NO;
            };
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                //                navController.navigationBarHidden = YES;
                [self presentViewController:navController animated:YES completion:nil];
            }];
        }
    }];
}

- (void)editButtonTapped:(UIButton *)sender event:(UIEvent *)event {
    NSSet *touches = event.allTouches;
    UITouch *touch = touches.anyObject;
    CGPoint currentTouchPosition = [touch locationInView:self.toursTableView];
    NSIndexPath *indexPath = [self.toursTableView indexPathForRowAtPoint:currentTouchPosition];
    if (indexPath != nil) {
        [self tableView:self.toursTableView accessoryButtonTappedForRowWithIndexPath:indexPath];
    }
}


#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"TabBarController"]) {
        if ([sender isKindOfClass:[MKAnnotationView class]]) {
            
            MKAnnotationView *annotationView = (MKAnnotationView *)sender;
            UITabBarController *tabBar = (UITabBarController *)segue.destinationViewController;
            
            TourMapViewController *tourMapViewController = (TourMapViewController *)tabBar.viewControllers.firstObject;
            TourListViewController *tourListViewController = (TourListViewController *)tabBar.viewControllers[1];
            
            if ([annotationView.annotation isKindOfClass:[CustomAnnotation class]]) {
                CustomAnnotation *annotation = (CustomAnnotation *)annotationView.annotation;
                
                // ...
                [tourMapViewController setCurrentTour:annotation.tourId];
                [tourListViewController setCurrentTour:annotation.tourId];
                tourListViewController.delegate = self;
            }
            
        } else {
            
            UITabBarController *tabBar = (UITabBarController *)segue.destinationViewController;
            
            TourMapViewController *tourMapViewController = (TourMapViewController *)tabBar.viewControllers.firstObject;
            TourListViewController *tourListViewController = (TourListViewController *)tabBar.viewControllers[1];
            
            if ([sender isKindOfClass:[NSString class]]) {
                [tourMapViewController setCurrentTour:sender];
                [tourListViewController setCurrentTour:sender];
                tourListViewController.delegate = self;
            }
        }
    }
}

#pragma mark - UISearchBarDelegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [self finalSearchButtonPressed:nil];
    [UIView animateWithDuration:0.3 animations:^{
        self.searchBarBottomConstraint.active = YES;
        if (self.view.frame.size.height < 600.0) {
            self.searchViewTopConstraint.constant += 40;
        }
        if (self.view.frame.size.height < 500.0) {
            self.searchViewTopConstraint.constant += 40;
        }
        [self.searchCategoryTableView setFrame:self.searchCategoryTableViewFrame];
        [self.view layoutIfNeeded];
    }];
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [UIView animateWithDuration:0.3 animations:^{
        self.searchBarBottomConstraint.active = YES;
        if (self.view.frame.size.height < 600.0) {
            self.searchViewTopConstraint.constant += 40;
        }
        if (self.view.frame.size.height < 500.0) {
            self.searchViewTopConstraint.constant += 40;
        }
        [self.searchCategoryTableView setFrame:self.searchCategoryTableViewFrame];
        [self.view layoutIfNeeded];
    }];
}

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    self.searchCategoryTableViewFrame = self.searchCategoryTableView.frame;
    [UIView animateWithDuration:0.3 animations:^{
        self.searchBarBottomConstraint.active = NO;
        if (self.view.frame.size.height < 600.0) {
            self.searchViewTopConstraint.constant -= 40;
        }
        if (self.view.frame.size.height < 500.0) {
            self.searchViewTopConstraint.constant -= 40;
        }
        [self.searchCategoryTableView setFrame:CGRectMake(self.searchCategoryTableViewFrame.origin.x, self.searchCategoryTableViewFrame.origin.y, self.searchCategoryTableViewFrame.size.width, 0)];
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - TourListViewControllerDelegate

- (void)deletedTourWithTour:(Tour *)tour {
    NSUInteger index = [self.toursFromParse indexOfObject:tour];
    [self.toursFromParse removeObjectAtIndex:index];
    [self.toursTableView deleteSections:[NSIndexSet indexSetWithIndex:index] withRowAnimation:UITableViewRowAnimationFade];
}

#pragma mark - POIDetailTableViewCellDelegate
-(void)favoriteButtonPressedForTourID:(NSString *)tourId{
    
    if (tourId !=nil) {
        BOOL isAlreadyAFavoriteTour = [self.favoriteToursFromParse containsObject:tourId];
        
        if (isAlreadyAFavoriteTour) {
            [self.favoriteToursFromParse removeObject:tourId];
        } else {
            if (self.favoriteToursFromParse) {
                [self.favoriteToursFromParse addObject:tourId];
            } else {
                self.favoriteToursFromParse = [NSMutableArray arrayWithObject:tourId];
            }
        }
    }
}

@end


