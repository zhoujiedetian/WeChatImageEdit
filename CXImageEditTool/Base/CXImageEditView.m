//
//  CXImageEditVC.m
//  ImageEditDemo
//
//  Created by zhoujie on 2021/5/31.
//

#import "CXImageEditView.h"
#import "CXImageEditConfig.h"
#import "CXToolCell.h"
#import "CXColorCell.h"
#import "CXScrawlView.h"
#import "CXWordView.h"
#import "CXWordLab.h"
#import "CXMosaicView.h"
#import "CXCropFunctionBar.h"
#import "CXCropCase.h"
#import "CXEditModel.h"

#define kAlphaAnimationDuration 0.15
//工具栏数量
#define kNumberOfTools 5
//颜色栏数量
#define kNumberOfColors 8
#define CXBottomToolHeight 44

@interface CXImageEditView ()<UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, CXWordViewDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate, CXScrawlViewDelegate, CXMosaicViewDelegate>
//用于处理缩放
@property(nonatomic, strong) UIScrollView *scrollVi;
//需要编辑的图片
@property(nonatomic, strong) UIImageView *editIgv;
//适配后的图片大小
@property(nonatomic, assign) CGSize editImageSize;
//图片横竖向
@property(nonatomic, assign) BOOL isHorizontal;
//是否展示工具栏
@property(nonatomic, assign) BOOL isShowToolBar;

//顶部工具栏容器
@property(nonatomic, strong) UIView *topBar;
//返回按钮
@property(nonatomic, strong) UIButton *backBtn;

//底部工具栏容器
@property(nonatomic, strong) UIView *bottomBar;
//底部工具栏图片
@property(nonatomic, copy) NSArray *toolImages;
//底部工具栏选中图片
@property(nonatomic, copy) NSArray *toolSelectedImages;
//底部工具栏选择器
@property(nonatomic, strong) UICollectionView *toolsCollection;
//颜色数组
@property(nonatomic, copy) NSArray *colorsArr;
//选择的颜色索引,默认值为2，代表红色
@property(nonatomic, assign) NSInteger selectColorIndex;
//选择工具的索引,默认-1，未选中
@property(nonatomic, assign) NSInteger selectToolIndex;
//颜色选择器
@property(nonatomic, strong) UICollectionView *colorsCollection;
//马赛克撤回按钮
@property(nonatomic, strong) UIButton * mosaicRecoveryBtn;
//马赛克撤回按钮容器
@property(nonatomic, strong) UIView *mosaicRecBtnContainer;
//涂鸦面板
@property(nonatomic, strong) CXScrawlView *scrawlVi;
//马赛克涂层
@property(nonatomic, strong) CXMosaicView *mosaicVi;

@property(nonatomic, strong) UIView *editIgvContainer;
//用于保存添加的文字
//@property(nonatomic, strong) NSMutableArray *wordsArr;
//剪裁功能底部按钮
@property(nonatomic, strong) CXCropFunctionBar *cropFunctionBar;
//是否为编辑模式
@property(nonatomic, assign) BOOL isEditMode;
//剪裁框
@property(nonatomic, strong) CXCropCase *cropCase;

@property(nonatomic, strong) CXEditModel *editModel;
//记录scroll初始化的scale
@property(nonatomic, assign) CGFloat initialZoomScale;
//记录开始剪裁之前的旋转方向
@property(nonatomic, assign) CXCropViewRotationDirection directionBeforeCrop;

@property(nonatomic, assign) CATransform3D scrollInitialTransform;
@end

@implementation CXImageEditView

- (instancetype)initWithEditImage:(UIImage *)image {
    if (self = [super initWithFrame:CGRectZero]) {
        [self setUpView];
        self.editImage = image;
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpView];
    }
    return self;
}

- (void)setEditImage:(UIImage *)editImage {
    _editImage = [self _compressHDImage:editImage];
    
    self.scrollVi.minimumZoomScale = kMinZoomScale;
    self.scrollVi.maximumZoomScale = kMaxZoomScale;
    self.scrollVi.zoomScale = 1;
    self.initialZoomScale = self.scrollVi.zoomScale;
    
    //计算图片适配后的大小
    [self _caculateImageSize];
    self.editIgvContainer.transform = CGAffineTransformIdentity;
    self.editIgvContainer.frame = CGRectMake(0, 0, _editImageSize.width, _editImageSize.height);
    self.editIgvContainer.layer.mask = nil;
    self.editIgv.image = _editImage;
    self.editIgv.frame = CGRectMake(0, 0, _editImageSize.width, _editImageSize.height);
    
    //设置contentSize
    self.scrollVi.contentSize = _editImageSize;
    //调整inset使图片居中显示
    [self _adjustEditImageViewToCenter];
    
    [self.mosaicVi generateMosaicImage:_editImage];
    self.mosaicVi.frame = CGRectMake(0, 0, _editImageSize.width, _editImageSize.height);
    self.scrawlVi.frame = CGRectMake(0, 0, _editImageSize.width, _editImageSize.height);
}

- (void)dealloc {
    NSLog(@"CXImageEditVC dealloc");
}

#pragma mark ********* SetUp *********
- (void)setUpView {
    //初始化记录编辑操作的model
    _editModel = [CXEditModel new];
    //工具栏未选中的图片
    _toolImages = @[@"pen", @"word", @"crop", @"mosaic"];
    //工具栏选中后的图片
    _toolSelectedImages = @[@"pen_selected", @"word_selected", @"crop_selected", @"mosaic_selected"];
    //颜色集合
    _colorsArr = @[CXUIColorFromRGB(0xffffff), CXUIColorFromRGB(0x000000), CXUIColorFromRGB(0xF5222D), CXUIColorFromRGB(0xFADB14), CXUIColorFromRGB(0x1890FF), CXUIColorFromRGB(0x52C41A), CXUIColorFromRGB(0x722ED1)];
    //默认涂鸦颜色为红色
    _selectColorIndex = 2;
    //默认没有选中工具栏里的任何一项
    _selectToolIndex = -1;
    //默认展示工具栏
    _isShowToolBar = YES;
    //默认非编辑模式
    _isEditMode = NO;
    self.backgroundColor = [UIColor blackColor];
    
    //初始化scrollView
    self.scrollVi.bounds = CGRectMake(0, 0, kScreenHeight, kScreenHeight);
    self.scrollVi.center = CGPointMake(kScreenWidth / 2, kScreenHeight / 2);
    [self addSubview:self.scrollVi];
    _scrollInitialTransform = self.scrollVi.layer.transform;
    
    self.editIgvContainer = [UIView new];
    [self.editIgvContainer addSubview:self.editIgv];
    [self.scrollVi addSubview:self.editIgvContainer];
    
    //初始化工具栏
    [self setUpToolBar];
    //添加马赛克层
    [self.editIgv addSubview:self.mosaicVi];
    //添加涂鸦层
    [self.editIgv addSubview:self.scrawlVi];
}

