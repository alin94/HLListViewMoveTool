//
//  HLDragArea.h
//  ZTrello
//
//  Created by alin on 2019/7/2.
//  Copyright © 2019年 alin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface HLDragArea : NSObject
@property (nonatomic, strong, readonly) UIView *superview;
@property (nonatomic, strong) NSMutableOrderedSet *collections;

- (id)initWithSuperview:(UIView *)superview containingCollections:(NSArray *)collections;

@end

