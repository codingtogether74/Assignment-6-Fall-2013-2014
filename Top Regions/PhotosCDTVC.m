//
//  PhotosCDTVC.m
//  Photomania
//
//  Created by CS193p Instructor.
//  Copyright (c) 2013 Stanford University. All rights reserved.
//

#import "PhotosCDTVC.h"
#import "Photo+Flickr.h"
#import "ImageViewController.h"

@implementation PhotosCDTVC

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Photo Cell"];
    
    Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = photo.title;
    cell.detailTextLabel.text = photo.subtitle;
    //----Thumnail------------------
    NSURL *thumbnailURL =  [NSURL URLWithString:photo.thumbnailURL];
    NSData *imageData = photo.thumbnail;
    if (!imageData){
        dispatch_queue_t q = dispatch_queue_create("thumbnail download queue", 0);
        dispatch_async(q, ^{
            NSData *imageData = [[NSData alloc] initWithContentsOfURL:thumbnailURL];
            UIImage *thumbnail =[[UIImage alloc] initWithData:imageData];
            dispatch_async(dispatch_get_main_queue(), ^{
                [photo.managedObjectContext performBlock:^{
                    photo.thumbnail = imageData;
                }];
                cell.imageView.image = thumbnail;
                [cell setNeedsLayout];
            });
        });
    } else {
        UIImage *thumbnail =[[UIImage alloc] initWithData:imageData];
        cell.imageView.image = thumbnail;
        [cell setNeedsLayout];
    }
    //------------------------------
    
    return cell;
}

#pragma mark - Navigation

- (void)prepareViewController:(id)vc
                     forSegue:(NSString *)segueIdentifer
                fromIndexPath:(NSIndexPath *)indexPath
{
    Photo *photo = [self.fetchedResultsController objectAtIndexPath:indexPath];

    // note that we don't check the segue identifier here
    // could easily imagine two different segues to ImageViewController from this class
    // for example, one might apply some sort of sepia tone or something
    // but for now, we only have this one segue, so we'll not check the segue identifier

    if ([vc isKindOfClass:[ImageViewController class]]) {
        ImageViewController *ivc = (ImageViewController *)vc;
        ivc.imageURL = [NSURL URLWithString:photo.imageURL];
        ivc.title = photo.title;
        [photo.managedObjectContext performBlock:^{
            [Photo putToResents:photo];
        }];
    }
}

// boilerplate
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    NSIndexPath *indexPath = nil;
    if ([sender isKindOfClass:[UITableViewCell class]]) {
        indexPath = [self.tableView indexPathForCell:sender];
        NSIndexPath *indexPath =[self.tableView indexPathForCell:sender];
        if (indexPath) {
            if ([segue.identifier isEqualToString:@"Display Photo"]) {
                if ([segue.destinationViewController isKindOfClass:[ImageViewController class]]) {
                    [self prepareViewController:segue.destinationViewController
                                       forSegue:segue.identifier
                                  fromIndexPath:indexPath];

                }
            }
        }
    }
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
