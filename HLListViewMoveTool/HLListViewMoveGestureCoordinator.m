//
//  HLListViewMoveGestureCoordinator.m
//  ZTrello
//
//  Created by alin on 2019/7/2.
//  Copyright © 2019年 alin. All rights reserved.
//



#import "HLListViewMoveGestureCoordinator.h"
#import "HLListView.h"
#import "UIView+HLScreenshot.h"
#import "NSMutableArray+HLExchangeObject.h"

typedef NS_ENUM(NSUInteger, HLListViewScrollDirection) {
    HLListViewScrollDirectionNotKnow,
    HLListViewScrollDirectionVertical,
    HLListViewScrollDirectionHorizontal
};
typedef NS_ENUM(NSUInteger, HLListViewAutoScrollDirection) {
    HLListViewAutoScrollDirectionNone = 0,     // 选中cell的截图没有到达父控件边缘
    HLListViewAutoScrollDirectionTop = 1,          // 选中cell的截图到达父控件顶部边缘
    HLListViewAutoScrollDirectionBottom = 2,       // 选中cell的截图到达父控件底部边缘
    HLListViewAutoScrollDirectionLeft = 3,         // 选中cell的截图到达父控件左侧边缘
    HLListViewAutoScrollDirectionRight = 4,        // 选中cell的截图到达父控件右侧边缘
};
@interface HLListViewMoveGestureCoordinator ()<UIGestureRecognizerDelegate>
{
    UILongPressGestureRecognizer *_longPress;
}
/** 自动滚动的方向 */
@property (nonatomic, assign) HLListViewAutoScrollDirection autoScrollDirection;
/** 对被选中的cell的截图 */
@property (nonatomic, strong) UIView *screenshotView;
/** 被选中的cell的原始位置，这个值是手机开始拖动cell时记录的原始值，只有下次开始拖动时才会被更改 */
@property (nonatomic, strong) NSIndexPath *beginRollIndexPath;
/** 开始移动的起始位置，这个值会随时改变 */
@property (nonatomic, strong) NSIndexPath *lastRollIndexPath;
/** 记录被选中的cell的新位置，手指移动时会从lastRollIndexPath移动到currentRollIndexPath */
@property (nonatomic, strong) NSIndexPath *currentRollIndexPath;
/**当前拖动cell所在的list*/
@property (nonatomic, strong) UIView<HLListView> *currentDraggingCollection;
/**上次拖动cell所在的list*/
@property (nonatomic, strong) UIView<HLListView> *lastDraggingCollection;

/** cell被拖动到边缘后开启，自动向上或向下滚动 */
@property (nonatomic, strong) CADisplayLink *displayLink;
/**控制cell的位置交换*/
@property (nonatomic, strong) NSTimer *moveTimer;
/** 记录手指所在的位置 */
@property (nonatomic, assign) CGPoint fingerPosition;
/**记录h是否跨了列表*/
@property (nonatomic, assign) BOOL hasChangedDraggingView;

@property (nonatomic, strong) HLDragArea *arena;
/**当前应该自动滚动的滚动视图*/
@property (nonatomic, strong) UIScrollView *currentRollView;


@end