//初始化工具栏UI
- (void)setUpToolBar {
    
    //顶部工具栏
    [self.topBar addSubview:self.backBtn];
    [self addSubview:self.topBar];
    [self.backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(18);
        make.bottom.mas_equalTo(-12);
    }];
    [self.topBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(0);
        make.height.offset(kStatusBarHeight + CXNaviHeight);
    }];
    
    //底部工具栏
    [self.toolsCollection registerClass:[CXToolCell class] forCellWithReuseIdentifier:@"CXToolCell"];
    [self.bottomBar addSubview:self.toolsCollection];
    [self.colorsCollection registerClass:[CXColorCell class] forCellWithReuseIdentifier:@"CXColorCell"];
    [self.bottomBar addSubview:self.colorsCollection];
    
    [self.mosaicRecBtnContainer addSubview:self.mosaicRecoveryBtn];
    [self.bottomBar addSubview:self.mosaicRecBtnContainer];
    
    [self addSubview:self.bottomBar];
    
    [self.bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(0);
        make.height.offset(CXBottomSafeHeight + CXBottomToolHeight);
    }];
    
    [self.colorsCollection mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.mas_equalTo(0);
        make.height.offset(CXBottomToolHeight);
    }];
    
    //TODO:测试iOS 10上的布局
    [self.toolsCollection mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(0);
        if (@available(ios 11, *)) {
            make.bottom.equalTo(self.bottomBar.mas_safeAreaLayoutGuideBottom);
        }else {
            make.bottom.mas_equalTo(CXBottomSafeHeight);
        }
        make.height.offset(CXBottomToolHeight);
    }];
    
    //和colorsCollection的item大小一样
    CGFloat mosaicBtnWidth = (kScreenWidth - 16 * 2 - 10 * (kNumberOfColors - 1)) / kNumberOfColors;
    [self.mosaicRecBtnContainer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-16);
        make.top.mas_equalTo(0);
        make.width.offset(mosaicBtnWidth);
        make.height.offset(CXBottomToolHeight);
    }];
    
    [self.mosaicRecoveryBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.top.mas_equalTo(0);
    }];
    
    [self addSubview:self.cropFunctionBar];
    [self.cropFunctionBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.mas_equalTo(0);
    }];
}

#pragma mark ********* UICollectionViewDelegate *********

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if (collectionView == _toolsCollection) {
        return kNumberOfTools;
    }else if (collectionView == _colorsCollection) {
        return kNumberOfColors;
    }
    return 0;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section {
    if (collectionView == _toolsCollection) {
        return UIEdgeInsetsMake(0, 16, 0, 16);
    }else if (collectionView == _colorsCollection) {
        return UIEdgeInsetsMake(0, 16, 0, 16);
    }
    return UIEdgeInsetsZero;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
    if (collectionView == _toolsCollection) {
        return 0;
    }else if (collectionView == _colorsCollection) {
        return 0;
    }
    return 0;
}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout minimumInteritemSpacingForSectionAtIndex:(NSInteger)section {
    if (collectionView == _toolsCollection) {
        /*
         16 * 2: collection左右内间距
         40 * (kNumberOfTools - 1): 前面四个按钮宽度
         80: 完成按钮宽度
         spacing: 每个按钮之间的间距
         */
        CGFloat spacing = (kScreenWidth - 16 * 2 - 40 * (kNumberOfTools - 1) - 80) / (kNumberOfTools - 1);
        return spacing;
    }else if (collectionView == _colorsCollection) {
        return 10;
    }
    return 0;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == _toolsCollection) {
        CGFloat width = 40;
        if (indexPath.row == kNumberOfTools - 1) {
            //完成按钮
            width = 80;
        }
        return CGSizeMake(width, CXBottomToolHeight);
    }else if (collectionView == _colorsCollection) {
        CGFloat width = (kScreenWidth - 16 * 2 - 10 * (kNumberOfColors - 1)) / kNumberOfColors;
        return CGSizeMake(width, CXBottomToolHeight);
    }
    return CGSizeZero;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    if (collectionView == _toolsCollection) {
        CXToolCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CXToolCell" forIndexPath:indexPath];
        if (indexPath.row < _toolImages.count) {
            NSString *imageName;
            if (indexPath.row == _selectToolIndex) {
                //选中
                imageName = _toolSelectedImages[indexPath.row];
            }else {
                //未选中
                imageName = _toolImages[indexPath.row];
            }
            [cell freshWithData:imageName];
        }else {
            [cell freshWithData:nil];
        }
        return cell;
    }else if (collectionView == _colorsCollection) {
        CXColorCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"CXColorCell" forIndexPath:indexPath];
        if (indexPath.row < _colorsArr.count) {
            [cell freshWithColor:_colorsArr[indexPath.row] isSelected:(indexPath.row == _selectColorIndex)];
        }else {
            [cell freshWithColor:nil isSelected:(indexPath.row == _selectColorIndex)];
        }
        return cell;
    }
    return nil;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    
    if (collectionView == _toolsCollection) {
        
        _selectToolIndex = indexPath.row;
        
        //工具栏选择器
        if (indexPath.row == 0) {
            //涂鸦功能
            self.scrawlVi.userInteractionEnabled = !self.scrawlVi.userInteractionEnabled;
            self.colorsCollection.hidden = !self.scrawlVi.userInteractionEnabled;
            if (self.colorsCollection.hidden) {
                //关闭涂鸦功能
                [self.bottomBar mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.height.offset(CXBottomSafeHeight + CXBottomToolHeight);
                }];
                _selectToolIndex = -1;
            }else {
                //打开涂鸦功能
                [self.bottomBar mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.height.offset(CXBottomSafeHeight + CXBottomToolHeight + CXBottomToolHeight);
                }];
            }
            
            self.mosaicVi.userInteractionEnabled = NO;
            self.mosaicRecBtnContainer.hidden = YES;
        }
        
        if (indexPath.row == 1) {
            //添加文字功能
            CXWordView *wordVi = [[CXWordView alloc] initWithImage:[self _generateFullScreenImage]];
            wordVi.delegate = self;
            [self addSubview:wordVi];
            [wordVi mas_makeConstraints:^(MASConstraintMaker *make) {
                make.left.right.top.bottom.mas_equalTo(0);
            }];
            
            self.scrawlVi.userInteractionEnabled = NO;
            self.colorsCollection.hidden = YES;
            [self.bottomBar mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.offset(CXBottomSafeHeight + CXBottomToolHeight);
            }];
            self.mosaicVi.userInteractionEnabled = NO;
            self.mosaicRecBtnContainer.hidden = YES;

        }
        
        if (indexPath.row == 2) {
            
            //隐藏工具栏
            [self _showOrHideToolBar:NO];
            //进入编辑模式
            [self.cropFunctionBar show];
            [self _changeScrollIntoCropMode];
            
            self.scrawlVi.userInteractionEnabled = NO;
            self.colorsCollection.hidden = YES;
            [self.bottomBar mas_updateConstraints:^(MASConstraintMaker *make) {
                make.height.offset(CXBottomSafeHeight + CXBottomToolHeight);
            }];
            self.mosaicVi.userInteractionEnabled = NO;
            self.mosaicRecBtnContainer.hidden = YES;

        }
        
        if (indexPath.row == 3) {
            //马赛克
            self.mosaicVi.userInteractionEnabled = !self.mosaicVi.userInteractionEnabled;
            self.mosaicRecBtnContainer.hidden = !self.mosaicVi.userInteractionEnabled;
            if (self.mosaicRecBtnContainer.hidden) {
                //关闭马赛克功能
                [self.bottomBar mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.height.offset(CXBottomSafeHeight + CXBottomToolHeight);
                }];
                _selectToolIndex = -1;
            }else {
                //打开马赛克功能
                [self.bottomBar mas_updateConstraints:^(MASConstraintMaker *make) {
                    make.height.offset(CXBottomSafeHeight + CXBottomToolHeight + CXBottomToolHeight);
                }];
            }
            
            self.scrawlVi.userInteractionEnabled = NO;
            self.colorsCollection.hidden = YES;
        }
        
        if (indexPath.row == 4) {
            //完成
            UIImage *result;
            if (![self.scrawlVi canRecall] &&
                _editModel.words.count == 0 &&
                !_editModel.cropModel &&
                ![self.mosaicVi canRecall]) {
                //没有编辑过
                result = self.editImage;
            }else {
                //编辑过
                result = [self _generateImage];
            }
            if (self.completeEdit) {
                self.completeEdit(result);
            }
        }
        [self.toolsCollection reloadData];
    }else if (collectionView == _colorsCollection) {
        //颜色选择器
        UIColor *selectColor;
        //其他颜色
        if (indexPath.row < _colorsArr.count) {
            selectColor = _colorsArr[indexPath.row];
            self.scrawlVi.currentDrawColor = selectColor;
            [self.colorsCollection reloadData];
            _selectColorIndex = indexPath.row;
            return;
        }
        
        //撤回
        if ([self.scrawlVi canRecall]) {
            [self.scrawlVi recall];
            //更新撤回按钮状态
            [self scrawlDidEnd:nil];
        }
    }else {
        
    }
}

