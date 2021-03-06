//
//  TourDetailViewController.m
//  WalkingTours
//
//  Created by Miles Ranisavljevic on 12/14/15.
//  Copyright © 2015 Lindsey Boggio. All rights reserved.
//
#import "TourDetailViewController.h"
#import "TourListViewController.h"
#import "TourMapViewController.h"
#import "VideoPlayerView.h"
#import "Location.h"
@import Parse;

static const NSString *ItemStatusContext;

@interface TourDetailViewController () <UINavigationControllerDelegate>

@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *playerItem;
@property (nonatomic, weak) IBOutlet VideoPlayerView *playerView;
@property (nonatomic, weak) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UILabel *locationNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationAddressLabel;
@property (weak, nonatomic) IBOutlet UILabel *locationDescriptionLabel;
@property (nonatomic, strong) NSString *locationData;
@property (strong, nonatomic) UIColor *navBarTintColor;
- (IBAction)playButtonPressed:(UIButton *)sender;

@end

@implementation TourDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];    
    [self setButtonStatus];
    self.navigationController.delegate = self;
    UIColor *tintColor = self.navigationController.navigationBar.tintColor;
    self.navBarTintColor = tintColor;
    self.navigationController.navigationBar.tintColor = [UIColor colorWithWhite:0.951 alpha:1.000];
    if (self.location) {
        self.locationNameLabel.text = self.location.locationName;
        self.locationDescriptionLabel.text = self.location.locationDescription;
        if (self.location.locationAddress) {
            self.locationAddressLabel.text = self.location.locationAddress;
        } else {
            self.locationAddressLabel.hidden = YES;
            CGRect labelFrame = self.locationAddressLabel.frame;
            labelFrame.size.height = 0;
            self.locationAddressLabel.frame = labelFrame;            
        }
        if (!self.location.video) {
            self.playButton.hidden = YES;
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.playerItem removeObserver:self forKeyPath:@"status" context:&ItemStatusContext];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (void)setLocation:(Location *)location {
    _location = location;
    if (location.video) {
        NSURL *videoUrl = [NSURL URLWithString:location.video.url];
        [self loadVideoAsset:videoUrl];
    } else {
        if (location.photo) {
            [location.photo getDataInBackgroundWithBlock:^(NSData * _Nullable data, NSError * _Nullable error) {
                if (error) {
                    NSLog(@"%@", error.localizedFailureReason);
                }
                if (data) {
                    UIImage *image = [UIImage imageWithData:data];
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.playerView.bounds];
                        [imageView setClipsToBounds:YES];
                        imageView.contentMode = UIViewContentModeScaleAspectFill;
                        imageView.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
                        imageView.layer.cornerRadius = 5.0;
                        [self.playerView addSubview:imageView];
                        imageView.image = image;
                    }];
                }
            }];
        } else {
            UIImage *image = [UIImage imageNamed:@"placeholder"];
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.playerView.bounds];
                [imageView setClipsToBounds:YES];
                imageView.contentMode = UIViewContentModeScaleAspectFill;
                imageView.backgroundColor = [UIColor colorWithWhite:0 alpha:0];
                imageView.layer.cornerRadius = 5.0;
                [self.playerView addSubview:imageView];
                imageView.image = image;
            }];
        }
    }
}

#pragma mark - Video player functions

- (void)loadVideoAsset:(NSURL *)url {
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSString *tracksKey = @"tracks";
    
    [asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler: ^ {
        dispatch_async(dispatch_get_main_queue(), ^ {
            NSError *error;
            AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
            
            if (status == AVKeyValueStatusLoaded) {
                AVPlayerLayer *playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
                playerLayer.frame = self.playerView.bounds;
                [self.playerView.layer addSublayer:playerLayer];
                self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                [self.playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial context:&ItemStatusContext];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
                self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
                [playerLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
                playerLayer.cornerRadius = 5.0;
                [self.playerView setPlayer:self.player];
            }
            else {
                NSLog(@"The asset's tracks were not loaded: %@", [error localizedDescription]);
            }
        });
    }];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self.player seekToTime:kCMTimeZero];
    [UIView animateWithDuration:0.4 animations:^{
        self.playButton.alpha = 1.0;
    }];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == &ItemStatusContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setButtonStatus];
        });
        return;
    }
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    return;
}

- (void)setButtonStatus {
    if ((self.player.currentItem != nil) &&
        ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
        self.playButton.enabled = YES;
    }
    else {
        self.playButton.enabled = NO;
    }
}

- (IBAction)playButtonPressed:(UIButton *)sender {
    [UIView animateWithDuration:0.4 animations:^{
        self.playButton.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (finished) {
            [self.player play];
        }
    }];
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (![viewController isKindOfClass:[TourDetailViewController class]]) {
        self.navigationController.navigationBar.tintColor = self.navBarTintColor;
    }
}

@end
