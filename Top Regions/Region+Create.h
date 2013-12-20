//
//  Region+Create.h
//  Photomania
//
//  Created by Tatiana Kornilova on 12/18/13.
//  Copyright (c) 2013 Tatiana Kornilova. All rights reserved.
//

#import "Region.h"

@interface Region (Create)
+ (Region *)regionWithName:(NSString *)name
                inManagedObjectContext:(NSManagedObjectContext *)context;
+ (Region *)regionForPhotosWithName:(NSString *)name
    inManagedObjectContext:(NSManagedObjectContext *)context;

@end
