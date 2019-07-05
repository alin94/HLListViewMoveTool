//
//  NSMutableArray+hl_exchangeObject.m
//  ZTrello
//
//  Created by alin on 2019/7/2.
//  Copyright © 2019年 alin. All rights reserved.
//

#import "NSMutableArray+HLExchangeObject.h"

@implementation NSMutableArray (HLExchangeObject)
- (void)hl_exchangeObjectFromIndex:(NSInteger)fromIndex toIndex:(NSInteger)toIndex {
    NSParameterAssert([self isKindOfClass:[NSMutableArray class]] || !self.count);
    if (fromIndex < toIndex) {
        for (NSInteger i = fromIndex; i < toIndex; i++) {
            [self exchangeObjectAtIndex:i withObjectAtIndex:i + 1];
        }
    }
    else {
        for (NSInteger i = fromIndex; i > toIndex; i--) {
            [self exchangeObjectAtIndex:i withObjectAtIndex:i - 1];
        }
    }
}


- (BOOL)hl_isArrayInChildElement {
    NSInteger founIdx = [self indexOfObjectPassingTest:^BOOL(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        BOOL res = [obj isKindOfClass:[NSArray class]];
        if (res) {
            *stop = YES;
        }
        return res;
    }];
    return founIdx != NSNotFound;
}


@end
