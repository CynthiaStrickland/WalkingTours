//
//  CreateTourViewController.m
//  WalkingTours
//
//  Created by Lindsey on 12/14/15.
//  Copyright © 2015 Lindsey Boggio. All rights reserved.
//

#import "CreateTourViewController.h"
#import "Location.h"
#import <Parse/Parse.h>
#import "LocationTableViewCell.h"
#import "CreateTourDetailViewController.h"
#import "ParseService.h"
#import "Tour.h"




@interface CreateTourViewController() <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate, CreateTourDetailViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameOfTourTextField;
@property (weak, nonatomic) IBOutlet UITextField *tourDescriptionTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *addLocationButtonBottomConstraint;

@property (weak, nonatomic) IBOutlet UIButton *addLocationButton;
- (IBAction)addLocationsButton:(id)sender;

@property (weak, nonatomic) IBOutlet UITableView *locationTableView;
@property (strong, nonatomic) NSMutableArray<Location *> *locations;
@property (strong, nonatomic) NSMutableArray<UIImage *> *images;



@end

@implementation CreateTourViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    [self setupMainViewController];
    self.addLocationButton.layer.cornerRadius = self.addLocationButton.frame.size.width / 2;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (self.locations.count == 0) {
        self.addLocationButtonBottomConstraint.constant = self.view.frame.size.height / 2;
    } else {
        self.addLocationButtonBottomConstraint.constant = 30;
    }
}

-(void)setupMainViewController{
    
    self.locationTableView.delegate = self;
    self.locationTableView.dataSource = self;
    [self.nameOfTourTextField setDelegate:self];
    [self.tourDescriptionTextField setDelegate:self];
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonSelected:)]];
    
    UINib *nib = [UINib nibWithNibName:@"LocationTableViewCell" bundle:nil];
    [[self locationTableView]registerNib:nib forCellReuseIdentifier:@"LocationTableViewCell"];
    
}

- (IBAction)addLocationsButton:(id)sender {
    
}

#pragma mark set up TableView

#pragma mark - UITableView protocol functions.

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.locations.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 5.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *headerView = [UIView new];
    [headerView setBackgroundColor:[UIColor clearColor]];
    
    return headerView;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
   LocationTableViewCell *cell = (LocationTableViewCell *)[self.locationTableView dequeueReusableCellWithIdentifier:@"LocationTableViewCell" forIndexPath:indexPath];
    [cell setLocation:self.locations[indexPath.section]];
    [cell setImage:self.images[indexPath.section]];
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.layer.cornerRadius = 5;
    cell.layer.masksToBounds = true;
}

//custom setter on location Array it reloads data

#pragma mark -UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    if (textField.tag == 0) {
        [self.tourDescriptionTextField becomeFirstResponder];
    }
    return YES;
}

#pragma mark Save to Parse

-(void)saveButtonSelected:(UIBarButtonItem *)sender{
    if (self.nameOfTourTextField.text.length == 0 || self.tourDescriptionTextField.text.length == 0) {
        UIAlertController *noTextinFieldAlert = [UIAlertController alertControllerWithTitle:@"Missing Text" message:@"Please enter the name and description for your tour" preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}];
        [noTextinFieldAlert addAction:defaultAction];
        [self presentViewController:noTextinFieldAlert animated:YES completion:nil];
        return;
    }
    if (self.locations.count ==0) {
        UIAlertController *noLocationAlert = [UIAlertController alertControllerWithTitle:@"Missing Locations" message:@"Please add at least one location." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){}];
        [noLocationAlert addAction:defaultAction];
        [self presentViewController:noLocationAlert animated:YES completion:nil];
        return;
    }
    Tour *tour = [[Tour alloc] initWithNameOfTour:self.nameOfTourTextField.text descriptionText:self.tourDescriptionTextField.text startLocation:self.locations.firstObject.location user:[PFUser currentUser]];
    NSMutableArray *saveArray;
    for (Location *location in self.locations) {
        location.tour = tour;
        if (saveArray.count == 0) {
            saveArray = [NSMutableArray arrayWithObject:location];
        } else {
            [saveArray addObject:location];
        }
    }
    
    [ParseService saveToParse:tour locations:saveArray completion:^(BOOL success, NSError *error) {
        if (success) {
            [self.navigationController popToRootViewControllerAnimated:YES];
        } else {
            NSLog(@"Error saving: %@", error.localizedFailureReason);
        }
    }];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier  isEqual: @"SegueToCreateTourDetailVC"]) {
        if ([segue.destinationViewController isKindOfClass:[CreateTourDetailViewController class]]) {
            CreateTourDetailViewController *detailVC = (CreateTourDetailViewController *)segue.destinationViewController;
            detailVC.createTourDetailDelegate = self;
        }
    }
}

- (void)didFinishSavingLocationWithLocation:(Location *)location image:(UIImage *)image {
    if (self.locations.count > 0) {
        [self.locations addObject:location];
        [self.images addObject:image];
    } else {
        self.locations = [NSMutableArray arrayWithObject:location];
        self.images = [NSMutableArray arrayWithObject:image];
    }
    [self.locationTableView reloadData];
}

@end
