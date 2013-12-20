//
//  Photographer+Create.h
//  Photomania
//
//  Created by Tatiana Kornilova on 12/17/13.
//  Copyright (c) 2013 Tatiana Kornilova. All rights reserved.
//

#import "Photographer.h"

@interface Photographer (Create)

+ (Photographer *)photographerWithName:(NSString *)name andRegionName:(NSString *)regionName
        inManagedObjectContext:(NSManagedObjectContext *)context;

@end