@implementation HLListViewMoveGestureCoordinator
#pragma mark - getter | setter
- (UILongPressGestureRecognizer *)longPress
{
    if (!_longPress) {
        _longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognized:)];
    }
    return _longPress;
}
- (HLListViewScrollDirection )getRollRirectionWithScrollView:(UIScrollView *)scrollView
{
    HLListViewScrollDirection rollDirection = 0;
    CGSize contentSize = scrollView.contentSize;
    CGSize scrollViewSize = scrollView.frame.size;
    if (scrollViewSize.width < contentSize.width) {
        //横向滚动
        rollDirection = HLListViewScrollDirectionHorizontal;
    }else if (scrollViewSize.height < contentSize.height){
        rollDirection = HLListViewScrollDirectionVertical;
    }else{
        if ([self.currentDraggingCollection isKindOfClass:[UICollectionView class]]) {
            UICollectionView *collectionView = (UICollectionView *)self.currentDraggingCollection;
            UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout *)collectionView.collectionViewLayout;
            rollDirection = HLListViewScrollDirectionNotKnow;
            if (flowLayout.scrollDirection == UICollectionViewScrollDirectionHorizontal) {
                rollDirection = HLListViewScrollDirectionHorizontal;
            }else {
                rollDirection = HLListViewScrollDirectionVertical;
            }
        }
    }
    
    return rollDirection;
}
- (void)setCurrentDraggingCollection:(UIView<HLListView> *)currentDraggingCollection
{
    _currentDraggingCollection = currentDraggingCollection;
    if (_currentDraggingCollection != self.lastDraggingCollection && self.lastDraggingCollection && _currentDraggingCollection) {
        //跨列表了
        self.hasChangedDraggingView = YES;
    }
}
#pragma mark- init
- (instancetype)initWithDragArea:(HLDragArea *)dragArea;
{
    self  = [super init];
    if (self) {
        self.arena = dragArea;
        [self initSet];
    }
    return self;
}
- (void)initSet
{
    self.moveEnabled = self.mixMoveEnabled = YES;
    self.longPressPositionMaxY = CGFLOAT_MAX;
    self.autoRollCellSpeed = 3;
    self.rollingColor = [UIColor blackColor];
    self.rollIngShadowOpacity = 0.3;
    self.arena.superview.userInteractionEnabled = YES;
    [self.arena.superview addGestureRecognizer:self.longPress];
    self.longPress.delegate = self;
}
#pragma mark- cell's  move | delete | insert
/**
 *  截图被移动到新的indexPath范围，这时先更新数据源，重排数组，再将cell移至新位置
 *  @param newIndexPath 新的indexPath
 */
