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
#import "FlickrFetcher.h"
#import "Photo+Flickr.h"
#import "PhotosByRegionCDTVC.h"
#import "DBHelper.h"

@interface RegionsCDTVC ()
@end

@implementation RegionsCDTVC

- (void)awakeFromNib
{
    [[NSNotificationCenter defaultCenter] addObserverForName:PhotoDatabaseAvailabilityNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification *note) {
                                                      self.managedObjectContext = note.userInfo[PhotoDatabaseAvailabilityContext];
                                                  }];

}

-(void)setManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    _managedObjectContext =managedObjectContext;
    [self setupFetchedResultsControllerWithDocument: _managedObjectContext];
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[DBHelper sharedManagedDocument] performWithDocument:
     ^(UIManagedDocument *document) {
         self.managedObjectContext =document.managedObjectContext;

     }];
}
- (void)setupFetchedResultsControllerWithDocument:(NSManagedObjectContext *)managedObjectContext
{

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
#pragma mark - Navigation

- (void)prepareViewController:(id)vc forSegue:(NSString *)segueIdentifer fromIndexPath:(NSIndexPath *)indexPath
{
    Region *region = [self.fetchedResultsController objectAtIndexPath:indexPath];
    // note that we don't check the segue identifier here
    // probably fine ... hard to imagine any other way this class would segue to PhotosByRegionCDTVC

    if ([vc isKindOfClass:[PhotosByRegionCDTVC class]]) {
        PhotosByRegionCDTVC *pbrcdtvc = (PhotosByRegionCDTVC *)vc;
        pbrcdtvc.region = region;
        pbrcdtvc.title = region.name;
    }
}

// boilerplate
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = nil;
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        indexPath = [self.tableView indexPathForCell:sender];
    }
    [self prepareViewController:segue.destinationViewController
                       forSegue:segue.identifier
                  fromIndexPath:indexPath];
}

// boilerplate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id detailvc = [self.splitViewController.viewControllers lastObject];
    if ([detailvc isKindOfClass:[UINavigationController class]]) {
        detailvc = [((UINavigationController *)detailvc).viewControllers firstObject];
        [self prepareViewController:detailvc
                           forSegue:nil
                      fromIndexPath:indexPath];
    }
}

@end
