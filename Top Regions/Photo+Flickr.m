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
#import "NetworkIndicatorHelper.h"
#import "DBHelper.h"

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
        NSString *dateUpload = [photoDictionary valueForKeyPath:FLICKR_PHOTO_UPLOAD_DATE];
        photo.dateUpload = [NSDate dateWithTimeIntervalSince1970:[dateUpload doubleValue]];
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
/* It's classic, not efficient variant - doesn't use here now , but put for example
 
+(void)loadPhotosFromFlickrArray:(NSArray *)photos // of Flickr NSDictionary
        intoManagedObjectContext:(NSManagedObjectContext *)context
{
    //----
    dispatch_queue_t placeQ =dispatch_queue_create("place fetcher", NULL);
    dispatch_async(placeQ, ^{
        NSMutableSet *photoIds =[[NSMutableSet alloc] init];
        NSMutableArray *photosWithRegion =[[NSMutableArray alloc] init];
        for (NSDictionary *photo in photos) {
            NSMutableDictionary *photoWithRegion =[photo mutableCopy];
            NSURL *urlPlace =[FlickrFetcher URLforInformationAboutPlace:[photo valueForKeyPath: FLICKR_PHOTO_PLACE_ID]];
            
            [NetworkIndicatorHelper setNetworkActivityIndicatorVisible:YES];
            NSData *jsonResults = [NSData dataWithContentsOfURL:urlPlace];
            [NetworkIndicatorHelper setNetworkActivityIndicatorVisible:NO];
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

    });
    
}
*/

+(void)load1PhotosFromFlickrArray:(NSArray *)photos // of Flickr NSDictionary
         intoManagedObjectContext:(NSManagedObjectContext *)context
{
    NSMutableSet *photoIds =[[NSMutableSet alloc] init];
    
    for (NSDictionary *photo in photos) {
        [photoIds addObject:photo[FLICKR_PHOTO_ID]];
    }
    [self photosWithFlickrInfo:photos andPhotoIds:[photoIds copy] inManagedObjectContext:context];
//    [self deleteOldPhotosInManagedObjectContext:context];
}

+ (void)photosWithFlickrInfo:(NSArray *)photoDictionaries andPhotoIds:(NSSet *)photoIds inManagedObjectContext:(NSManagedObjectContext *)context
{
    NSMutableArray *photoNonInDBDictionaries =[photoDictionaries mutableCopy];
    
    NSFetchRequest *request =[NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.predicate = [NSPredicate predicateWithFormat: @"(unique IN %@)", photoIds] ;
    // narrow the fetch to these one properties
    request.propertiesToFetch = [NSArray arrayWithObjects:@"unique",nil];
    [request setResultType:NSDictionaryResultType];
    
    request.fetchBatchSize =20;
   
    NSError *error;
    NSArray *matches =[context executeFetchRequest:request error:&error];
    if (!matches || error) {
        // handle error
    }else {
        NSString *uniquePhoto;
        NSString *uniqueFlickr;
        for (NSDictionary *photo in matches) {
            uniquePhoto =photo[@"unique"];
            for (NSDictionary *photoDictionary in photoDictionaries) {
                uniqueFlickr=[photoDictionary valueForKeyPath:FLICKR_PHOTO_ID];
                if ([uniqueFlickr isEqualToString:uniquePhoto]) {
                    [photoNonInDBDictionaries removeObject:photoDictionary];
                }
            }
        }
        dispatch_queue_t placeQ =dispatch_queue_create("place fetcher", NULL);
        dispatch_async(placeQ, ^{
            
            for (NSDictionary *photoDictionary in photoNonInDBDictionaries){
                NSURL *urlPlace =[FlickrFetcher URLforInformationAboutPlace:[photoDictionary valueForKeyPath: FLICKR_PHOTO_PLACE_ID]];
                [NetworkIndicatorHelper setNetworkActivityIndicatorVisible:YES];
                NSData *jsonResults = [NSData dataWithContentsOfURL:urlPlace];
                [NetworkIndicatorHelper setNetworkActivityIndicatorVisible:NO];
                NSDictionary *placeInformation =[NSJSONSerialization JSONObjectWithData:jsonResults
                                                                                options:0
                                                                                  error:NULL];
                NSString *region = [FlickrFetcher extractRegionNameFromPlaceInformation:placeInformation];
                if (!region) {
                    region =@"Unknown";
                }
                NSLog(@"region = %@",region);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[DBHelper sharedManagedDocument] performWithDocument:^(UIManagedDocument *document) {
                        Photo *photo = [NSEntityDescription insertNewObjectForEntityForName:@"Photo" inManagedObjectContext:document.managedObjectContext];
                        photo.unique =[photoDictionary valueForKeyPath:FLICKR_PHOTO_ID];
                        photo.title = [photoDictionary valueForKeyPath:FLICKR_PHOTO_TITLE];
                        NSString *dateUpload = [photoDictionary valueForKeyPath:FLICKR_PHOTO_UPLOAD_DATE];
                        photo.dateUpload = [NSDate dateWithTimeIntervalSince1970:[dateUpload doubleValue]];
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
                                                             andRegionName:region
                                                    inManagedObjectContext:context];
                        photo.region = [Region regionForPhotosWithName:region inManagedObjectContext:context];
                        //                        [document saveToURL:document.fileURL forSaveOperation:UIDocumentSaveForOverwriting completionHandler:NULL];
                    }];
                    
                });
            }
               [[NSNotificationCenter defaultCenter] postNotificationName:@"DataUpdated" object:self];
            //--
            dispatch_async(dispatch_get_main_queue(), ^{
                [[DBHelper sharedManagedDocument] performWithDocument:^(UIManagedDocument *document) {
                    [self deleteOldPhotosInManagedObjectContext:document.managedObjectContext];
 
                      }];
                });
            [[NSNotificationCenter defaultCenter] postNotificationName:@"DataUpdated" object:self];

            //--
        });
        
    }
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
//        NSLog(@"Error in exisitingPhotoForID: %@ %@", matches, error);
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