- (void)moveCellToNewIndexPath:(NSIndexPath *)newIndexPath{
    if (!self.lastRollIndexPath) {
        return;
    }
    if (newIndexPath == self.lastRollIndexPath) {
        return;
    }
    //检查是否禁止move
    NSArray *notAllowMovedIndexPaths = [self.currentDraggingCollection indexPathsForNotAllowMove];
    if (newIndexPath) {
        if ([notAllowMovedIndexPaths containsObject:newIndexPath]) {
            return;
        }
    }
    // 更新数据源
    [self moveCellUpdateDataSource];
    //交换移动cell位置
    [self.currentDraggingCollection moveItemAtIndexPath:self.lastRollIndexPath toIndexPath:newIndexPath];
    // 更新lastRollIndexPath当前indexPath
    self.lastRollIndexPath = newIndexPath;
}
- (void)moveCellUpdateDataSource {
    //通过originalDataBlock获得原始的数据
    NSMutableArray *rollingTempArray = [NSMutableArray array];
    NSArray *orginalArray = self.currentDraggingCollection.dataSourceArray;
    [rollingTempArray addObjectsFromArray:orginalArray];
    //判断原始数据是否为嵌套数组
    if ([rollingTempArray hl_isArrayInChildElement]) {
        //是嵌套数组
        if (self.lastRollIndexPath.section == self.currentRollIndexPath.section) {
            //在同一个section内
            // 容错处理：当外界的数组实际类型不是NSMutableArray时，将其转换为NSMutableArray
            if ([rollingTempArray[self.lastRollIndexPath.section] isKindOfClass:[NSMutableArray class]]) {
                [rollingTempArray[self.lastRollIndexPath.section] hl_exchangeObjectFromIndex:self.lastRollIndexPath.row toIndex:self.currentRollIndexPath.row];
            }else{
                NSMutableArray * tempArr = [NSMutableArray arrayWithArray:rollingTempArray[self.lastRollIndexPath.section]];
                [tempArr hl_exchangeObjectFromIndex:self.lastRollIndexPath.row toIndex:self.currentRollIndexPath.row];
                [rollingTempArray replaceObjectAtIndex:self.lastRollIndexPath.section withObject:tempArr];
            }
        }
        else {
            //不在同一个section内
            id originalObj = rollingTempArray[self.lastRollIndexPath.section][self.lastRollIndexPath.item];
            // 容错处理：当外界的数组实际类型不是NSMutableArray时，将其转换为NSMutableArray
            if ([rollingTempArray[self.currentRollIndexPath.section] isKindOfClass:[NSMutableArray class]]) {
                [rollingTempArray[self.currentRollIndexPath.section] insertObject:originalObj atIndex:self.currentRollIndexPath.item];
            }else{
                NSMutableArray * tempArr = [NSMutableArray arrayWithArray:rollingTempArray[self.currentRollIndexPath.section]];
                [tempArr insertObject:originalObj atIndex:self.currentRollIndexPath.item];
                [rollingTempArray replaceObjectAtIndex:self.currentRollIndexPath.section withObject:tempArr];
            }
            
            if ([rollingTempArray[self.lastRollIndexPath.section] isKindOfClass:[NSMutableArray class]]) {
                [rollingTempArray[self.lastRollIndexPath.section] removeObjectAtIndex:self.lastRollIndexPath.item];
            }else{
                NSMutableArray * tempArr = [NSMutableArray arrayWithArray:rollingTempArray[self.lastRollIndexPath.section]];
                [tempArr removeObjectAtIndex:self.lastRollIndexPath.item];
                [rollingTempArray replaceObjectAtIndex:self.lastRollIndexPath.section withObject:tempArr];
            }
        }
    }
    else {
        //不是嵌套数组
        [rollingTempArray hl_exchangeObjectFromIndex:self.lastRollIndexPath.row toIndex:self.currentRollIndexPath.row];
    }
    if (self.currentDraggingCollection.dataSourceExchangedBlock) {
        self.currentDraggingCollection.dataSourceExchangedBlock(self.lastRollIndexPath, self.currentRollIndexPath);
    }
    if (self.currentDraggingCollection.dataSourceChangedBlock) {
        self.currentDraggingCollection.dataSourceChangedBlock(rollingTempArray);
    }
    
}
- (id)deleteCellForIndexPath:(NSIndexPath *)deleteIndexPath
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:deleteIndexPath.row inSection:deleteIndexPath.section];
    //检查是否禁止move
    NSArray *notAllowMovedIndexPaths = [self.lastDraggingCollection indexPathsForNotAllowMove];
    if (indexPath) {
        if ([notAllowMovedIndexPaths containsObject:indexPath]) {
            return nil;
        }
    }
    id obj;
    // 更新数据源并返回给外部
    NSMutableArray *rollingTempArray = [NSMutableArray array];
    NSArray *orginalArray = self.lastDraggingCollection.dataSourceArray;
    [rollingTempArray addObjectsFromArray:orginalArray];
    //判断原始数据是否为嵌套数组
    if ([rollingTempArray hl_isArrayInChildElement]) {
        //是嵌套数组
        obj = rollingTempArray[indexPath.section][indexPath.item];
        // 容错处理：当外界的数组实际类型不是NSMutableArray时，将其转换为NSMutableArray
        if ([rollingTempArray[indexPath.section] isKindOfClass:[NSMutableArray class]]) {
            [rollingTempArray[indexPath.section] removeObjectAtIndex:indexPath.item];
        }else{
            NSMutableArray * tempArr = [NSMutableArray arrayWithArray:rollingTempArray[indexPath.section]];
            [tempArr removeObjectAtIndex:indexPath.item];
            [rollingTempArray replaceObjectAtIndex:indexPath.section withObject:tempArr];
        }
    }
    else {
        //不是嵌套数组
        obj = rollingTempArray[indexPath.row];
        [rollingTempArray removeObjectAtIndex:indexPath.row];
    }
    if (self.lastDraggingCollection.dataSourceDeleteBlock) {
        self.lastDraggingCollection.dataSourceDeleteBlock(obj,indexPath);
    }
    if (self.lastDraggingCollection.dataSourceChangedBlock) {
        self.lastDraggingCollection.dataSourceChangedBlock(rollingTempArray);
    }
    //删除cell
    [self.lastDraggingCollection deleteItemsAtIndexPaths:@[indexPath]];
    return obj;
}
- (void)insertObj:(id)obj atIndexPath:(NSIndexPath *)indexPath
{
    // 更新数据源并返回给外部
    NSMutableArray *rollingTempArray = [NSMutableArray array];
    NSArray *orginalArray = self.currentDraggingCollection.dataSourceArray;
    [rollingTempArray addObjectsFromArray:orginalArray];
    //判断原始数据是否为嵌套数组
    if ([rollingTempArray hl_isArrayInChildElement]) {
        // 容错处理：当外界的数组实际类型不是NSMutableArray时，将其转换为NSMutableArray
        if ([rollingTempArray[indexPath.section] isKindOfClass:[NSMutableArray class]]) {
            [rollingTempArray[indexPath.section] insertObject:obj atIndex:indexPath.item];
        }else{
            NSMutableArray * tempArr = [NSMutableArray arrayWithArray:rollingTempArray[indexPath.section]];
            [tempArr insertObject:obj atIndex:indexPath.item];
            [rollingTempArray replaceObjectAtIndex:indexPath.section withObject:tempArr];
        }
    }
    else {
        //不是嵌套数组
        [rollingTempArray insertObject:obj atIndex:indexPath.row];
    }
    if (self.currentDraggingCollection.dataSourceInsertBlock) {
        self.currentDraggingCollection.dataSourceInsertBlock(obj,indexPath);
    }
    if (self.currentDraggingCollection.dataSourceChangedBlock) {
        self.currentDraggingCollection.dataSourceChangedBlock(rollingTempArray);
    }
    //插入cell
    [self.currentDraggingCollection insertItemsAtIndexPaths:@[indexPath]];
    //隐藏新插入的cell
    UIView *cell = [self.currentDraggingCollection itemAtIndexPath:indexPath];
    cell.hidden = YES;
}

