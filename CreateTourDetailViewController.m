//
//  CreateTourDetailViewController.m
//  WalkingTours
//
//  Created by Miles Ranisavljevic on 12/14/15.
//  Copyright © 2015 Lindsey Boggio. All rights reserved.
//

#import "CreateTourDetailViewController.h"
#import "CategoryTableViewCell.h"
@import MobileCoreServices;
@import CoreLocation;
@import Parse;

static const NSArray *categories;

@interface CreateTourDetailViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate>

- (IBAction)cameraButtonPressed:(UIButton *)sender;
@property (strong, nonatomic) UIImagePickerController *imagePicker;
@property (strong, nonatomic) UIView *greyOutView;
@property (strong, nonatomic) UITableView *categoryTableView;
@property (strong, nonatomic) UIButton *finalSaveButton;
@property (strong, nonatomic) NSMutableArray *selectedCategories;
@property (strong, nonatomic) PFFile *mediaFile;
@property (strong, nonatomic) PFGeoPoint *geoPoint;
@property (strong, nonatomic) Location *location;

@end

@implementation CreateTourDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveLocation:)];
    self.navigationItem.rightBarButtonItem = saveButton;
    [self setUpGreyOutView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

#pragma mark - Setup Functions

- (void)setCategoryOptions {
    categories = @[@"Restaurant", @"Cafe", @"Art", @"Museum", @"History", @"Shopping", @"Nightlife"];
}

- (void)setUpGreyOutView {
    self.greyOutView = [[UIView alloc] initWithFrame:CGRectMake(self.view.center.x, self.view.center.y, 0, 0)];
    
    self.greyOutView.backgroundColor = [UIColor colorWithWhite:0.737 alpha:0.500];
    
    [self.greyOutView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.view addSubview:self.greyOutView];
    
    [self setUpFinalSaveButton];
    
    [self setUpTableView];
}

- (void)setUpFinalSaveButton {
    self.finalSaveButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.center.x, self.view.center.y, 0, 0)];
    [self.finalSaveButton setTitle:@"Save" forState:UIControlStateNormal];
    [self.finalSaveButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.finalSaveButton setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.view addSubview:self.finalSaveButton];
    [self.finalSaveButton addTarget:self action:@selector(saveLocationWithCategories:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)setUpTableView {
    self.categoryTableView = [[UITableView alloc] initWithFrame:CGRectMake(self.view.center.x, self.view.center.y, 0, 0)];
    
    [self setCategoryOptions];
    self.categoryTableView.dataSource = self;
    self.categoryTableView.delegate = self;
    
    UINib *categoryNib = [UINib nibWithNibName:@"CategoryTableViewCell" bundle:[NSBundle mainBundle]];
    [self.categoryTableView registerNib:categoryNib forCellReuseIdentifier:@"cell"];
    
    [self.categoryTableView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    [self.view addSubview:self.categoryTableView];
}

#pragma mark - User Interaction Functions

- (void)loadImagePicker {
    if (!self.imagePicker) {
        self.imagePicker = [[UIImagePickerController alloc] init];
        self.imagePicker.delegate = self;
        
        if ([UIImagePickerController isSourceTypeAvailable:(UIImagePickerControllerSourceTypeCamera)] && [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear]) {
            NSArray *availableMediaTypes = [UIImagePickerController availableMediaTypesForSourceType:UIImagePickerControllerSourceTypeCamera];
            if ([availableMediaTypes containsObject:(NSString *)kUTTypeMovie]) {
                self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
                self.imagePicker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString *)kUTTypeImage, (NSString *)kUTTypeMovie, nil];
            }
            self.imagePicker.showsCameraControls = YES;
            self.imagePicker.allowsEditing = YES;
        }
    }
    [self presentViewController:self.imagePicker animated:YES completion:nil];
}

- (void)displayCategories {
    [self.view layoutIfNeeded];
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:self.greyOutView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:0];
    NSLayoutConstraint *trailing = [NSLayoutConstraint constraintWithItem:self.greyOutView attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0];
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:self.greyOutView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0];
    NSLayoutConstraint *leading = [NSLayoutConstraint constraintWithItem:self.greyOutView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0];
    
    top.active = YES;
    trailing.active = YES;
    bottom.active = YES;
    leading.active = YES;
    
    NSLayoutConstraint *tableViewBottom = [NSLayoutConstraint constraintWithItem:self.categoryTableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1.0 constant:-(self.view.frame.size.height / 2)];
    NSLayoutConstraint *tableViewHeight = [NSLayoutConstraint constraintWithItem:self.categoryTableView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeHeight multiplier:0.6 constant:-(self.view.frame.size.height * 0.6)];
    NSLayoutConstraint *tableViewWidth = [NSLayoutConstraint constraintWithItem:self.categoryTableView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeWidth multiplier:0.8 constant:-(self.view.frame.size.width) * 0.8];
    NSLayoutConstraint *tableViewCenterX = [NSLayoutConstraint constraintWithItem:self.categoryTableView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0.0];
    
    tableViewBottom.active = YES;
    tableViewHeight.active = YES;
    tableViewWidth.active = YES;
    tableViewCenterX.active = YES;
    
    NSLayoutConstraint *buttonTop = [NSLayoutConstraint constraintWithItem:self.finalSaveButton attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1.0 constant:20];
    NSLayoutConstraint *buttonTrailing = [NSLayoutConstraint constraintWithItem:self.finalSaveButton attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-20];
    
    [UIView animateKeyframesWithDuration:0.8 delay:0 options:UIViewKeyframeAnimationOptionLayoutSubviews animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.5 animations:^{
            self.navigationController.navigationBarHidden = YES;
            [self.view layoutIfNeeded];
            
        }];
        
        tableViewBottom.constant = -30.0;
        tableViewHeight.constant = 0;
        tableViewWidth.constant = 0;
        [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
            [self.view layoutIfNeeded];
        }];
        buttonTop.active = YES;
        buttonTrailing.active = YES;
        [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
            [self.view layoutIfNeeded];
        }];
    } completion:^(BOOL finished) {
        //
    }];
}

