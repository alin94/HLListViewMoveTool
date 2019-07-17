//
//  UICollectionView+HLListView.m
//  ZTrello
//
//  Created by alin on 2019/7/2.
//  Copyright © 2019年 alin. All rights reserved.
//

#import "UICollectionView+HLListView.h"
#import "UIView+HLListView.h"

@implementation UICollectionView (HLListView)

#pragma mark - HLListView implementation

-(UIView *)itemAtIndexPath:(NSIndexPath *)index{
    return [self cellForItemAtIndexPath:index];
}
@end