#pragma mark ********* UIScrollViewDelegate *********
- (nullable UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.editIgvContainer;
}

//调整inset保证图片缩放后居中
- (void)scrollViewDidZoom:(UIScrollView *)scrollView {

    if (_editModel.cropModel && !_isEditMode) {
        [self _updateContentInsetAfterCrop];
        return;
    }
    
    //剪裁模式不在此方法调整其contentInset
    if (_isEditMode) {
        return;
    }
    
    //此方法只在编辑初始页调整contentInset使其居中
    if (_isHorizontal) {
        if (self.scrollVi.contentSize.height > kScreenHeight) {
            //图片高大于屏幕高
            self.scrollVi.contentInset = UIEdgeInsetsZero;
        }else {
            //图片高小于屏幕高
            self.scrollVi.contentInset = UIEdgeInsetsMake((self.scrollVi.frame.size.height - self.scrollVi.contentSize.height) / 2, (self.scrollVi.frame.size.width - kScreenWidth) / 2, (self.scrollVi.frame.size.height - self.scrollVi.contentSize.height) / 2, (self.scrollVi.frame.size.width - kScreenWidth) / 2);
        }
    }else {
        if (self.scrollVi.contentSize.width > kScreenWidth) {
            //图片宽大于屏幕宽
            self.scrollVi.contentInset = UIEdgeInsetsZero;
        }else {
            //图片宽小于屏幕宽
            self.scrollVi.contentInset = UIEdgeInsetsMake((self.scrollVi.frame.size.height - kScreenHeight) / 2, (self.scrollVi.frame.size.width - self.scrollVi.contentSize.width) / 2  , (self.scrollVi.frame.size.height - kScreenHeight) / 2, (self.scrollVi.frame.size.width - self.scrollVi.contentSize.width) / 2);
        }
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    NSLog(@"scrollViewWillBeginDragging");
    [self.cropCase beginImageresizer];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    NSLog(@"scrollViewDidEndDecelerating");
    [self.cropCase endedImageresizer];
}

//结束拖动后无加速度
- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    if (CGPointEqualToPoint(velocity, CGPointZero)) {
        NSLog(@"scrollViewWillEndDragging");
        [self.cropCase endedImageresizer];
    }
}

- (void)scrollViewWillBeginZooming:(UIScrollView *)scrollView withView:(nullable UIView *)view {
    NSLog(@"scrollViewWillBeginZooming");
    [self.cropCase beginImageresizer];
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    NSLog(@"scrollViewDidEndZooming");
    [self.cropCase endedImageresizer];
}

#pragma mark ********* CXScrawlViewDelegate *********
- (void)scrawlBegan:(CXScrawlView *)scrawlView {
    //隐藏工具栏
    [self _showOrHideToolBar:NO];
}

- (void)scrawlDidEnd:(CXScrawlView *)scrawlView {
    CXColorCell *cell = (CXColorCell *)[self.colorsCollection cellForItemAtIndexPath:[NSIndexPath indexPathForRow:7 inSection:0]];
    BOOL canRecall = [self.scrawlVi canRecall];
    [cell enableRecall:canRecall];
    
    //显示工具栏
    [self _showOrHideToolBar:YES];
}

