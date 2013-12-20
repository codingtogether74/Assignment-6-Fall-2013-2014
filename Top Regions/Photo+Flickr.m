//
//  Photo+Flickr.m
//  Photomania
//
//  Created by Tatiana Kornilova on 12/17/13.
//  Copyright (c) 2013 Tatiana Kornilova. All rights reserved.
//

#import "Photo+Flickr.h"
#import "FlickrFetcher.h"
#import "Photographer+Create.h"
#import "Region+Create.h"

@implementation Photo (Flickr)

+ (Photo *)photoWithFlickrInfo:(NSDictionary *)photoDictionary
        inManagedObjectContext:(NSManagedObjectContext *)context
{
    Photo *photo =nil;
 
    NSString *unique = photoDictionary[FLICKR_PHOTO_ID];
    NSFetchRequest *request =[NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.predicate = [NSPredicate predicateWithFormat:@"unique = %@",unique];
    
    NSError *error;
    NSArray *matches =[context executeFetchRequest:request error:&error];
    if (!matches || error || ([matches count]>1)) {
        // handle error
    }else if ([matches count]){
        photo = [matches firstObject];
    }else {
        photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
        photo.unique =unique;
        photo.title = [photoDictionary valueForKeyPath:FLICKR_PHOTO_TITLE];
        photo.subtitle =[photoDictionary valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
        photo.imageURL = [[FlickrFetcher URLforPhoto:photoDictionary format:FlickrPhotoFormatLarge] absoluteString];
        
        NSString *photographerName =[photoDictionary valueForKeyPath:FLICKR_PHOTO_OWNER];
        photo.whoTook = [Photographer photographerWithName:photographerName
                                             andRegionName:[photoDictionary valueForKey:@"region"]
                                    inManagedObjectContext:context];
        //---
        photo.region = [Region regionForPhotosWithName:[photoDictionary valueForKey:@"region"]
                                inManagedObjectContext:context];
    }
    return photo;
 
}

+(void)loadPhotosFromFlickrArray:(NSArray *)photos // of Flickr NSDictionary
        intoManagedObjectContext:(NSManagedObjectContext *)context
{
//    for (NSDictionary *photo in photos) {
//----
        dispatch_queue_t placeQ =dispatch_queue_create("place fetcher", NULL);
        dispatch_async(placeQ, ^{
    for (NSDictionary *photo in photos) {

            NSMutableDictionary *photoWithRegion =[photo mutableCopy];
            NSURL *urlPlace =[FlickrFetcher URLforInformationAboutPlace:[photo valueForKeyPath: FLICKR_PHOTO_PLACE_ID]];
            
            NSData *jsonResults = [NSData dataWithContentsOfURL:urlPlace];
            NSDictionary *placeInformation =[NSJSONSerialization JSONObjectWithData:jsonResults
                                                                            options:0
                                                                              error:NULL];
            NSString *region = [FlickrFetcher extractRegionNameFromPlaceInformation:placeInformation];
//            NSLog(@"region = %@",region);
            
            if (region) {
                [photoWithRegion setObject:region forKey:@"region"];
            }else{
                [photoWithRegion setObject:@"Unknown" forKey:@"region"];

            }

//----
        [self photoWithFlickrInfo:photoWithRegion inManagedObjectContext:context];
    }
          });
    
}



@end
