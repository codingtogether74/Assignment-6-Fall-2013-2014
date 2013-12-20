//
//  Region+Create.m
//  Photomania
//
//  Created by Tatiana Kornilova on 12/18/13.
//  Copyright (c) 2013 Tatiana Kornilova. All rights reserved.
//

#import "Region+Create.h"

@implementation Region (Create)

+ (Region *)regionWithName:(NSString *)name
    inManagedObjectContext:(NSManagedObjectContext *)context
{
    Region *region =nil;
    
    if ([name length]) {
        NSFetchRequest *request =[NSFetchRequest fetchRequestWithEntityName:@"Region"];
        request.predicate = [NSPredicate predicateWithFormat:@"name = %@",name];
        
        NSError *error;
        NSArray *matches =[context executeFetchRequest:request error:&error];
        if (!matches || ([matches count] > 1)) {
            // handle error
        } else if (![matches count]) {
            region = [NSEntityDescription insertNewObjectForEntityForName:@"Region"
                                                   inManagedObjectContext:context];
            region.name = name;
            region.countPhotographers = [NSNumber numberWithInt:1];
            
        } else {
            region = [matches lastObject];
            region.countPhotographers = [NSNumber numberWithInt:[region.countPhotographers intValue] + 1];
        }
    }
    return region;
}

+ (Region *)regionForPhotosWithName:(NSString *)name
    inManagedObjectContext:(NSManagedObjectContext *)context
{
    Region *region =nil;
    
    if ([name length]) {
        NSFetchRequest *request =[NSFetchRequest fetchRequestWithEntityName:@"Region"];
        request.predicate = [NSPredicate predicateWithFormat:@"name = %@",name];
        
        NSError *error;
        NSArray *matches =[context executeFetchRequest:request error:&error];
        if (!matches || ([matches count] > 1)) {
            // handle error
        } else if (![matches count]) {
            region = [NSEntityDescription insertNewObjectForEntityForName:@"Region"
                                                   inManagedObjectContext:context];
            region.name = name;
            region.countPhotos = [NSNumber numberWithInt:1];
            
        } else {
            region = [matches lastObject];
            region.countPhotos = [NSNumber numberWithInt:[region.countPhotos intValue] + 1];
        }
    }
    return region;
}

@end
