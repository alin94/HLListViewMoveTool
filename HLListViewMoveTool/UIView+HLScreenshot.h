//
//  UIView+HLScreenshot.h
//  ZTrello
//
//  Created by alin on 2019/7/2.
//  Copyright © 2019年 alin. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface UIView (HLScreenshot)
- (UIImageView *)hl_screenshotViewWithShadowOpacity:(CGFloat)shadowOpacity shadowColor:(UIColor *)shadowColor;

@end

