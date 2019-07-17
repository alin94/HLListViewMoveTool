//
//  UITableView+HLListView.m
//  ZTrello
//
//  Created by alin on 2019/7/2.
//  Copyright © 2019年 alin. All rights reserved.
//

#import "UITableView+HLListView.h"
#import "UIView+HLListView.h"


@implementation UITableView (HLListView)

#pragma mark - HLListView implementation


-(NSIndexPath *)indexPathForItemAtPoint:(CGPoint) at{
    if (!self.dataSourceArray.count) {
        //空列表插入
        return [NSIndexPath indexPathForRow:0 inSection:0];
    }
    return [self indexPathForRowAtPoint:at];
}


-(UIView *)itemAtIndexPath:(NSIndexPath *)index{
    return [self cellForRowAtIndexPath:index];
}


-(void) deleteItemsAtIndexPaths:(NSArray *)indeces{
    [self deleteRowsAtIndexPaths:indeces withRowAnimation:UITableViewRowAnimationFade];
}


-(void) reloadItemsAtIndexPaths:(NSArray *)indeces{
    [self reloadRowsAtIndexPaths:indeces withRowAnimation:UITableViewRowAnimationFade];
}


-(void) insertItemsAtIndexPaths:(NSArray *)indeces{
    [self insertRowsAtIndexPaths:indeces withRowAnimation:UITableViewRowAnimationFade];
}
- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath
{
    [self moveRowAtIndexPath:indexPath toIndexPath:newIndexPath];
}

@end
