//
//  ImageViewController.m
//  ImaginariumMy
//
//  Created by Tatiana Kornilova on 12/14/13.
//  Copyright (c) 2013 Tatiana Kornilova. All rights reserved.
//

#import "ImageViewController.h"

@interface ImageViewController () <UIScrollViewDelegate, UISplitViewControllerDelegate>
@property (nonatomic,strong) UIImageView *imageView;
@property (nonatomic,strong) UIImage *image;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *spinner;
@property (nonatomic, getter = isAutoZoomed) BOOL autoZoomed;
@end

@implementation ImageViewController

-(void)setScrollView:(UIScrollView *)scrollView
{
    _scrollView = scrollView;
    _scrollView.minimumZoomScale = 0.2;
    _scrollView.maximumZoomScale = 2.0;
    _scrollView.delegate =self;
    self.scrollView.contentSize = self.image ? self.image.size : CGSizeZero;
}

-(UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

// Disable autoZoom after the user performs a zoom (by pinching)
- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(UIView *)view
{
    self.autoZoomed = NO;
}

-(void)setImageURL:(NSURL *)imageURL
{
    _imageURL =imageURL;
    [self startDownLoadImage];
}

-(void)startDownLoadImage
{
    self.image =nil;

    if (self.imageURL) {
        [self.spinner startAnimating];
        NSURLRequest *request = [NSURLRequest requestWithURL:self.imageURL];
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL *localfile, NSURLResponse *response, NSError *error) {
            if (!error) {
                if ([request.URL isEqual:self.imageURL]) {
                    UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:localfile]];
                    dispatch_async(dispatch_get_main_queue(), ^{self.image =image;});
                }
            }
        }];
        [task resume];
    }
}

-(UIImageView *)imageView
{
    if (!_imageView)_imageView=[[UIImageView alloc] init];
    return _imageView;
}

-(UIImage *)image
{
    return self.imageView.image;
}

-(void)setImage:(UIImage *)image
{
    self.scrollView.zoomScale =1.0;
    self.imageView.image =image;
    self.imageView.frame =CGRectMake(0, 0, image.size.width, image.size.height);
    self.scrollView.contentSize = self.image ? self.image.size : CGSizeZero;
    self.autoZoomed = YES;
    [self zoomScaleToFit];
    [self.spinner stopAnimating];
}

// Calculate zoom scale to fit the image in the screen without blank spaces
- (void)zoomScaleToFit
{
    // if is AutoZoomed then set the zoomScale property only if the geometry is completely loaded
    if ((self.isAutoZoomed)&&(self.imageView.bounds.size.width)&&(self.scrollView.bounds.size.width)) {
        CGFloat widthRatio  = self.scrollView.bounds.size.width  / self.imageView.bounds.size.width;
        CGFloat heightRatio = self.scrollView.bounds.size.height / self.imageView.bounds.size.height;
        self.scrollView.zoomScale = (widthRatio > heightRatio) ? widthRatio : heightRatio;
    }
}

// When subviews are layed out we set the zoom to make the image fit the screen.
- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self zoomScaleToFit];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    [self.scrollView addSubview:self.imageView];
}

#pragma UISplitViewControllerDelegate

-(void)awakeFromNib
{
    self.splitViewController.delegate =self;
}

-(BOOL)splitViewController:(UISplitViewController *)svc
  shouldHideViewController:(UIViewController *)vc
             inOrientation:(UIInterfaceOrientation)orientation
{
    return UIInterfaceOrientationIsPortrait(orientation);
}

-(void)splitViewController:(UISplitViewController *)svc
    willHideViewController:(UIViewController *)aViewController
         withBarButtonItem:(UIBarButtonItem *)barButtonItem
      forPopoverController:(UIPopoverController *)pc
{
    UIViewController *aVC = aViewController;
    if ([aVC isKindOfClass:[UITabBarController class]]) {
        aVC = ((UITabBarController *)aVC).selectedViewController;
    }
    if ([aVC isKindOfClass:[UINavigationController class]]) {
        aVC = ((UINavigationController *)aVC).topViewController;
    }
    if (aVC) {
        barButtonItem.title = aVC.title;
    } else {
        barButtonItem.title = @"Regions";
    }

    self.navigationItem.leftBarButtonItem =barButtonItem;
    
}

-(void)splitViewController:(UISplitViewController *)svc
    willShowViewController:(UIViewController *)aViewController
 invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    self.navigationItem.leftBarButtonItem =nil;
}
@end
