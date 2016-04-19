//
//  GKCirculateView.m
//  GKCirculateView
//
//  Created by apple on 16/4/12.
//  Copyright © 2016年 guoxc. All rights reserved.
//

#import "GKCirculateView.h"

#define DEFAULTTIME 5
#define KSCREEN_WIDTH  [UIScreen mainScreen].bounds.size.width
#define KSCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
//方向枚举
typedef NS_ENUM(NSInteger, GKCirculateViewDirectType) {
    GKCirculateViewNoneDirectType = 0,
    GKCirculateViewLeftDirectType,
    GKCirculateViewRightDirectType
};

@interface GKCirculateView() <UIScrollViewDelegate>

//图片数组
@property(nonatomic, strong) NSMutableArray *images;
//当前显示的视图
@property(nonatomic, strong) UIImageView *currentImageView;
//将要显示的下一张视图
@property(nonatomic, strong) UIImageView *nextImageView;
//当前图片索引
@property(nonatomic) NSInteger currentIndex;
//即将出现图片的索引
@property(nonatomic) NSInteger nextIndex;
//滚动视图
@property(nonatomic, strong) UIScrollView *scrollView;
//分页控件
@property(nonatomic, strong) UIPageControl *pageControl;
//方向枚举
@property(nonatomic) GKCirculateViewDirectType circulateViewDirectType;
//定时器
@property(nonatomic, strong) NSTimer *timer;

//下载图片的字典
@property(nonatomic, strong) NSMutableDictionary *imageDic;
//下载图片的操作
@property(nonatomic, strong) NSMutableDictionary *operationDic;
//任务队列
@property(nonatomic, strong) NSOperationQueue *queue;
@end

@implementation GKCirculateView

//创建缓存图片的文件夹
+ (void)initialize {
    NSString *cache = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:@"GKCirculateView"];
    BOOL isDir = NO;
    BOOL isExists = [[NSFileManager defaultManager] fileExistsAtPath:cache isDirectory:&isDir];
    if (!isExists || !isDir) {
        [[NSFileManager defaultManager] createDirectoryAtPath:cache withIntermediateDirectories:YES attributes:nil error:nil];
    }
}

//获取宽高
- (CGFloat)width {
    return self.scrollView.frame.size.width;
}

- (CGFloat)height {
    return self.scrollView.frame.size.height;
}

//懒加载
- (NSMutableDictionary *)imageDic {
    if (!_imageDic) {
        _imageDic = [NSMutableDictionary dictionary];
    }
    return _imageDic;
}
- (NSMutableDictionary *)operationDic {
    if (!_operationDic) {
        _operationDic = [NSMutableDictionary dictionary];
    }
    return _operationDic;
}
- (NSOperationQueue *)queue {
    if (!_queue) {
        _queue = [[NSOperationQueue alloc] init];
    }
    return _queue;
}
- (UIScrollView *)scrollView {
    if (!_scrollView) {
        _scrollView = [[UIScrollView alloc] init];
        _scrollView.pagingEnabled = YES;//关键属性，整屏分页;
        _scrollView.bounces = NO;
        _scrollView.showsHorizontalScrollIndicator = NO;
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.delegate = self;
        
        _currentImageView = [[UIImageView alloc] init];
        _currentImageView.userInteractionEnabled = YES;
        [_currentImageView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(imageClick)]];
        [self.scrollView addSubview:_currentImageView];
        
        _nextImageView = [[UIImageView alloc] init];
        [self.scrollView addSubview:_nextImageView];
        [self addSubview:_scrollView];
    }
    return _scrollView;
}
- (UIPageControl *)pageControl {
    if (!_pageControl) {
        _pageControl = [[UIPageControl alloc] init];
        _pageControl.hidesForSinglePage = YES;//单页隐藏
        _pageControl.userInteractionEnabled = NO;
        [self addSubview:_pageControl];
    }
    return _pageControl;
}