#pragma mark ********* CXWordViewDelegate *********
//添加文字
- (void)didAddWord:(NSString *)text textColor:(UIColor *)textColor isShowBg:(BOOL)isShowBg {
    CXWordLab *wordLab = [CXWordLab new];
    wordLab.textColor = textColor;
    wordLab.text = text;
    wordLab.isShowBackgroundVi = isShowBg;
    __weak typeof(wordLab) weakWord = wordLab;
    __weak typeof(self) weakSelf = self;
    wordLab.closeBlock = ^{
        [weakSelf.editModel.words removeObject:weakWord];
        [weakWord removeFromSuperview];
    };
    if (_editModel.cropModel) {
        CGFloat centerXPercent = 0.5 * (1 - (_editModel.cropModel.cropToImagePercentEdge.left + _editModel.cropModel.cropToImagePercentEdge.right)) + _editModel.cropModel.cropToImagePercentEdge.left;
        CGFloat centerYPercent = 0.5 * (1 - (_editModel.cropModel.cropToImagePercentEdge.top + _editModel.cropModel.cropToImagePercentEdge.bottom)) + _editModel.cropModel.cropToImagePercentEdge.top;
        wordLab.center = CGPointMake(self.editIgv.bounds.size.width * centerXPercent, self.editIgv.bounds.size.height * centerYPercent);
    }else {
        wordLab.center = CGPointMake(self.editIgv.bounds.size.width / 2, self.editIgv.bounds.size.height / 2);
    }
    CGSize size = [wordLab sizeThatFits:CGSizeMake(kScreenWidth, kScreenHeight)];
    wordLab.bounds = CGRectMake(0, 0, size.width, size.height);
    [wordLab showBorderAutoHide];
    [self _fixWordsOrientationAndSize:wordLab];
//    [self.editIgv addSubview:wordLab];
    [self.editIgvContainer addSubview:wordLab];
    
    [self.editModel.words addObject:wordLab];
    
    UIPanGestureRecognizer *wordPan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(panWordVi:)];
    wordPan.maximumNumberOfTouches = 1;
    wordPan.delegate = self;
    [wordLab addGestureRecognizer:wordPan];

    UIPinchGestureRecognizer *wordPinch = [[UIPinchGestureRecognizer alloc]initWithTarget:self action:@selector(pinchWordVi:)];
    wordPinch.delegate = self;
    [wordLab addGestureRecognizer:wordPinch];
    
    UIRotationGestureRecognizer *wordRotation = [[UIRotationGestureRecognizer alloc]initWithTarget:self action:@selector(rotationWordVi:)];
    wordRotation.delegate = self;
    [wordLab addGestureRecognizer:wordRotation];
    
    UITapGestureRecognizer *tapWord = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapWordVi:)];
    [wordLab addGestureRecognizer:tapWord];
    
    UITapGestureRecognizer *doubleTapWord = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(doubleTapWordVi:)];
    doubleTapWord.numberOfTapsRequired = 2;
    [wordLab addGestureRecognizer:doubleTapWord];
    
    [tapWord requireGestureRecognizerToFail:doubleTapWord];
    
    self.scrollVi.panGestureRecognizer.maximumNumberOfTouches = 1;
    [self.scrollVi.panGestureRecognizer requireGestureRecognizerToFail:wordPan];
    [self.scrollVi.panGestureRecognizer requireGestureRecognizerToFail:wordPinch];
    [self.scrollVi.panGestureRecognizer requireGestureRecognizerToFail:wordRotation];
    [self.scrollVi.pinchGestureRecognizer requireGestureRecognizerToFail:wordPinch];
    [self.scrollVi.pinchGestureRecognizer requireGestureRecognizerToFail:wordRotation];
    
    //清除选中的文字选项
    _selectToolIndex = -1;
    [self.toolsCollection reloadData];
}

- (void)didClickCancel:(CXWordView *)wordView {
    //清除选中的文字选项
    _selectToolIndex = -1;
    [self.toolsCollection reloadData];
}

#pragma mark ********* CropButtonClicked *********
//进入编辑模式
- (void)_changeScrollIntoCropMode {
    
    _isEditMode = YES;
    for (CXWordLab *wordLab in _editModel.words) {
        [wordLab hideBorderRightNow];
    }
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (_editModel.cropModel) {
        _directionBeforeCrop = _editModel.cropModel.rotationDirection;
       //曾经编辑过
        //缩小scroll的倍数
        CGFloat cropScale = self.initialZoomScale * 0.7;
        if (cropScale < self.scrollVi.minimumZoomScale) {
            self.scrollVi.minimumZoomScale = cropScale;
        }
        
        UIViewAnimationOptions options = UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState;
        [UIView animateWithDuration:0.25 delay:0 options:options animations:^{
            [self.scrollVi setZoomScale:cropScale animated:NO];
            self.editIgvContainer.layer.mask = nil;
            self.scrollVi.contentInset = self.editModel.cropModel.contentInset;
            self.scrollVi.contentOffset = self.editModel.cropModel.contentOffset;
//            [self _adjustEditImageViewToCenter];
        } completion:^(BOOL finished) {
            self.cropCase = [[CXCropCase alloc]initWithFrame:self.scrollVi.frame scrollVi:self.scrollVi imageView:self.editIgv cropModel:self.editModel.cropModel];
            [self insertSubview:self.cropCase belowSubview:self.cropFunctionBar];
        }];
        
    }else {
        _directionBeforeCrop = CXCropViewRotationDirectionUp;
       //未编辑过
        //缩小scroll的倍数
        CGFloat cropScale = self.initialZoomScale * 0.7;
        if (cropScale < self.scrollVi.minimumZoomScale) {
            self.scrollVi.minimumZoomScale = cropScale;
        }
        
        UIViewAnimationOptions options = UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState;
        [UIView animateWithDuration:0.25 delay:0 options:options animations:^{
            [self.scrollVi setZoomScale:cropScale animated:NO];
            [self _adjustEditImageViewToCenter];
        } completion:^(BOOL finished) {
            self.cropCase = [[CXCropCase alloc]initWithFrame:self.scrollVi.frame scrollVi:self.scrollVi imageView:self.editIgv];
            [self insertSubview:self.cropCase belowSubview:self.cropFunctionBar];
        }];
    }
}

- (void)_afterCropAdjustScrollWithEditedImage:(UIImage *)editedImage {
//    _editImage = editedImage;
    CGFloat editScale = self.editModel.cropModel.zoomScale;
    //放大动画
    CGFloat scale = 1 / 0.7;
    scale *= editScale;
    self.scrollVi.minimumZoomScale = scale;
    if (scale > self.scrollVi.maximumZoomScale) {
        self.scrollVi.maximumZoomScale = scale;
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIViewAnimationOptions options = UIViewAnimationOptionCurveEaseIn | UIViewAnimationOptionBeginFromCurrentState;
        [UIView animateWithDuration:0.25 delay:0 options:options animations:^{
            [self.scrollVi setZoomScale:scale animated:NO];
            [self _updateContentInsetAfterCrop];
        } completion:^(BOOL finished) {
            self.initialZoomScale = self.scrollVi.zoomScale;
        }];
    });
    
}


#pragma mark ********* CXMosaicViewDelegate *********
- (void)mosaicBegan:(CXMosaicView *)mosaicView {
    //隐藏工具栏
    [self _showOrHideToolBar:NO];
}

- (void)mosaicDidEnd:(CXMosaicView *)mosaicView {
    BOOL canRecall = [self.mosaicVi canRecall];
    self.mosaicRecoveryBtn.userInteractionEnabled = canRecall;
    self.mosaicRecoveryBtn.alpha = canRecall ? 1 : 0.4;
    //显示工具栏
    [self _showOrHideToolBar:YES];
}

#pragma mark ********* UIGestureRecognizerDelegate *********
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
//    if ([gestureRecognizer.view isKindOfClass:[CXWordLab class]] &&
//        [otherGestureRecognizer.view isKindOfClass:[CXWordLab class]]) {
//        return YES;
//    }
//    if ([gestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
//        return NO;
//    }
//    if ([otherGestureRecognizer.view isKindOfClass:[UIScrollView class]]) {
//        return NO;
//    }
    return YES;
}

#pragma mark ********* EventResponse *********
//点击图片
- (void)clickEditImage {
    if (_isEditMode) {
        return;
    }
    _isShowToolBar = !_isShowToolBar;
    [self _showOrHideToolBar:_isShowToolBar];
}

//点击返回
- (void)clickBack {
    //清除编辑操作
    [self.scrawlVi clear];
    for (CXWordLab *lab in _editModel.words) {
        [lab removeFromSuperview];
    }
    _editModel.words = nil;
    _editModel.cropModel = nil;
    [self.mosaicVi clear];
    self.scrollVi.layer.transform = CATransform3DIdentity;
    
    if (self.customBackAction) {
        self.customBackAction();
        return;
    }
    [self removeFromSuperview];
}

