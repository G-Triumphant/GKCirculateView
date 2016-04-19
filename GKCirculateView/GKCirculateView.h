//
//  GKCirculateView.h
//  GKCirculateView
//
//  Created by apple on 16/4/12.
//  Copyright © 2016年 guoxc. All rights reserved.
//

#import <UIKit/UIKit.h>

//1.图片点击处理事件(block块)
typedef  void(^ClickBlock)(NSInteger index);

@class GKCirculateView;
@protocol GKCirculateViewDelegate <NSObject>
//2.点击图片处理事件(代理)
- (void)circulateView:(GKCirculateView *)circulateView didClickImage:(NSInteger)index;
@end


@interface GKCirculateView : UIView

//图片数组
@property(nonatomic, strong) NSArray *imageAry;
//时间间隔
@property(nonatomic) NSTimeInterval time;

//点击图片后执行的操作
@property(nonatomic, copy) ClickBlock imageClickBlock;
@property(nonatomic, weak) id<GKCirculateViewDelegate> delegate;

#pragma mark -- 构造方法
- (instancetype)initWithImageAry:(NSArray *)imageAry;
+ (instancetype)circulateViewWithImageAry:(NSArray *)imageAry;

- (instancetype)initWithImageAry:(NSArray *)imageAry imageClickBlock:(ClickBlock)imageClickBlock;
+ (instancetype)circulateViewWithImageAry:(NSArray *)imageAry imageClickBlock:(ClickBlock)imageClickBlock;

//清除缓存
- (void)clearDiskCache;
@end