#pragma mark 布局子控件
- (void)layoutSubviews {
    [super layoutSubviews];
    //有导航控制器时，会默认在scrollview上方添加64的内边距，这里强制设置为0
    self.scrollView.contentInset = UIEdgeInsetsZero;
}

#pragma mark - frame
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    self.scrollView.frame = self.bounds;
    //分页控件
    CGSize size = [_pageControl sizeForNumberOfPages:_images.count];
    _pageControl.frame = CGRectMake(self.scrollView.frame.size.width - size.width - 5, self.scrollView.frame.size.height - size.height + 5, size.width, size.height);
    
    _scrollView.contentOffset = CGPointMake(self.width, 0);//显示中间
    _currentImageView.frame = CGRectMake(self.width, 0, self.width, self.height);
    [self setScrollViewContentSize];//设置内容范围
}

#pragma mark - contentSize
- (void)setScrollViewContentSize {
    if (_images.count > 1) {
        _scrollView.contentSize = CGSizeMake(self.width * 3,  0);
        [self startTimer];
        
    }else {
        _scrollView.contentSize = CGSizeZero;
    }
}

#pragma mark - 设置时间及定时操作
- (void)setTime:(NSTimeInterval)time {
    _time = time;
    [self startTimer];
}
- (void)startTimer {
    if (_images.count <= 1) {
        return;
    }
    //默认时间设置,不得低于1s；
    self.timer = [NSTimer timerWithTimeInterval:_time < 1 ? DEFAULTTIME : _time target:self selector:@selector(nextPage) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
}
- (void)stopTimer {
    [self.timer invalidate];
    self.timer = nil;
}
- (void)nextPage {
    [_scrollView setContentOffset:CGPointMake(self.width * 2, 0) animated:YES];
}

#pragma mark - 图片点击事件 
- (void)imageClick {
    if (self.imageClickBlock) {
        self.imageClickBlock(self.currentIndex);
    }else if ([_delegate respondsToSelector:@selector(circulateView:didClickImage:)]) {
        [_delegate circulateView:self didClickImage:self.currentIndex];
    }
}

#pragma mrak - Initialization
- (instancetype)initWithImageAry:(NSArray *)imageAry {
    return [self initWithImageAry:imageAry imageClickBlock:nil];
}
+ (instancetype)circulateViewWithImageAry:(NSArray *)imageAry {
    return [self circulateViewWithImageAry:imageAry imageClickBlock:nil];
}

- (instancetype)initWithImageAry:(NSArray *)imageAry imageClickBlock:(ClickBlock)imageClickBlock {
    if (self = [super init]) {
        self.imageAry = imageAry;
        self.imageClickBlock = imageClickBlock;
    }
    return self;
}
+ (instancetype)circulateViewWithImageAry:(NSArray *)imageAry imageClickBlock:(ClickBlock)imageClickBlock {
    return [[self alloc] initWithImageAry:imageAry imageClickBlock:imageClickBlock];
}


#pragma mark - Direction Type
- (void)setCirculateViewDirectType:(GKCirculateViewDirectType)circulateViewDirectType {
    if (_circulateViewDirectType == circulateViewDirectType) {
        return;
    }
    _circulateViewDirectType = circulateViewDirectType;
    
    switch (circulateViewDirectType) {
        case GKCirculateViewNoneDirectType:
            return;
            break;
        case GKCirculateViewRightDirectType:
            self.nextImageView.frame = CGRectMake(0, 0, self.width, self.height);
            self.nextIndex = self.currentIndex - 1;
            if (self.nextIndex < 0) {
                self.nextIndex = self.images.count - 1;
            }
            break;
        case GKCirculateViewLeftDirectType:
            self.nextImageView.frame = CGRectMake(CGRectGetMaxX(self.currentImageView.frame), 0, self.width, self.height);
            self.nextIndex = (self.currentIndex + 1) % self.images.count;
            break;
        default:
            break;
    }
    self.nextImageView.image = self.images[self.nextIndex];
}

#pragma mark - imageAry
- (void)setImageAry:(NSArray *)imageAry {
    //NSParameterAssert(imageAry != nil);
    if (!imageAry.count) {
        return;
    }
    _imageAry = imageAry;
    _images = [NSMutableArray array];
    for (int i = 0; i < imageAry.count; i++) {
        if ([imageAry[i] isKindOfClass:[UIImage class]]) {//图片类
            [self.images addObject:imageAry[i]];
        }else if ([imageAry[i] isKindOfClass:[NSString class]]) {//图片网址类
            [self.images addObject:[UIImage imageNamed:@"placeholder"]];
        }
    }
    self.currentImageView.image = _images.firstObject;
    self.pageControl.numberOfPages = _images.count;
    [self setScrollViewContentSize];
}

#pragma mark - 图片加载
- (void)downLoadImages:(NSInteger)index {
    NSString *key = _imageAry[index];
    
    //读取缓存的图片
    UIImage *image = [self.imageDic objectForKey:key];
    if (image) {
        _images[index] = image;
        return;
    }
    //从沙盒缓存中取图片
    NSString *cache = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:@"GKCirculateView"];
    NSString *path = [cache stringByAppendingPathComponent:[key lastPathComponent]];
    NSData *data = [NSData dataWithContentsOfFile:path];
    if (data) {
        [UIImage imageWithData:data];
        _images[index] = image;
        [self.imageDic setObject:image forKey:key];
        return;
    }
    
    //下载图片
    NSBlockOperation *downLoad = [self.operationDic objectForKey:key];
    if (downLoad) {
        return;
    }
    //创建操作
    downLoad = [NSBlockOperation blockOperationWithBlock:^{
        NSURL *url = [NSURL URLWithString:key];
        NSData *data = [NSData dataWithContentsOfURL:url];
        if (!data) {
            return;
        }
        UIImage *image = [UIImage imageWithData:data];
        if (image) {
            [self.imageDic setObject:image forKey:key];
            _images[index] = image;
        }
        //如果下载的图片为当前要显示的图片，直接到主线程给imageView赋值，否则要等到下一轮才会显示
        if (_currentIndex == index) {
            [_currentImageView performSelectorOnMainThread:@selector(setImage:) withObject:image waitUntilDone:NO];
            [data writeToFile:path atomically:YES];
        }
        [self.operationDic removeObjectForKey:key];//
    }];
    [self.queue addOperation:downLoad];
    [self.operationDic setObject:downLoad forKey:key];
    
}
#pragma mark - 代理方法
//滚动事件方法, 滚动过程中会一直循环执行(滚动中...)
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offsetX = scrollView.contentOffset.x;
    self.circulateViewDirectType = offsetX > self.width ? GKCirculateViewLeftDirectType : offsetX < self.width ? GKCirculateViewRightDirectType : GKCirculateViewNoneDirectType;
   
}

//开始拖拽事件方法(手动)
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self stopTimer];
}

//拖拽操作完成事件方法(手动)
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
    [self startTimer];
}

//滚动停止事件方法(滚动过程中减速停止后执行操作)
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self pauseScroll];
}
//滚动动画停止时执行,setContentOffset改变时也触发
- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
    [self pauseScroll];
    NSLog(@"%@", NSStringFromCGPoint(scrollView.contentOffset));
}

- (void)pauseScroll {
    //整屏
    if (self.scrollView.contentOffset.x / self.width == 1){//不动
        return;
    }
    self.currentIndex = self.nextIndex;
    self.pageControl.currentPage = self.currentIndex;
    self.currentImageView.frame = CGRectMake(self.width, 0, self.width, self.height);
    self.currentImageView.image = self.nextImageView.image;
    self.scrollView.contentOffset = CGPointMake(self.width, 0);
}

#pragma mark - 缓存清除
- (void)clearDiskCache {
    NSString *cache = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingString:@"GKCirculateView"];
    NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:cache error:NULL];
    for (NSString *fileName in content) {
        [[NSFileManager defaultManager] removeItemAtPath:[cache stringByAppendingString:fileName] error:NULL];
    }
}
@end
