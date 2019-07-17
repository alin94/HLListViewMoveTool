//
//  HLListView.h
//  ZTrello
//
//  Created by alin on 2019/7/2.
//  Copyright © 2019年 alin. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HLListView <NSObject>

@required
- (NSIndexPath *)indexPathForItemAtPoint:(CGPoint)at;
- (UIView *)itemAtIndexPath:(NSIndexPath *)index;
- (void)deleteItemsAtIndexPaths:(NSArray *)indeces;
- (void)reloadItemsAtIndexPaths:(NSArray *)indeces;
- (void)insertItemsAtIndexPaths:(NSArray *)indeces;
- (void)moveItemAtIndexPath:(NSIndexPath *)indexPath toIndexPath:(NSIndexPath *)newIndexPath;
- (NSArray *)indexPathsForNotAllowMove;
- (NSArray *)dataSourceArray;
- (void (^)(id, NSIndexPath *))dataSourceInsertBlock;
- (void (^)(id, NSIndexPath *))dataSourceDeleteBlock;
- (void (^)(NSIndexPath *, NSIndexPath *))dataSourceExchangedBlock;
- (void (^)(NSArray *))dataSourceChangedBlock;
- (NSString *)idString;

@end
