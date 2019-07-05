//
//  UICollectionView+HLListView.h
//  ZTrello
//
//  Created by alin on 2019/7/2.
//  Copyright © 2019年 alin. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UICollectionView (HLListView)
@property (nonatomic, strong) NSArray *indexPathsForNotAllowMove;
@property (nonatomic, strong) NSArray *dataSourceArray;
@property (nonatomic, copy) void (^dataSourceDeleteBlock)(id object,NSIndexPath *indexPath);
@property (nonatomic, copy) void (^dataSourceInsertBlock)(id object,NSIndexPath *indexPath);
@property (nonatomic, copy) void (^dataSourceExchangedBlock)(NSIndexPath * originalIndexPath, NSIndexPath * currentIndexPath);
@property (nonatomic, copy) void (^dataSourceChangedBlock)(NSArray * dataSourceArray);

@end

