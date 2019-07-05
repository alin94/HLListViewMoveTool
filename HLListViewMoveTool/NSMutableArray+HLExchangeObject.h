//
//  NSMutableArray+hl_exchangeObject.h
//  ZTrello
//
//  Created by alin on 2019/7/2.
//  Copyright © 2019年 alin. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSMutableArray (HLExchangeObject)
/**
 检查数组中的元素是否为数组类型
 */
- (BOOL)hl_isArrayInChildElement;
/**
 *  将可变数组中的一个对象移动到该数组中的另外一个位置
 *  @param fromIndex 开始的index
 *  @param toIndex   目的index
 */
- (void)hl_exchangeObjectFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex;

@end

