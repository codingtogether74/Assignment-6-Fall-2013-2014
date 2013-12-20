//
//  PhotoGraphersCDTVC.m
//  Photomania
//
//  Created by Tatiana Kornilova on 12/17/13.
//  Copyright (c) 2013 Tatiana Kornilova. All rights reserved.
//

#import "PhotoGraphersCDTVC.h"
#import "Photographer.h"
#import "PhotoDatabaseAvailability.h"

@interface PhotoGraphersCDTVC ()

@end

@implementation PhotoGraphersCDTVC

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
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Photographer"];
    request.predicate =nil;
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"name"
                                                              ascending:YES
                                                               selector:@selector(localizedStandardCompare:)]];
    request.fetchLimit =100;
    
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:request
                                                                        managedObjectContext:managedObjectContext sectionNameKeyPath:nil
                                                                                   cacheName:nil];
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell =[self.tableView dequeueReusableCellWithIdentifier:@"Photographer Cell"];
    Photographer *photographer =[self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = photographer.name;
    cell.detailTextLabel.text =[NSString stringWithFormat:@"%d photos",[photographer.photosByPhotographer count]];
    return cell;
}
@end