//点击马赛克撤回
- (void)clickMosaicRecovery {
    if ([self.mosaicVi canRecall]) {
        [self.mosaicVi recall];
        [self mosaicDidEnd:nil];
    }
}

#pragma mark ********* Router *********
- (void)routerWithEventName:(NSString *)eventName DataInfo:(NSDictionary *)dataInfo {
    //点击了剪裁功能的取消按钮
    if ([eventName isEqualToString:kCXCropFunctionBar_CloseBtn_Clicked]) {
        //退出编辑模式
        _isEditMode = NO;
        [self _showOrHideToolBar:YES];
        [self.cropCase cancelDelayHandle];
        [self.cropCase removeFromSuperview];
        self.cropCase = nil;
        
        if (_editModel.cropModel) {
            CAShapeLayer *maskLayer = [CAShapeLayer layer];
            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRect:_editModel.cropModel.cropFrameOnImageView];
            maskLayer.path = bezierPath.CGPath;
            self.editIgvContainer.layer.mask = maskLayer;
            [self _afterCropAdjustScrollWithEditedImage:_editModel.cropModel.cropImage];
            UIViewAnimationOptions options = UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState;
            [UIView animateWithDuration:0.25 delay:0 options:options animations:^{
                [self _rotationScrollWithDiretion:self.directionBeforeCrop];
            } completion:^(BOOL finished) {
                
            }];
        }else {
            self.scrollVi.minimumZoomScale = self.initialZoomScale;
            UIViewAnimationOptions options = UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState;
            [UIView animateWithDuration:0.25 delay:0 options:options animations:^{
                [self _rotationScrollWithDiretion:self.directionBeforeCrop];
                [self.scrollVi setZoomScale:self.initialZoomScale animated:NO];
                [self _adjustEditImageViewToCenter];
            } completion:^(BOOL finished) {
                
            }];
        }
        return;
    }
    
    //点击剪裁功能的还原按钮
    if ([eventName isEqualToString:kCXCropFunctionBar_RecoveryBtn_Clicked]) {
        [self.cropCase recovery];
        return;
    }
    
    //剪裁工具栏的还原按钮是否能点击
    if ([eventName isEqualToString:kCXCropCase_IsCanRecovery]) {
        BOOL isCanRecovery = [dataInfo[@"isCanRecovery"] boolValue];
        [self.cropFunctionBar isCanRecovery:isCanRecovery];
        return;
    }
    
    //点击剪裁功能的旋转按钮
    if ([eventName isEqualToString:kCXCropFunctionBar_RotationBtn_Clicked]) {
        [self.cropCase rotation];
        return;
    }
    
    //点击了剪裁功能的完成按钮
    if ([eventName isEqualToString:kCXCropFunctionBar_FinishBtn_Clicked]) {
        __weak typeof(self) weakSelf = self;
        [self.cropCase cropImageWithComplete:^(UIImage * _Nonnull image, CXCropModel *cropModel) {
            weakSelf.editModel.cropModel = cropModel;
            //退出编辑模式
            weakSelf.isEditMode = NO;
            [weakSelf _showOrHideToolBar:YES];
            [self.cropCase cancelDelayHandle];
            [weakSelf.cropCase removeFromSuperview];
            weakSelf.cropCase = nil;
            
            [weakSelf _afterCropAdjustScrollWithEditedImage:image];
        }];
        return;
    }
    [super routerWithEventName:eventName DataInfo:dataInfo];
}

#pragma mark ********* WordGesture *********
//计算当前展示图片部分的中心
- (CGPoint)_caculateEditIgvCenter {
    CGPoint center = CGPointZero;
    if (_editModel.cropModel) {
        CGFloat x = self.editIgv.frame.origin.x;
        CGFloat y = self.editIgv.frame.origin.y;
        CGFloat width = self.editIgv.frame.size.width;
        CGFloat height = self.editIgv.frame.size.height;
        CGFloat horizontalShowRatio = 1 - _editModel.cropModel.cropToImagePercentEdge.left - _editModel.cropModel.cropToImagePercentEdge.right;
        CGFloat verticalShowRatio = 1 - _editModel.cropModel.cropToImagePercentEdge.top - _editModel.cropModel.cropToImagePercentEdge.bottom;
        CGFloat showWidth = width * horizontalShowRatio;
        CGFloat showHeight = height * verticalShowRatio;
        CGFloat showX = width * _editModel.cropModel.cropToImagePercentEdge.left + x;
        CGFloat showY = height * _editModel.cropModel.cropToImagePercentEdge.top + y;
        CGRect showRect = CGRectMake(showX, showY, showWidth, showHeight);
        center = CGPointMake(CGRectGetMidX(showRect), CGRectGetMidY(showRect));
    }else {
        center = self.editIgv.center;
    }
    return center;
}
/* 为了实现文本框超出图片被截取的功能，在滑动的时候在文本框添加到_editIgvContainer,在滑动完成的时候再添加回_editIgv */
- (void)panWordVi:(UIPanGestureRecognizer *)pan {
    if (_isEditMode) {
            return;
        }
    CXWordLab *word = (CXWordLab *)pan.view;

    static CGPoint originCenter;
    static CGPoint startPanLocation;
    static CGPoint endPanLocation;

    if (pan.state == UIGestureRecognizerStateBegan) {
        CGRect rectOnIgv = word.frame;
        CGRect rectOnContainer = [_editIgv convertRect:rectOnIgv toView:self.editIgvContainer];
        word.center = CGPointMake(CGRectGetMidX(rectOnContainer), CGRectGetMidY(rectOnContainer));
        [self.editIgvContainer addSubview:word];
        [word showBorderForever];
        originCenter = word.center;
        startPanLocation = [pan locationInView:self.editIgvContainer];
    }else if (pan.state == UIGestureRecognizerStateChanged) {
        endPanLocation = [pan locationInView:self.editIgvContainer];
        word.center = CGPointMake(originCenter.x + (endPanLocation.x - startPanLocation.x), originCenter.y + (endPanLocation.y - startPanLocation.y));
    }else if (pan.state == UIGestureRecognizerStateEnded ||
              pan.state == UIGestureRecognizerStateCancelled) {
        CGFloat horizontalShowRatio = 1;
        CGFloat verticalShowRatio = 1;
        if (_editModel.cropModel) {
            horizontalShowRatio = 1 - _editModel.cropModel.cropToImagePercentEdge.left - _editModel.cropModel.cropToImagePercentEdge.right;
            verticalShowRatio = 1 - _editModel.cropModel.cropToImagePercentEdge.top - _editModel.cropModel.cropToImagePercentEdge.bottom;
        }
        CGPoint imageCurrentCenter = [self _caculateEditIgvCenter];
        if (fabs(word.center.y - imageCurrentCenter.y) > self.editIgv.frame.size.height * verticalShowRatio / 2 ||
            fabs(word.center.x - imageCurrentCenter.x) > self.editIgv.frame.size.width * horizontalShowRatio / 2) {
            //X轴或Y轴超过图片
            word.center = originCenter;
        }
        
        CGRect tempRect = [self.editIgvContainer convertRect:word.frame toView:self.editIgv];
        word.center = CGPointMake(CGRectGetMidX(tempRect), CGRectGetMidY(tempRect));
        [self.editIgv addSubview:word];
        [word hideBorder];
        if (CGRectIsNull(CGRectIntersection(word.frame, self.editIgv.frame))) {
            [self.editModel.words removeObject:word];
            [word removeFromSuperview];
        }
    }else {
        CGRect tempRect = [self.editIgvContainer convertRect:word.frame toView:self.editIgv];
        word.center = CGPointMake(CGRectGetMidX(tempRect), CGRectGetMidY(tempRect));
        [self.editIgv addSubview:word];
        [word hideBorder];
    }
}
- (void)pinchWordVi:(UIPinchGestureRecognizer *)pinch {
    if (_isEditMode) {
        return;
    }
    CXWordLab *word = (CXWordLab *)pinch.view;
    if (pinch.state == UIGestureRecognizerStateBegan) {
        CGRect rectOnIgv = word.frame;
        CGRect rectOnContainer = [_editIgv convertRect:rectOnIgv toView:self.editIgvContainer];
        word.center = CGPointMake(CGRectGetMidX(rectOnContainer), CGRectGetMidY(rectOnContainer));
        if (word.superview != self.editIgvContainer) {
            [self.editIgvContainer addSubview:word];
        }
        [word showBorderForever];
    }else if (pinch.state == UIGestureRecognizerStateChanged) {
        word.transform = CGAffineTransformScale(word.transform, pinch.scale, pinch.scale);
        pinch.scale = 1;
    }else if (pinch.state == UIGestureRecognizerStateEnded) {
        CGRect tempRect = [self.editIgvContainer convertRect:word.frame toView:self.editIgv];
        word.center = CGPointMake(CGRectGetMidX(tempRect), CGRectGetMidY(tempRect));
        [self.editIgv addSubview:word];
        [word hideBorder];
    }else if (pinch.state == UIGestureRecognizerStateCancelled) {
        CGRect tempRect = [self.editIgvContainer convertRect:word.frame toView:self.editIgv];
        word.center = CGPointMake(CGRectGetMidX(tempRect), CGRectGetMidY(tempRect));
        [self.editIgv addSubview:word];
        [word hideBorder];
    }
}

