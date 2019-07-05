//
//  HLDragArea.m
//  ZTrello
//
//  Created by alin on 2019/7/2.
//  Copyright © 2019年 alin. All rights reserved.
//

#import "HLDragArea.h"

@implementation HLDragArea
- (id)initWithSuperview:(UIView *)superview containingCollections:(NSArray *)collections{
    self = [super init];
    if(self){
        _superview = superview;
        _collections = [[NSMutableOrderedSet alloc] initWithCapacity:collections.count];
        [self.collections addObjectsFromArray:collections];
    }
    return self;
}

@end
