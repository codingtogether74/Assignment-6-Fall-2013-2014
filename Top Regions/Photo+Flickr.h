//
//  Photo+Flickr.h
//  Photomania
//
//  Created by Tatiana Kornilova on 12/17/13.
//  Copyright (c) 2013 Tatiana Kornilova. All rights reserved.
//

#import "Photo.h"

@interface Photo (Flickr)
+ (Photo *)photoWithFlickrInfo:(NSDictionary *)photoDictionary
        inManagedObjectContext:(NSManagedObjectContext *)context;

//+(void)loadPhotosFromFlickrArray:(NSArray *)photos // of Flickr NSDictionary
//        intoManagedObjectContext:(NSManagedObjectContext *)context;

+(void)load1PhotosFromFlickrArray:(NSArray *)photos // of Flickr NSDictionary
        intoManagedObjectContext:(NSManagedObjectContext *)context;


+ (void)putToResents:(Photo *)photo;
+ (Photo *)exisitingPhotoWithID:(NSString *)photoID
         inManagedObjectContext:(NSManagedObjectContext *)context;
+ (void)removePhotoWithID:(NSString *)photoID inManagedObjectContext:(NSManagedObjectContext *)context
;

@end
