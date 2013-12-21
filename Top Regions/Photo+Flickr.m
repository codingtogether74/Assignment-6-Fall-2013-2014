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

#define FLICKR_UNKNOWN_PHOTO @"Unknown"

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
        if ([photo.title length]== 0) {
            photo.title = [[photoDictionary valueForKeyPath:FLICKR_PHOTO_DESCRIPTION] description];
            if ([photo.title length]== 0) {
                photo.title = FLICKR_UNKNOWN_PHOTO;
            }
        }
        photo.subtitle =[photoDictionary valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
        if ([photo.title isEqualToString:photo.subtitle] || [photo.title isEqualToString:FLICKR_UNKNOWN_PHOTO]) {
            photo.subtitle = @"";
        }
        photo.imageURL = [[FlickrFetcher URLforPhoto:photoDictionary format:FlickrPhotoFormatLarge] absoluteString];
        photo.thumbnailURL = [[FlickrFetcher URLforPhoto:photoDictionary format:FlickrPhotoFormatSquare] absoluteString];

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
    //----
    dispatch_queue_t placeQ =dispatch_queue_create("place fetcher", NULL);
    dispatch_async(placeQ, ^{
        NSMutableArray *photoIds =[[NSMutableArray alloc] init];
        NSMutableArray *photosWithRegion =[[NSMutableArray alloc] init];
        for (NSDictionary *photo in photos) {
            NSMutableDictionary *photoWithRegion =[photo mutableCopy];
            NSURL *urlPlace =[FlickrFetcher URLforInformationAboutPlace:[photo valueForKeyPath: FLICKR_PHOTO_PLACE_ID]];
            
            NSData *jsonResults = [NSData dataWithContentsOfURL:urlPlace];
            NSDictionary *placeInformation =[NSJSONSerialization JSONObjectWithData:jsonResults
                                                                            options:0
                                                                              error:NULL];
            NSString *region = [FlickrFetcher extractRegionNameFromPlaceInformation:placeInformation];
            NSLog(@"region = %@",region);
            
            if (region) {
                [photoWithRegion setObject:region forKey:@"region"];
            }else{
                [photoWithRegion setObject:@"Unknown" forKey:@"region"];
                
            }
            [photoIds addObject:photo[FLICKR_PHOTO_ID]];
            [photosWithRegion addObject:photoWithRegion];
            //----
            dispatch_async(dispatch_get_main_queue(), ^{
                [self photoWithFlickrInfo:photoWithRegion inManagedObjectContext:context];
            });
        }
 //       dispatch_async(dispatch_get_main_queue(), ^{
 //           [self photosWithFlickrInfo:photosWithRegion andPhotoIds:photoIds inManagedObjectContext:context];
 //       });

    });
    
}

+ (NSArray *)photosWithFlickrInfo:(NSArray *)photoDictionaries andPhotoIds:(NSArray *)photoIds inManagedObjectContext:(NSManagedObjectContext *)context
{
    
    NSMutableArray *photos =nil;
    NSMutableArray *photoNonInDBDictionaries =[photoDictionaries mutableCopy];
   
    NSFetchRequest *request =[NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.predicate = [NSPredicate predicateWithFormat: @"(unique IN %@)", photoIds] ;
    
    NSError *error;
    NSArray *matches =[context executeFetchRequest:request error:&error];
    if (!matches || error) {
        // handle error
   }else if ([matches count]){
        photos = [matches copy];
    }else {
        NSString *uniquePhoto;
        NSString *uniqueFlickr;
        for (Photo *photo in matches) {
            uniquePhoto =photo.unique;
            [photos addObject:photo];
            for (NSDictionary *photoFlickrInfo in photoDictionaries) {
                uniqueFlickr = photoFlickrInfo [FLICKR_PHOTO_ID];
                if ([uniqueFlickr isEqualToString:uniquePhoto]) {
                    [photoNonInDBDictionaries removeObject:photoFlickrInfo];
                }
            }
        }
        for (NSDictionary *photoDictionary in photoNonInDBDictionaries){
        Photo *photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:context];
        photo.unique =[photoDictionary valueForKeyPath:FLICKR_PHOTO_ID];
        photo.title = [photoDictionary valueForKeyPath:FLICKR_PHOTO_TITLE];
        if ([photo.title length]== 0) {
            photo.title = [[photoDictionary valueForKeyPath:FLICKR_PHOTO_DESCRIPTION] description];
            if ([photo.title length]== 0) {
                photo.title = FLICKR_UNKNOWN_PHOTO;
            }
        }
        photo.subtitle =[photoDictionary valueForKeyPath:FLICKR_PHOTO_DESCRIPTION];
        if ([photo.title isEqualToString:photo.subtitle] || [photo.title isEqualToString:FLICKR_UNKNOWN_PHOTO]) {
            photo.subtitle = @"";
        }
        photo.imageURL = [[FlickrFetcher URLforPhoto:photoDictionary format:FlickrPhotoFormatLarge] absoluteString];
        
        NSString *photographerName =[photoDictionary valueForKeyPath:FLICKR_PHOTO_OWNER];
        NSString *regionName = [photoDictionary valueForKey:@"region"];
        photo.whoTook = [Photographer photographerWithName:photographerName
                                             andRegionName:regionName
                                    inManagedObjectContext:context];
        //---
        photo.region = [Region regionForPhotosWithName:regionName inManagedObjectContext:context];
            [photos addObject:photo];
        }
    }
    return [photos copy];
}
+ (Photo *)exisitingPhotoWithID:(NSString *)photoID
         inManagedObjectContext:(NSManagedObjectContext *)context
{
    Photo *photo;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.predicate = [NSPredicate predicateWithFormat:@"unique = %@", photoID];
    request.sortDescriptors = [NSArray arrayWithObject:
                               [NSSortDescriptor sortDescriptorWithKey:@"title"
                                                             ascending:YES]];
    NSError *error;
    NSArray *matches = [context executeFetchRequest:request error:&error];
    if (!matches || ([matches count] > 1 || error)) {
        NSLog(@"Error in exisitingPhotoForID: %@ %@", matches, error);
    } else if ([matches count] == 0) {
        photo = nil;
    } else {
        photo = [matches lastObject];
    }
    return photo;
}


+ (void)putToResents:(Photo *)photo
{
    NSManagedObjectContext *context = photo.managedObjectContext;
    [Photo exisitingPhotoWithID:photo.unique inManagedObjectContext:context].dateStamp = [NSDate date];
    [context updatedObjects];
}


@end
