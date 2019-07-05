//
//  UITableView+HLListView.h
//  ZTrello
//
//  Created by alin on 2019/7/2.
//  Copyright © 2019年 alin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableView (HLListView)
/**不允许移动的indexPath*/
@property (nonatomic, strong) NSArray *indexPathsForNotAllowMove;
/**列表的数据源*/
@property (nonatomic, strong) NSArray *dataSourceArray;
/**数据源删除数据回调*/
@property (nonatomic, copy) void (^dataSourceDeleteBlock)(id object,NSIndexPath *indexPath);
/**数据源插入数据回调*/
@property (nonatomic, copy) void (^dataSourceInsertBlock)(id object,NSIndexPath *indexPath);
/**数据源位置交换回调*/
@property (nonatomic, copy) void (^dataSourceExchangedBlock)(NSIndexPath * originalIndexPath, NSIndexPath * currentIndexPath);
/**数据源改变回调*/
@property (nonatomic, copy) void (^dataSourceChangedBlock)(NSArray * dataSourceArray);
@end