- (void)rotationWordVi:(UIRotationGestureRecognizer *)rotation {
    if (_isEditMode) {
        return;
    }
    CXWordLab *word = (CXWordLab *)rotation.view;
    if (rotation.state == UIGestureRecognizerStateBegan) {
        CGRect rectOnIgv = word.frame;
        CGRect rectOnContainer = [_editIgv convertRect:rectOnIgv toView:self.editIgvContainer];
        word.center = CGPointMake(CGRectGetMidX(rectOnContainer), CGRectGetMidY(rectOnContainer));
        if (word.superview != self.editIgvContainer) {
            [self.editIgvContainer addSubview:word];
        }
        [word showBorderForever];
    }else if (rotation.state == UIGestureRecognizerStateChanged) {
        word.transform = CGAffineTransformRotate(word.transform, rotation.rotation);
        rotation.rotation = 0;
    }else if (rotation.state == UIGestureRecognizerStateEnded) {
        CGRect tempRect = [self.editIgvContainer convertRect:word.frame toView:self.editIgv];
        word.center = CGPointMake(CGRectGetMidX(tempRect), CGRectGetMidY(tempRect));
        [self.editIgv addSubview:word];
        [word hideBorder];
    }else if (rotation.state == UIGestureRecognizerStateCancelled) {
        CGRect tempRect = [self.editIgvContainer convertRect:word.frame toView:self.editIgv];
        word.center = CGPointMake(CGRectGetMidX(tempRect), CGRectGetMidY(tempRect));
        [self.editIgv addSubview:word];
        [word hideBorder];
    }
}

- (void)tapWordVi:(UITapGestureRecognizer *)tap {
    if (_isEditMode) {
        return;
    }
    CXWordLab *word = (CXWordLab *)tap.view;
    [word showBorderAutoHide];
}

- (void)doubleTapWordVi:(UITapGestureRecognizer *)doubleTap {
    if (_isEditMode) {
        return;
    }
    CXWordLab *word = (CXWordLab *)doubleTap.view;
    NSString *tempStr = word.text;
    word.hidden = YES;
    
    //添加文字功能
    CXWordView *wordVi = [[CXWordView alloc] initWithImage:[self _generateFullScreenImage]];
    wordVi.delegate = self;
    [wordVi setText:tempStr textColor:word.textColor isShowBg:word.isShowBackgroundVi];
    //取消编辑
    wordVi.editCancel = ^{
        word.hidden = NO;
    };
    //完成编辑
    wordVi.editComplete = ^(NSString * _Nonnull content, UIColor * _Nonnull textColor, BOOL isShowBg) {
        word.hidden = NO;
        word.text = content;
        word.textColor = textColor;
        word.isShowBackgroundVi = isShowBg;
        CGSize size = [word sizeThatFits:CGSizeMake(kScreenWidth, kScreenHeight)];
        word.bounds = CGRectMake(0, 0, size.width, size.height);
    };
    [self addSubview:wordVi];
    [wordVi mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.mas_equalTo(0);
    }];
    
    CABasicAnimation *basic = [CABasicAnimation animationWithKeyPath:@"position"];
    basic.fromValue = [NSValue valueWithCGPoint:CGPointMake(kScreenWidth/2, kScreenHeight * 1.5)];
    basic.toValue = [NSValue valueWithCGPoint:CGPointMake(kScreenWidth/2, kScreenHeight * 0.5)];
    basic.duration = 0.25;
    basic.fillMode = kCAFillModeForwards;
    [wordVi.layer addAnimation:basic forKey:nil];
}

#pragma mark ********* PublicMethod *********
- (void)clearAllEditHandle {
    //清除编辑操作
    [self.scrawlVi clear];
    for (CXWordLab *lab in _editModel.words) {
        [lab removeFromSuperview];
    }
    [_editModel.words removeAllObjects];
    _editModel.cropModel = nil;
    [self.mosaicVi clear];
    self.scrollVi.layer.transform = CATransform3DIdentity;
}

#pragma mark ********* PrivateMethod *********
//计算图片适配后大小
- (void)_caculateImageSize {
    if (!_editImage) return;
    CGFloat imageWidth = _editImage.size.width;
    CGFloat imageHeight = _editImage.size.height;
    CGFloat screenRatio = kScreenWidth / kScreenHeight;
    CGFloat imageRatio = imageWidth / imageHeight;
    _isHorizontal = (imageRatio >= screenRatio);
    if (_isHorizontal) {
        _editImageSize = CGSizeMake(kScreenWidth, imageHeight * (kScreenWidth / imageWidth));
    }else {
        _editImageSize = CGSizeMake(imageWidth * (kScreenHeight / imageHeight), kScreenHeight);
    }

}