+ (void)deleteOldPhotosInManagedObjectContext:(NSManagedObjectContext *)context
{
    // keep our number of photos to a manageable level, remove photos older than 2 weeks
    // compute the date two weeks ago from today, used later when dumping older photos
    //
    NSCalendar *gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    NSDateComponents *offsetComponents = [[NSDateComponents alloc] init];
    [offsetComponents setDay:-7];  // 7 days back from today
    NSDate *twoWeeksAgo = [gregorian dateByAddingComponents:offsetComponents toDate:[NSDate date] options:0];
    
    // use the same request instance but switch back to NSManagedObjectResultType
    NSFetchRequest *request =[NSFetchRequest fetchRequestWithEntityName:@"Photo"];
    request.resultType = NSManagedObjectResultType;
    request.predicate = [NSPredicate predicateWithFormat:@"dateUpload < %@", twoWeeksAgo];
    NSError *error = nil;
    NSArray *oldPhotos = [context executeFetchRequest:request error:&error];
    NSInteger i=0;
    NSInteger numberOfOldPhotos =[oldPhotos count];
    NSLog(@"Number of old photos = %ld",(long)numberOfOldPhotos);
    for (Photo *photo in oldPhotos) {
        [Photo removePhotoWithID:photo.unique inManagedObjectContext:photo.managedObjectContext];
        NSLog(@"Delete %ld/%ld old photo",(long)i,(long)numberOfOldPhotos);
        i++;
    }
    
    if ([context hasChanges]) {
        
        if (![context save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate.
            // You should not use this function in a shipping application, although it may be useful
            // during development. If it is not possible to recover from the error, display an alert
            // panel that instructs the user to quit the application by pressing the Home button.
            //
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}
+ (void)removePhoto:(Photo *)photo
{
    NSManagedObjectContext *context = photo.managedObjectContext;
    // tags and place could be put in prepareForDeletion
{
    Region *regionPhoto = photo.region;
    if ([photo.whoTook.photosByPhotographer count] == 1){
        
        if ([regionPhoto.countPhotographers intValue]== 1) [context deleteObject:regionPhoto];
        else regionPhoto.countPhotographers =[NSNumber numberWithInt:[regionPhoto.countPhotographers intValue] - 1];                 [context deleteObject:photo.whoTook];
    }
    
    if ([regionPhoto.countPhotos intValue]== 1){
            [context deleteObject:regionPhoto];
    } else {
        
    regionPhoto.countPhotos =[NSNumber numberWithInt:[regionPhoto.countPhotos intValue] - 1];
}
    [context updatedObjects];
    [context deleteObject:photo];
}
}

+ (void)removePhotoWithID:(NSString *)photoID
   inManagedObjectContext:(NSManagedObjectContext *)context
{
    Photo *photo = [Photo exisitingPhotoWithID:photoID inManagedObjectContext:context];
    [Photo removePhoto:photo];
}


@end
