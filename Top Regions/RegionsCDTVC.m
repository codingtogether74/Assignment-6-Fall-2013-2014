//
//  RegionsCDTVC.m
//  Photomania
//
//  Created by Tatiana Kornilova on 12/18/13.
//  Copyright (c) 2013 Tatiana Kornilova. All rights reserved.
//

#import "RegionsCDTVC.h"
#import "Region.h"
#import "PhotoDatabaseAvailability.h"

@interface RegionsCDTVC ()

@end

@implementation RegionsCDTVC

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserverForName:PhotoDatabaseAvailabilityNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      self.managedObjectContext =note.userInfo[PhotoDatabaseAvailabilityContext];
                                                  }];
}

-(void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext =managedObjectContext;
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Region"];
    request.predicate =nil;
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"countPhotographers"
                                                              ascending:NO
                                 ],[NSSortDescriptor
                                    sortDescriptorWithKey:@"name"
                                    ascending:YES
                                    selector:@selector(localizedCaseInsensitiveCompare:)]];
    request.fetchLimit =50;
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:managedObjectContext sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell =[self.tableView dequeueReusableCellWithIdentifier:@"Photographer Cell"];
    Region *region =[self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = region.name;
    cell.detailTextLabel.text =[NSString stringWithFormat:@"%@ photographers %@ photos",region.countPhotographers,region.countPhotos];
    return cell;
}

@end
