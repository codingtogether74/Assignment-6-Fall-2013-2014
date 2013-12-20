//
//  Photographer+Create.m
//  Photomania
//
//  Created by Tatiana Kornilova on 12/17/13.
//  Copyright (c) 2013 Tatiana Kornilova. All rights reserved.
//

#import "Photographer+Create.h"
#import "Region+Create.h"

@implementation Photographer (Create)
+ (Photographer *)photographerWithName:(NSString *)name andRegionName:(NSString *)regionName
                inManagedObjectContext:(NSManagedObjectContext *)context
{
    Photographer *photographer =nil;
    if ([name length]) {
        NSFetchRequest *request =[NSFetchRequest fetchRequestWithEntityName:@"Photographer"];
        request.predicate = [NSPredicate predicateWithFormat:@"name = %@",name];
        
        NSError *error;
        NSArray *matches =[context executeFetchRequest:request error:&error];
        if (!matches || ([matches count] > 1)) {
            // handle error
        } else if (![matches count]) {
            photographer = [NSEntityDescription insertNewObjectForEntityForName:@"Photographer"
                                                         inManagedObjectContext:context];
            photographer.name = name;
            photographer.region = [Region regionWithName:regionName inManagedObjectContext:context];
        } else {
            photographer = [matches lastObject];
        }
    }    
    return photographer;
}
@end
