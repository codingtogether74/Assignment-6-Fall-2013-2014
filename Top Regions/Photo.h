//
//  Photo.h
//  Top Regions
//
//  Created by Tatiana Kornilova on 12/21/13.
//  Copyright (c) 2013 Tatiana Kornilova. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Photographer, Region;

@interface Photo : NSManagedObject

@property (nonatomic, retain) NSString * unique;
@property (nonatomic, retain) NSString * title;
@property (nonatomic, retain) NSString * subtitle;
@property (nonatomic, retain) NSString * imageURL;
@property (nonatomic, retain) NSString * thumbnailURL;
@property (nonatomic, retain) NSData * thumbnail;
@property (nonatomic, retain) NSDate * dateStamp;
@property (nonatomic, retain) Photographer *whoTook;
@property (nonatomic, retain) Region *region;

@end
