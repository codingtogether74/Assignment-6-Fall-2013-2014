//
//  TopRegionsCDTVC.m
//  Top Regions
//
//  Created by Tatiana Kornilova on 12/22/13.
//  Copyright (c) 2013 Tatiana Kornilova. All rights reserved.
//

#import "TopRegionsCDTVC.h"
#import "FlickrFetcher.h"
#import "DBHelper.h"
#import "Photo+Flickr.h"
#import "NetworkIndicatorHelper.h"

@interface TopRegionsCDTVC ()

@end

@implementation TopRegionsCDTVC

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleUpdatedData:)
                                                 name:@"DataUpdated"
                                               object:nil];
//    [self fetchTopPlaces];
}

-(void)handleUpdatedData:(NSNotification *)notification {
   [self.refreshControl endRefreshing]; // stop the spinner
    NSLog(@"Data updated");
}

-(IBAction)fetchTopPlaces
{
    [self.refreshControl beginRefreshing]; // start the spinner
    [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height) animated:YES];
    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    sessionConfig.allowsCellularAccess = YES;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfig];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[FlickrFetcher URLforRecentGeoreferencedPhotos]];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request
                                                    completionHandler:^(NSURL *localFile, NSURLResponse *response, NSError *error) {
                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                            [NetworkIndicatorHelper setNetworkActivityIndicatorVisible:NO];
                                                        });
                                                        if (error) {
                                                            NSLog(@"Flickr background fetch failed: %@", error.localizedDescription);
                                                        } else {
                                                            
                                                            [self loadFlickrPhotosFromLocalURL:localFile];
                                                        }
                                                    }];
    [NetworkIndicatorHelper setNetworkActivityIndicatorVisible:YES];
    [task resume];
}
- (NSArray *)flickrPhotosAtURL:(NSURL *)url
{
    NSDictionary *flickrPropertyList;
    NSData *flickrJSONData = [NSData dataWithContentsOfURL:url];
    if (flickrJSONData) {
        flickrPropertyList = [NSJSONSerialization JSONObjectWithData:flickrJSONData
                                                             options:0
                                                               error:NULL];
    }
    return [flickrPropertyList valueForKeyPath:FLICKR_RESULTS_PHOTOS];
}

- (void)useRegionDocumentWithFlickrPhotos:(NSArray *)photos
{
    [[DBHelper sharedManagedDocument] performWithDocument:^(UIManagedDocument *document) {
        self.managedObjectContext = document.managedObjectContext;
        
        [Photo load1PhotosFromFlickrArray:photos intoManagedObjectContext:self.managedObjectContext];
        [document saveToURL:document.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:NULL];
    }];
}

- (void)loadFlickrPhotosFromLocalURL:(NSURL *)localFile
{
    NSArray *photos = [self flickrPhotosAtURL:localFile];
    [self useRegionDocumentWithFlickrPhotos:photos];
}


@end