- (IBAction)cameraButtonPressed:(UIButton *)sender {
        [self loadImagePicker];
}

//- (void)saveLocation:(UIBarButtonItem *)sender {
//    if (self.locationNameTextField.text.length > 0 && self.locationDescriptionTextField.text.length > 0 && self.geoPoint != nil) {
//        //Create a location with no tour and no categories.
//        //If a photo isn't taken it'll pass a nil reference.
//        Location *location = [[Location alloc] initWithLocationName:self.locationNameTextField.text locationDescription:self.locationDescriptionTextField.text photo:self.mediaFile categories:nil location:self.geoPoint tour:nil];
//        self.location = location;
//        [self displayCategories];
//    } else {
//        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"What!?!" message:@"Fill everything out!" preferredStyle:UIAlertControllerStyleAlert];
//        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
//        [alertController addAction:okAction];
//        [self presentViewController:alertController animated:YES completion:nil];
//    }
//}

- (void)saveLocationWithCategories:(UIButton *)sender {
    if (self.location != nil && self.selectedCategories.count > 0) {
        self.location.categories = self.selectedCategories;
        if (self.delegate) {
            [self.delegate didFinishSavingLocationWithLocation:self.location];
        }
        [self.navigationController popViewControllerAnimated:YES];
    }
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    NSLog(@"Why'd you cancel?");
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    NSData *mediaData;
    PFFile *mediaFile;
    if ([info objectForKey:@"UIImagePickerControllerMediaURL"]) {
        NSLog(@"So, you've made a movie...");
        mediaData = [NSData dataWithContentsOfURL:[info objectForKey:@"UIImagePickerControllerMediaURL"]];
        mediaFile = [PFFile fileWithName:[NSString stringWithFormat:@"%i.mp4", rand() / 2] data:mediaData];
    }
    if ([info objectForKey:@"UIImagePickerControllerEditedImage"]) {
        NSLog(@"Ah, just a photo?");
        mediaData = UIImageJPEGRepresentation([info objectForKey:@""], 1.0);
        mediaFile = [PFFile fileWithName:[NSString stringWithFormat:@"%i.jpg",rand() / 2] data:mediaData];
    }
    self.mediaFile = mediaFile;
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewControllerDelegate & UITableViewControllerDatasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return categories.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CategoryTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    [cell setCategory:categories[indexPath.row]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([tableView cellForRowAtIndexPath:indexPath].accessoryType == UITableViewCellAccessoryCheckmark) {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryNone;
    } else {
        [tableView cellForRowAtIndexPath:indexPath].accessoryType = UITableViewCellAccessoryCheckmark;
    }
    if (self.selectedCategories.count > 0) {
        if ([self.selectedCategories containsObject:categories[indexPath.row]]) {
            [self.selectedCategories removeObjectAtIndex:[self.selectedCategories indexOfObject:[categories objectAtIndex:indexPath.row]]];
        } else {
            [self.selectedCategories addObject:categories[indexPath.row]];
        }
    } else {
        self.selectedCategories = [NSMutableArray arrayWithObject:categories[indexPath.row]];
    }
}

#pragma mark - Test Funcs

//- (void)addTestModelsToParse:(PFFile *)media {
//    CLLocationCoordinate2D location = CLLocationCoordinate2DMake(47.623544, -122.336224);
//    PFGeoPoint *geoPoint = [PFGeoPoint geoPointWithLatitude:location.latitude longitude:location.longitude];
//    Tour *tour1 = [[Tour alloc] initWithNameOfTour:@"Tour 1" descriptionText:@"This is a tour." startLocation:geoPoint user:[PFUser currentUser]];
//    Location *location1 = [[Location alloc] initWithLocationName:@"Code Fellows" locationDescription:@"This is where we practically live" photo:media categories:@[@"School", @"Education"] location:geoPoint tour:tour1];
//    PFGeoPoint *geoPoint2 = [PFGeoPoint geoPointWithLatitude:47.627825 longitude:-122.337412];
//    Location *location2 = [[Location alloc] initWithLocationName:@"The Park" locationDescription:@"I remember what the sun was like..." photo:media categories:@[@"Park", @"Not Coding"] location:geoPoint2 tour:tour1];
//    NSArray *objectArray = [NSArray arrayWithObjects:tour1, location1, location2, nil];
//    [PFObject saveAllInBackground:objectArray block:^(BOOL succeeded, NSError * _Nullable error) {
//        if (succeeded) {
//            NSLog(@"They saved!");
//        } else {
//            NSLog(@"Something went terribly wrong.");
//        }
//    }];
//}

@end
