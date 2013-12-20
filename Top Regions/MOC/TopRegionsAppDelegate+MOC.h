//
//  TopRegionsAppDelegate+MOC.h
//  Top Regions
//
//  Created by Tatiana Kornilova on 12/20/13.
//  Copyright (c) 2013 Tatiana Kornilova. All rights reserved.
//

#import "TopRegionsAppDelegate.h"

@interface TopRegionsAppDelegate (MOC)

- (NSManagedObjectContext *)createMainQueueManagedObjectContext;

@end
