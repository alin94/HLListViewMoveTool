//
//  UICollectionView+HLListView.m
//  ZTrello
//
//  Created by alin on 2019/7/2.
//  Copyright © 2019年 alin. All rights reserved.
//

#import "UICollectionView+HLListView.h"
#import <objc/runtime.h>

static char *notAllowMoveIndexPathsKey = "notAllowMoveIndexPathsKey";
static char *dataSourceArrayKey = "dataSourceArrayKey";
static char *dataSourceDeleteBlockKey = "dataSourceDeleteBlockKey";
static char *dataSourceInsertBlockKey = "dataSourceInsertBlockKey";
static char *dataSourceExchangedBlockKey = "dataSourceExchangedBlockKey";
static char *dataSourceChangedBlockKey = "dataSourceChangedBlockKey";

@implementation UICollectionView (HLListView)
- (NSArray *)indexPathsForNotAllowMove
{
    return objc_getAssociatedObject(self, notAllowMoveIndexPathsKey);
}
- (void)setIndexPathsForNotAllowMove:(NSArray *)indexPathsForNotAllowMove
{
    objc_setAssociatedObject(self, notAllowMoveIndexPathsKey, indexPathsForNotAllowMove, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (NSArray *)dataSourceArray
{
    return objc_getAssociatedObject(self, dataSourceArrayKey);
}
- (void)setDataSourceArray:(NSArray *)dataSourceArray
{
    objc_setAssociatedObject(self, dataSourceArrayKey, dataSourceArray, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void (^)(id, NSIndexPath *))dataSourceDeleteBlock
{
    return objc_getAssociatedObject(self, dataSourceDeleteBlockKey);
    
}
- (void)setDataSourceDeleteBlock:(void (^)(id, NSIndexPath *))dataSourceDeleteBlock
{
    objc_setAssociatedObject(self, dataSourceDeleteBlockKey, dataSourceDeleteBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (void (^)(id, NSIndexPath *))dataSourceInsertBlock
{
    return objc_getAssociatedObject(self, dataSourceInsertBlockKey);
}
- (void)setDataSourceInsertBlock:(void (^)(id, NSIndexPath *))dataSourceInsertBlock
{
    objc_setAssociatedObject(self, dataSourceInsertBlockKey, dataSourceInsertBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (void (^)(NSIndexPath *, NSIndexPath *))dataSourceExchangedBlock;
{
    return objc_getAssociatedObject(self, dataSourceExchangedBlockKey);
}
- (void)setDataSourceExchangedBlock:(void (^)(NSIndexPath *, NSIndexPath *))dataSourceExchangedBlock
{
    objc_setAssociatedObject(self, dataSourceExchangedBlockKey, dataSourceExchangedBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (void (^)(NSArray *))dataSourceChangedBlock
{
    return objc_getAssociatedObject(self, dataSourceChangedBlockKey);
    
}
- (void)setDataSourceChangedBlock:(void (^)(NSArray *))dataSourceChangedBlock
{
    objc_setAssociatedObject(self, dataSourceChangedBlockKey, dataSourceChangedBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

#pragma mark - HLListView implementation

-(UIView *)itemAtIndexPath:(NSIndexPath *)index{
    return [self cellForItemAtIndexPath:index];
}
@end
