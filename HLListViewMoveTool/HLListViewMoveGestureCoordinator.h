//
//  HLListViewMoveGestureCoordinator.h
//  ZTrello
//
//  Created by alin on 2019/7/2.
//  Copyright © 2019年 alin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "HLDragArea.h"
#import "HLListView.h"

@class HLListViewMoveGestureCoordinator;

@protocol HLListViewMoveDelegate <NSObject>

- (BOOL)hl_listViewShouldBeginLongPress:(UIGestureRecognizer *)gestureRecognizer onListView:(UIView<HLListView> *)listView gestureCoordinator:(HLListViewMoveGestureCoordinator *)gestureCoordinator;
- (void)hl_listViewBeginLongPressAtIndexPath:(NSIndexPath *)indexPath onListView:(UIView<HLListView> *)listView gestureCoordinator:(HLListViewMoveGestureCoordinator *)gestureCoordinator;
- (void)hl_listViewRollingCellDidEndScrollAtIndexPath:(NSIndexPath *)indexPath onListView:(UIView<HLListView> *)listView gestureCoordinator:(HLListViewMoveGestureCoordinator *)gestureCoordinator;
@end



@interface HLListViewMoveGestureCoordinator : NSObject
/**底部负责滚动的视图。当多个list可以跨列表拖动的时候，传所有list的共同父视图的可滚动视图*/
@property (nonatomic, strong) UIScrollView *bottomScrollView;

@property (nonatomic, weak) id <HLListViewMoveDelegate> delegate;
/** 是否允许cell移动 默认 YES*/
@property (nonatomic, assign, getter=isMoveEnabled) BOOL moveEnabled;

/** 是否允许cell拖拽跨列表移动 默认 YES */
@property (nonatomic, assign, getter=isMixMoveEnabled) BOOL mixMoveEnabled;

/** cell在滚动时的阴影颜色,默认为黑色*/
@property (nonatomic, strong) UIColor * __nullable rollingColor;

/** cell在滚动时的阴影的不透明度,默认为0.3 */
@property (nonatomic, assign) CGFloat rollIngShadowOpacity;

/** cell拖拽到屏幕边缘时，其他cell的滚动速度，数值越大滚动越快，默认为5.0,最大为15 */
@property (nonatomic, assign) CGFloat autoRollCellSpeed;

/**手指允许长按最大Y值*/
@property (nonatomic, assign) CGFloat longPressPositionMaxY;
/**长按手势 只读*/
@property (nonatomic, strong, readonly) UILongPressGestureRecognizer *longPress;


- (instancetype)initWithDragArea:(HLDragArea *)dragArea;

@end