#pragma mark- timer for cell's move and scrollView's auto move
- (void)startMoveTimer
{
    if (!self.moveTimer) {
        self.moveTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(moveCell) userInfo:nil repeats:YES];
        [self.moveTimer fire];
    }
}
- (void)moveCell
{
    if (self.currentRollIndexPath) {
        [self moveCellToNewIndexPath:self.currentRollIndexPath];
    }else{
        [self stopMoveTimer];
    }
}
- (void)stopMoveTimer
{
    [self.moveTimer invalidate];
    self.moveTimer = nil;
}

- (void)startAutoScroll {
    if (!self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(startAutoScrollCurrentRollView)];
        [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    }
}
// 开始自动滚动当前该滚动的list
- (void)startAutoScrollCurrentRollView {
    //    NSLog(@"自动滚动啦啦啦");
    UIScrollView *scrollView = self.currentRollView;
    // 设置自动滚动速度
    if (self.autoRollCellSpeed == 0.0) {
        self.autoRollCellSpeed = 3.0;
    } else if (self.autoRollCellSpeed > 15) {
        self.autoRollCellSpeed = 15;
    }
    CGFloat autoRollCellSpeed = self.autoRollCellSpeed; // 滚动速度，数值越大滚动越快
    HLListViewScrollDirection rollDirection = [self getRollRirectionWithScrollView:self.currentRollView];
    if ((rollDirection == HLListViewScrollDirectionVertical || rollDirection == HLListViewScrollDirectionNotKnow) &&
        self.autoScrollDirection == HLListViewAutoScrollDirectionTop) {//向上滚动
        //向上滚动最大范围限制
        if (scrollView.contentOffset.y > 0) {
            scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y - autoRollCellSpeed);
            self.screenshotView.center = CGPointMake(self.screenshotView.center.x, self.screenshotView.center.y - autoRollCellSpeed);
        }
    } else if ((rollDirection == HLListViewScrollDirectionVertical || rollDirection == HLListViewScrollDirectionNotKnow) &&
               self.autoScrollDirection == HLListViewAutoScrollDirectionBottom) { // 向下滚动
        //向下滚动最大范围限制
        if (scrollView.contentOffset.y + scrollView.bounds.size.height < scrollView.contentSize.height) {
            scrollView.contentOffset = CGPointMake(0, scrollView.contentOffset.y + autoRollCellSpeed);
            self.screenshotView.center = CGPointMake(self.screenshotView.center.x, self.screenshotView.center.y + autoRollCellSpeed);
        }
    } else if (self.autoScrollDirection == HLListViewAutoScrollDirectionLeft) {
        // 向左滚动滚动的最大范围限制
        if (scrollView.contentOffset.x > 0) {
            scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x - autoRollCellSpeed, 0);
            self.screenshotView.center = CGPointMake(self.screenshotView.center.x - autoRollCellSpeed, self.screenshotView.center.y);
        }
    } else if (self.autoScrollDirection == HLListViewAutoScrollDirectionRight) {
        // 向右滚动滚动的最大范围限制
        if (scrollView.contentOffset.x + scrollView.bounds.size.width < scrollView.contentSize.width) {
            scrollView.contentOffset = CGPointMake(scrollView.contentOffset.x + autoRollCellSpeed, scrollView.contentOffset.y);
            self.screenshotView.center = CGPointMake(self.screenshotView.center.x + autoRollCellSpeed, self.screenshotView.center.y);
        }
    }
    self.currentRollIndexPath = [self.currentDraggingCollection indexPathForItemAtPoint:[self convertPointToDraggingCollection:self.screenshotView.center]];
    
    if (self.currentRollIndexPath &&
        ![self.currentRollIndexPath isEqual:self.lastRollIndexPath]) {
        [self startMoveTimer];
    }
}
- (void)stopAutoScroll {
    if (self.displayLink) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}