//生成合成图片
- (UIImage *)_generateImage {
    if (_editModel.words.count > 0) {
            for (CXWordLab *wordLab in _editModel.words) {
                [wordLab hideBorderRightNow];
            }
        }
    CGFloat scale = _editImage.size.width / _editIgv.frame.size.width;
    NSInteger imageWidth = floor(self.editIgv.frame.size.width);
    NSInteger imageHeight = floor(self.editIgv.frame.size.height);
    CGSize contextSize = CGSizeMake(imageWidth, imageHeight);
    UIGraphicsBeginImageContextWithOptions(contextSize, NO, scale);
    [self.editIgvContainer.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *resultImg = UIGraphicsGetImageFromCurrentImageContext();
    CGRect cropRect;
    if (_editModel.cropModel) {
        CGFloat x = resultImg.size.width * resultImg.scale * _editModel.cropModel.cropToImagePercentEdge.left;
        CGFloat y = resultImg.size.height * resultImg.scale * _editModel.cropModel.cropToImagePercentEdge.top;
        CGFloat width = resultImg.size.width * resultImg.scale * (1 - _editModel.cropModel.cropToImagePercentEdge.left - _editModel.cropModel.cropToImagePercentEdge.right);
        CGFloat height = resultImg.size.height * resultImg.scale * (1 - _editModel.cropModel.cropToImagePercentEdge.top - _editModel.cropModel.cropToImagePercentEdge.bottom);
        cropRect = CGRectMake(x, y, width, height);
    }else {
        cropRect = CGRectMake(0, 0, resultImg.size.width * resultImg.scale, resultImg.size.height * resultImg.scale);
    }

    CGImageRef imageRefRect = CGImageCreateWithImageInRect(resultImg.CGImage, cropRect);
    UIImage *sendImage = [[UIImage alloc] initWithCGImage:imageRefRect];
    if (_editModel.cropModel) {
        sendImage = [self _getTargetDirectionImage:sendImage];
    }
    CGImageRelease(imageRefRect);
    UIGraphicsEndImageContext();
    return sendImage;

}

//根据方向获取正确的图片
- (UIImage *)_getTargetDirectionImage:(UIImage *)image {
    UIImageOrientation orientation;
    switch (_editModel.cropModel.rotationDirection) {
        case CXCropViewRotationDirectionLeft:
            orientation = UIImageOrientationLeft;
            break;
            
        case CXCropViewRotationDirectionDown:
            orientation = UIImageOrientationDown;
            break;
            
        case CXCropViewRotationDirectionRight:
            orientation = UIImageOrientationRight;
            break;
            
        default:
            orientation = UIImageOrientationUp;
            break;
    }
    return [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:orientation];
}

//生成全屏的合成图片
- (UIImage *)_generateFullScreenImage {
    if (_editModel.words.count > 0) {
            for (CXWordLab *wordLab in _editModel.words) {
                [wordLab hideBorderRightNow];
            }
        }
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(kScreenWidth, kScreenHeight), YES, 0);
    CGSize imageSize = self.editIgv.bounds.size;
    CGFloat x = (kScreenWidth - imageSize.width) / 2;
    CGFloat y = (kScreenHeight - imageSize.height) / 2;
    [self.editIgv drawViewHierarchyInRect:CGRectMake(x, y, imageSize.width, imageSize.height) afterScreenUpdates:YES];
    UIImage *resultImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return resultImg;
}

//隐藏或显示工具栏
- (void)_showOrHideToolBar:(BOOL)isShow {
    _isShowToolBar = isShow;
    CGFloat alpha = isShow ? 1 : 0;
    UIViewAnimationOptions option = UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState;
    [UIView animateWithDuration:kAlphaAnimationDuration delay:0 options:option animations:^{
        self.topBar.alpha = alpha;
        self.bottomBar.alpha = alpha;
    } completion:^(BOOL finished) {
        
    }];
}

//将图片调整至居中
- (void)_adjustEditImageViewToCenter {
    self.scrollVi.contentInset = UIEdgeInsetsMake((CGRectGetHeight(self.scrollVi.frame) - CGRectGetHeight(self.editIgvContainer.frame)) / 2,
                                                  (CGRectGetWidth(self.scrollVi.frame) - CGRectGetWidth(self.editIgvContainer.frame)) / 2,
                                                  (CGRectGetHeight(self.scrollVi.frame) - CGRectGetHeight(self.editIgvContainer.frame)) / 2,
                                                  (CGRectGetWidth(self.scrollVi.frame) - CGRectGetWidth(self.editIgvContainer.frame)) / 2);
}

//根据剪裁框来更新scroll的内间距
- (void)_updateContentInsetAfterCrop {
    CGFloat showWidth = CGRectGetWidth(self.editIgvContainer.frame) * (1 - _editModel.cropModel.cropToImagePercentEdge.left - _editModel.cropModel.cropToImagePercentEdge.right);
    CGFloat showHeight = CGRectGetHeight(self.editIgvContainer.frame) * (1 - _editModel.cropModel.cropToImagePercentEdge.top - _editModel.cropModel.cropToImagePercentEdge.bottom);
    CGFloat left = (CGRectGetWidth(self.scrollVi.frame) - showWidth) / 2 - _editModel.cropModel.cropToImagePercentEdge.left * CGRectGetWidth(self.editIgvContainer.frame);
    CGFloat right = (CGRectGetWidth(self.scrollVi.frame) - showWidth) / 2 - _editModel.cropModel.cropToImagePercentEdge.right * CGRectGetWidth(self.editIgvContainer.frame);
    //超出屏幕部分可滑动
    if (showWidth > kScreenWidth) {
        CGFloat shouldMoveSpacing = (showWidth - kScreenWidth) * 0.5;
        left += shouldMoveSpacing;
        right+= shouldMoveSpacing;
    }
    CGFloat top = (CGRectGetHeight(self.scrollVi.frame) - showHeight) / 2 - _editModel.cropModel.cropToImagePercentEdge.top * CGRectGetHeight(self.editIgvContainer.frame);
    CGFloat bottom = (CGRectGetHeight(self.scrollVi.frame) - showHeight) / 2 - _editModel.cropModel.cropToImagePercentEdge.bottom * CGRectGetHeight(self.editIgvContainer.frame);
    //超出屏幕部分可滑动
    if (showHeight > kScreenHeight) {
        CGFloat shouldMoveSpacing = (showHeight - kScreenHeight) * 0.5;
        top += shouldMoveSpacing;
        bottom+= shouldMoveSpacing;
    }
    UIEdgeInsets contentInset = UIEdgeInsetsMake(top, left, bottom, right);
    self.scrollVi.contentInset = contentInset;
}

