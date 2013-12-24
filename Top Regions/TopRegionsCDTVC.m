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
//   [self fetchTopPlaces];
}

-(void)handleUpdatedData:(NSNotification *)notification {
    if(self.refreshControl.isRefreshing)  [self.refreshControl endRefreshing]; // stop the spinner
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
-(IBAction)fetchTopPlaces1
{
    [self.refreshControl beginRefreshing]; // start the spinner
    [self.tableView setContentOffset:CGPointMake(0, -self.refreshControl.frame.size.height) animated:YES];
    
    NSURL *url = [FlickrFetcher URLforRecentGeoreferencedPhotos];
    // create a (non-main) queue to do fetch on
    dispatch_queue_t fetchQ = dispatch_queue_create("flickr fetcher", NULL);
    // put a block to do the fetch onto that queue
    dispatch_async(fetchQ, ^{
        // fetch the JSON data from Flickr
        NSData *jsonResults = [NSData dataWithContentsOfURL:url];
        // convert it to a Property List (NSArray and NSDictionary)
        NSDictionary *results = [NSJSONSerialization JSONObjectWithData:jsonResults
                                                                options:0
                                                                  error:NULL];
        // get the NSArray of places NSDictionarys out of the results
        NSArray *photos = [results valueForKeyPath:FLICKR_RESULTS_PHOTOS];
        // update the Model (and thus our UI), but do so back on the main queue
        dispatch_async(dispatch_get_main_queue(), ^{
            [self useRegionDocumentWithFlickrPhotos:photos];

//            [self.refreshControl endRefreshing]; // stop the spinner

        });
    });
    
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