#pragma mark - private Func
- (void)resetCurrentDraggingCollection
{
    for (UIView<HLListView> *collection in self.arena.collections){
        CGRect collectionRealFrame = [collection.superview convertRect:collection.frame toView:self.arena.superview];
        BOOL contains = CGRectContainsPoint(collectionRealFrame, self.fingerPosition);
        if(contains){
            CGPoint covertPoint = [self.arena.superview convertPoint:self.fingerPosition toView:collection];
            NSIndexPath *index = [collection indexPathForItemAtPoint:covertPoint];
            if([collection itemAtIndexPath:index]){
                if (!self.hasChangedDraggingView) {
                    self.lastDraggingCollection = self.currentDraggingCollection;
                }
                self.currentDraggingCollection = collection;
            }
            else{
                self.currentDraggingCollection = nil;
            }
            break;
        }
    }
}
- (CGPoint)convertPointToDraggingCollection:(CGPoint)point
{
    return [self.arena.superview convertPoint:point toView:self.currentDraggingCollection];
}
// cell被长按手指选中，对其进行截图，原cell隐藏
- (void)cellSelectedAtIndexPath:(NSIndexPath *)indexPath {
    if (self.screenshotView) {
        [self.screenshotView removeFromSuperview];
    }
    UIView *cell = [self.currentDraggingCollection itemAtIndexPath:indexPath];
    UIView *screenshotView = [cell hl_screenshotViewWithShadowOpacity:self.rollIngShadowOpacity shadowColor:self.rollingColor];
    CGPoint convertCenter = [cell.superview convertPoint:cell.center toView:self.arena.superview];
    screenshotView.center = convertCenter;
    [self.arena.superview addSubview:screenshotView];
    [self.arena.superview bringSubviewToFront:screenshotView];
    self.screenshotView = screenshotView;
    cell.hidden = YES;
    //旋转5度角
    [UIView animateWithDuration:0.2 animations:^{
        self.screenshotView.transform = CGAffineTransformMakeRotation( 5.0/180.0*M_PI);
        self.screenshotView.alpha = 0.98;
    }];
}

// 检查截图是否到达边缘，并作出响应
- (BOOL)checkIfScreenshotViewMeetsEdgeOnScrollView:(UIScrollView *)scrollView
{
    CGFloat scale = 0.2;
    CGFloat width = CGRectGetWidth(self.screenshotView.frame);
    HLListViewScrollDirection rollRirection = [self getRollRirectionWithScrollView:scrollView];
    if (rollRirection == HLListViewScrollDirectionHorizontal) {
        CGFloat MinX = CGRectGetMinX(self.screenshotView.frame) + width*scale;
        CGFloat maxX = CGRectGetMaxX(self.screenshotView.frame) - width*scale;
        if (MinX < scrollView.contentOffset.x/scrollView.zoomScale) {
            self.autoScrollDirection = HLListViewAutoScrollDirectionLeft;
            return YES;
        }
        if (maxX > scrollView.frame.size.width/scrollView.zoomScale + scrollView.contentOffset.x/scrollView.zoomScale) {
            self.autoScrollDirection = HLListViewAutoScrollDirectionRight;
            return YES;
        }
    }else{
        CGRect convertFrame = [self.screenshotView.superview convertRect:self.screenshotView.frame toView:scrollView];
        CGFloat minY = CGRectGetMinY(convertFrame);
        CGFloat maxY = CGRectGetMaxY(convertFrame);
        if (minY < scrollView.contentOffset.y) {
            self.autoScrollDirection = HLListViewAutoScrollDirectionTop;
            return YES;
        }
        if (maxY > scrollView.bounds.size.height + scrollView.contentOffset.y) {
            self.autoScrollDirection = HLListViewAutoScrollDirectionBottom;
            return YES;
        }
    }
    return NO;

}