//压缩高清图片
- (UIImage *)_compressHDImage:(UIImage *)image {
    if (image.size.width < 5000 && image.size.height < 5000) {
        return image;
    }
    CGFloat imageRatio = image.size.width / image.size.height;
    CGFloat width = 1024;
    CGFloat height = 1024 / imageRatio;
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), YES, 0);
    [image drawInRect:CGRectMake(0, 0, width, height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)_rotationScrollWithDiretion:(CXCropViewRotationDirection)direction {
    CGFloat scale = 0;
    if (direction == CXCropViewRotationDirectionLeft ||
        direction == CXCropViewRotationDirectionRight) {
        scale = kScreenWidth / self.scrollVi.bounds.size.height;
    }else {
        scale = self.scrollVi.bounds.size.height / kScreenWidth;
    }
    CGFloat angle = -M_PI / 2;
    
    switch (direction) {
        case CXCropViewRotationDirectionUp:
            angle = 0;
            break;
        case CXCropViewRotationDirectionLeft:
            angle = -M_PI / 2;
            break;
        case CXCropViewRotationDirectionDown:
            angle = -M_PI;
            break;
        case CXCropViewRotationDirectionRight:
            angle = -3 * M_PI / 2;
            break;
            
        default:
            break;
    }
    
    UIViewAnimationOptions options = UIViewAnimationOptionCurveLinear | UIViewAnimationOptionBeginFromCurrentState;
    [UIView animateWithDuration:0.25 delay:0 options:options animations:^{
        self.scrollVi.layer.transform = CATransform3DRotate(self.scrollInitialTransform, angle, 0, 0, 1);
    } completion:^(BOOL finished) {

    }];
}

//修正添加文字时的方向
- (void)_fixWordsOrientationAndSize:(CXWordLab *)lab {
    
    if (!_editModel.cropModel) {
        return;
    }
    CATransform3D transform = lab.layer.transform;
    CGFloat angle = 0;
    switch (_editModel.cropModel.rotationDirection) {
        case CXCropViewRotationDirectionUp:
            angle = 0;
            break;
        case CXCropViewRotationDirectionLeft:
            angle = M_PI / 2;
            break;
        case CXCropViewRotationDirectionDown:
            angle = M_PI;
            break;
        case CXCropViewRotationDirectionRight:
            angle = 3 * M_PI / 2;
            break;
            
        default:
            break;
    }
    transform = CATransform3DRotate(transform, angle, 0, 0, 1);
    transform = CATransform3DScale(transform, 1 / self.scrollVi.zoomScale, 1 / self.scrollVi.zoomScale, 1);
    lab.layer.transform = transform;
}

//更新editIgvContainer的遮罩
- (void)_updateImageContainerMaskLayer {
    CAShapeLayer *layer = [CAShapeLayer layer];
    UIBezierPath *path;
    if (_editModel.cropModel) {
        //剪裁过
        path = [UIBezierPath bezierPathWithRect:self.editIgvContainer.bounds];
    }else {
        //没有剪裁过
        path = [UIBezierPath bezierPathWithRect:self.editIgvContainer.bounds];
    }
    layer.path = path.CGPath;
    self.editIgvContainer.layer.mask = layer;
}

#pragma mark ********* Getter *********
- (UIScrollView *)scrollVi {
    if (!_scrollVi) {
        _scrollVi = [[UIScrollView alloc]init];
        _scrollVi.delegate = self;
        _scrollVi.maximumZoomScale = 4.0;
        _scrollVi.minimumZoomScale = 1;
        _scrollVi.showsVerticalScrollIndicator = NO;
        _scrollVi.showsHorizontalScrollIndicator = NO;
        if (@available(iOS 11.0, *)) {
            _scrollVi.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        }
    }
    return _scrollVi;
}

- (UIImageView *)editIgv {
    if (!_editIgv) {
        _editIgv = [UIImageView new];
        _editIgv.contentMode = UIViewContentModeScaleAspectFit;
        _editIgv.userInteractionEnabled = YES;
        _editIgv.clipsToBounds = YES;
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(clickEditImage)];
        [_editIgv addGestureRecognizer:tap];
    }
    return _editIgv;
}

- (UIView *)topBar {
    if (!_topBar) {
        _topBar = [UIView new];
        _topBar.backgroundColor = CXUIColorFromRGBA(0x000000, 0.6);
    }
    return _topBar;
}

- (UIButton *)backBtn {
    if (!_backBtn) {
        _backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backBtn setImage:[UIImage imageNamed:@"back"] forState:0];
        [_backBtn addTarget:self action:@selector(clickBack) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backBtn;
}

- (UIView *)bottomBar {
    if (!_bottomBar) {
        _bottomBar = [UIView new];
        _bottomBar.backgroundColor = CXUIColorFromRGBA(0x000000, 0.6);
    }
    return _bottomBar;
}

- (UICollectionView *)toolsCollection {
    if (!_toolsCollection) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        _toolsCollection = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        _toolsCollection.delegate = self;
        _toolsCollection.dataSource = self;
        _toolsCollection.backgroundColor = [UIColor clearColor];
    }
    return _toolsCollection;
}

- (CXScrawlView *)scrawlVi {
    if (!_scrawlVi) {
        _scrawlVi = [CXScrawlView new];
        _scrawlVi.userInteractionEnabled = NO;
        _scrawlVi.delegate = self;
    }
    return _scrawlVi;
}

- (CXMosaicView *)mosaicVi {
    if (!_mosaicVi) {
        _mosaicVi = [CXMosaicView new];
        _mosaicVi.userInteractionEnabled = NO;
        _mosaicVi.delegate = self;
    }
    return _mosaicVi;
}

- (UICollectionView *)colorsCollection {
    if (!_colorsCollection) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc]init];
        _colorsCollection = [[UICollectionView alloc]initWithFrame:CGRectZero collectionViewLayout:layout];
        _colorsCollection.delegate = self;
        _colorsCollection.dataSource = self;
        _colorsCollection.hidden = YES;
        _colorsCollection.backgroundColor = [UIColor clearColor];
    }
    return _colorsCollection;
}

- (UIView *)mosaicRecBtnContainer {
    if (!_mosaicRecBtnContainer) {
        _mosaicRecBtnContainer = [UIView new];
        _mosaicRecBtnContainer.backgroundColor = [UIColor clearColor];
        _mosaicRecBtnContainer.hidden = YES;
    }
    return _mosaicRecBtnContainer;
}

- (UIButton *)mosaicRecoveryBtn {
    if (!_mosaicRecoveryBtn) {
        _mosaicRecoveryBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_mosaicRecoveryBtn setImage:[UIImage imageNamed:@"recall"] forState:0];
        _mosaicRecoveryBtn.userInteractionEnabled = NO;
        _mosaicRecoveryBtn.alpha = 0.4;
        [_mosaicRecoveryBtn addTarget:self action:@selector(clickMosaicRecovery) forControlEvents:UIControlEventTouchUpInside];
    }
    return _mosaicRecoveryBtn;
}

- (CXCropFunctionBar *)cropFunctionBar {
    if (!_cropFunctionBar) {
        _cropFunctionBar = [[CXCropFunctionBar alloc]init];
        _cropFunctionBar.alpha = 0;
    }
    return _cropFunctionBar;
}
@end
