//
//  CXColorCell.h
//  ImageEditDemo
//
//  Created by zhoujie on 2021/6/1.
//

#import <UIKit/UIKit.h>



@interface CXColorCell : UICollectionViewCell
//如果color不为空，则显示colorVi，如果color为空，则显示撤回按钮
- (void)freshWithColor:(UIColor *)color isSelected:(BOOL)isSelected;
//如果color不为空，则显示colorVi，如果color为空，则显示文字按钮
- (void)freshWithWord:(UIColor *)color isSelected:(BOOL)isSelected;
//是否允许撤销操作
- (void)enableRecall:(BOOL)enable;
@end