// 拖拽结束，显示cell，并移除截图
- (void)rollingCellDidEndScroll {
    UIView *cell = [self.currentDraggingCollection itemAtIndexPath:self.currentRollIndexPath];
    cell.hidden = NO;
    cell.alpha = 0;
    [UIView animateWithDuration:0.2 animations:^{
        CGPoint convertCenter = [cell.superview convertPoint:cell.center toView:self.arena.superview];
        self.screenshotView.center = convertCenter;
        self.screenshotView.alpha = 0;
        self.screenshotView.transform = CGAffineTransformIdentity;
        cell.alpha = 1;
        cell.hidden = NO;
        
    } completion:^(BOOL finished) {
        [self.screenshotView removeFromSuperview];
        if (self.delegate && [self.delegate respondsToSelector:@selector(hl_listViewRollingCellDidEndScrollAtIndexPath:gestureCoordinator:)]) {
            [self.delegate hl_listViewRollingCellDidEndScrollAtIndexPath:self.lastRollIndexPath gestureCoordinator:self];
        }
        self.screenshotView = nil;
        self.beginRollIndexPath = nil;
        self.currentRollIndexPath = nil;
        self.lastRollIndexPath = nil;
        self.currentDraggingCollection = nil;
        self.lastDraggingCollection = nil;
        self.hasChangedDraggingView = NO;
        self.fingerPosition = CGPointZero;
    }];
    
}

#pragma mark - UIGestureRecognizerDelegate | Events
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (!self.isMoveEnabled) {
        return NO;
    }
    if (gestureRecognizer == self.longPress) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(hl_listViewShouldBeginLongPress:)]) {
            BOOL allow = [self.delegate hl_listViewShouldBeginLongPress:gestureRecognizer];
            if (!allow) {
                return allow;
            }
        }
        CGPoint fingerPosition = [gestureRecognizer locationInView:gestureRecognizer.view];
        //检查可长按手势范围
        if (fingerPosition.y > self.longPressPositionMaxY) {
            return NO;
        }
        self.fingerPosition = fingerPosition;
        if (!self.currentDraggingCollection) {
            [self resetCurrentDraggingCollection];
        }
        if (!self.currentDraggingCollection) {
            //没有选中list
            return NO;
        }
        NSIndexPath * indexPath = [self.currentDraggingCollection indexPathForItemAtPoint:[self convertPointToDraggingCollection:fingerPosition]];
        if (!indexPath) {
            //没有选中cell
            return NO;
        }
        //检查是否是禁止move的indexPath
        NSArray *notAllowMovedIndexPaths = [self.currentDraggingCollection indexPathsForNotAllowMove];
        if ([notAllowMovedIndexPaths containsObject:indexPath]) {
            return NO;
        }
    }
    return YES;
}
- (void)longPressGestureRecognized:(UILongPressGestureRecognizer *)longPress
{
    // 获取手指在rollView上的坐标
    CGPoint fingerPosition = [longPress locationInView:longPress.view];
    self.fingerPosition = fingerPosition;
    [self resetCurrentDraggingCollection];
    // 手指按住位置对应的indexPath，可能为nil
    NSIndexPath * currentcurrentRollIndexPath = [self.currentDraggingCollection indexPathForItemAtPoint:[self convertPointToDraggingCollection:fingerPosition]];
    
    if (self.hasChangedDraggingView && currentcurrentRollIndexPath) {
        [self stopMoveTimer];
        //改变了拖拽列表
        id draggingItem = [self deleteCellForIndexPath:self.lastRollIndexPath];
        [self insertObj:draggingItem atIndexPath:currentcurrentRollIndexPath];
        self.currentRollIndexPath = nil;
        self.hasChangedDraggingView = NO;
        self.lastDraggingCollection = nil;
        self.currentDraggingCollection = nil;
        self.lastDraggingCollection = nil;
        self.lastRollIndexPath = nil;
        return;
    }
    self.currentRollIndexPath = currentcurrentRollIndexPath;
    if (!self.lastRollIndexPath) {
        self.lastRollIndexPath = self.currentRollIndexPath;
    }
    if (longPress.state == UIGestureRecognizerStateBegan) {
        // 获取beginRollIndexPath，注意容错处理，因为可能为nil
        self.beginRollIndexPath = currentcurrentRollIndexPath;
        self.lastRollIndexPath = self.beginRollIndexPath;
        if (self.lastRollIndexPath) {
            if (self.delegate && [self.delegate respondsToSelector:@selector(hl_listViewBeginLongPressAtIndexPath:gestureCoordinator:)]) {
                [self.delegate hl_listViewBeginLongPressAtIndexPath:self.beginRollIndexPath gestureCoordinator:self];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    //手势开始，对被选中cell截图，隐藏原cell
                    [self cellSelectedAtIndexPath:self.lastRollIndexPath];
                });
            }else{
                [self cellSelectedAtIndexPath:self.lastRollIndexPath];
            }
        }
        
    }
    else if (longPress.state == UIGestureRecognizerStateChanged) {
        if (!self.screenshotView) {
            NSLog(@"没有截图！！！！！");
            return;
        }
        // 长按手势开始移动，判断手指按住位置是否进入其它indexPath范围，若进入则更新数据源并移动cell
        // 截图跟随手指移动
        if (self.isMixMoveEnabled) {
            [UIView animateWithDuration:0.1 animations:^{
                self.screenshotView.center = self.fingerPosition;
            }];
        }else{
            CGPoint center = self.screenshotView.center;
            HLListViewScrollDirection direction = [self getRollRirectionWithScrollView:(UIScrollView *)self.currentDraggingCollection];
            if (direction == HLListViewScrollDirectionVertical) {
                center.y = self.fingerPosition.y;
            }else if (direction == HLListViewScrollDirectionHorizontal){
                center.x = self.fingerPosition.x;
            }else{
                center = self.fingerPosition;
            }
            [UIView animateWithDuration:0.1 animations:^{
                self.screenshotView.center = center;
            }];
            
        }
        if (self.lastRollIndexPath&&self.currentRollIndexPath && ![self.currentRollIndexPath isEqual:self.lastRollIndexPath]) {
            [self startMoveTimer];
        }
        BOOL autoScroll = NO;
        // 检测是否到达边缘，如果到达边缘就开始运行定时器,自动滚动
        if ([self checkIfScreenshotViewMeetsEdgeOnScrollView:(UIScrollView *)self.currentDraggingCollection]) {
            self.currentRollView = (UIScrollView *)self.currentDraggingCollection;
            autoScroll = YES;
            [self startAutoScroll];
        }
        if (!autoScroll && [self checkIfScreenshotViewMeetsEdgeOnScrollView:self.bottomScrollView] && self.bottomScrollView) {
            self.currentRollView = self.bottomScrollView;
            [self startAutoScroll];
            autoScroll = YES;
        }
        if (!autoScroll) {
            [self stopAutoScroll];
        }

    }
    else {
        NSLog(@"停止啦啦啦");
        [self stopMoveTimer];
        // 其他情况，比如长按手势结束或被取消，移除截图，显示cell
        if (self.currentRollIndexPath && ![self.currentRollIndexPath isEqual:self.lastRollIndexPath]) {
            [self moveCellToNewIndexPath:self.currentRollIndexPath];
        }else{
            self.currentRollIndexPath = self.lastRollIndexPath;
        }
        [self stopAutoScroll];
        [self rollingCellDidEndScroll];
        self.currentDraggingCollection = nil;
        self.lastDraggingCollection = nil;
        self.hasChangedDraggingView = NO;
    }
    
}

@end
