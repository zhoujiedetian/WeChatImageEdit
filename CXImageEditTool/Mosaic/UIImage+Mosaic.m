//
//  UIImage+Mosaic.m
//  ImageEditDemo
//
//  Created by zhoujie on 2021/6/7.
//

#import "UIImage+Mosaic.h"
#import <Accelerate/Accelerate.h>

#define bitsPerComponent (8)
#define bitsPerPixel (32)
#define bytesPerRow (4)

@implementation UIImage (Mosaic)
//图片模糊处理
- (UIImage *)blurImageWithBlurNumber:(CGFloat)blur {
    
    NSData *imageData = UIImageJPEGRepresentation(self, 1); // convert to jpeg
    UIImage* destImage = [UIImage imageWithData:imageData];
    
    if (blur < 0.f || blur > 1.f) {
        blur = 0.5f;
    }
    int boxSize = (int)(blur * 40);
    boxSize = boxSize - (boxSize % 2) + 1;
    
    CGImageRef img = destImage.CGImage;
    
    vImage_Buffer inBuffer, outBuffer;
    
    vImage_Error error;
    
    void *pixelBuffer;
    
    
    //create vImage_Buffer with data from CGImageRef
    
    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);
    
    
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    inBuffer.data = (void*)CFDataGetBytePtr(inBitmapData);
    
    //create vImage_Buffer for output
    
    pixelBuffer = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    
    if(pixelBuffer == NULL)
        NSLog(@"No pixelbuffer");
    
    outBuffer.data = pixelBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);
    
    // Create a third buffer for intermediate processing
    void *pixelBuffer2 = malloc(CGImageGetBytesPerRow(img) * CGImageGetHeight(img));
    vImage_Buffer outBuffer2;
    outBuffer2.data = pixelBuffer2;
    outBuffer2.width = CGImageGetWidth(img);
    outBuffer2.height = CGImageGetHeight(img);
    outBuffer2.rowBytes = CGImageGetBytesPerRow(img);
    
    //perform convolution
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer2, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    error = vImageBoxConvolve_ARGB8888(&outBuffer2, &inBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0, boxSize, boxSize, NULL, kvImageEdgeExtend);
    if (error) {
        NSLog(@"error from convolution %ld", error);
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(outBuffer.data,
                                             outBuffer.width,
                                             outBuffer.height,
                                             8,
                                             outBuffer.rowBytes,
                                             colorSpace,
                                             (CGBitmapInfo)kCGImageAlphaNoneSkipLast);
    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];
    
    //clean up
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);
    
    free(pixelBuffer);
    free(pixelBuffer2);
    CFRelease(inBitmapData);
    
    CGImageRelease(imageRef);
    
    return returnImage;
}

/*
 * 转换成马赛克,level代表一个点转为多少level*level的正方形
 */
- (UIImage *)getMosaicImageFromOrginImageBlockLevel:(NSUInteger)level {
    // self == OrginImage
    //1,获取BitmapData
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB(); // 创建颜色空间,需要释放内存
                                                                //    CGColorSpaceRef colorSpace = CGImageGetColorSpace(self.CGImage);
    CGImageRef imgRef = self.CGImage;                           // 图片转换
    CGFloat width = CGImageGetWidth(imgRef);                    //图片宽
    CGFloat height = CGImageGetHeight(imgRef);                  //高

    // 2, 创建图片上下文(解析图片信息，绘制图片 开辟内存空间，这块空间用于处理马赛克图片
    /*
     参数4:代表每一个像素点,每一个分量大小(8位 2的8次 =255) (图形学中,一个像素点有ARGB组成,每一个颜色就分别代表一个分量,每一个分量大小: 8位 = 1字节)
     参数5:代表每一行的大小(图片由像素组成)
     计算:
     1, 计算一个像素点大小 = ARGB = 4 * 8 = 32位 = 4 字节
     2, 每一行大小 = 4字节 * width
     */
    CGContextRef context = CGBitmapContextCreate(nil, //数据源
                                                 width,
                                                 height,
                                                 bitsPerComponent,                // 通常是8
                                                 width * bytesPerRow,             //每一行的像素点占用的字节数(4)，每个像素点的ARGB四个通道各占8个bit
                                                 colorSpace,                      // 颜色空间
                                                 kCGImageAlphaPremultipliedLast); //是否需要透明度
    // 3, 根据图片上下文绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);

    // 4, 获取图片的指针(像素数组)
    unsigned char *bitmapData = CGBitmapContextGetData(context);
    //5, 核心算法 图片打码,加入马赛克,这里把BitmapData进行马赛克转换,让一个像素点替换为和它相同的矩形区域(正方形，圆形都可以)
    unsigned char pixel[bytesPerRow] = {0}; // 像素点默认是4个通道,默认值是0
    NSUInteger index, preIndex;             // 从左到右 上到下

    for (NSUInteger i = 0; i < height - 1; i++) // 行
    {
        for (NSUInteger j = 0; j < width - 1; j++) // 列
        {
            index = i * width + j;  // 获取当前像素点坐标
            if (i % level == 0)     // 新矩形开始(马赛克矩形第一行)
            {                       //行向所有被整除的坐标
                if (j % level == 0) // 第一个像素点 (马赛克矩形第一行第一个像素点)
                {                   //列向所有被整除的坐标 比如 3 * 3 (00 03 06 09.........)
                    /*
                     拷贝数据,例如 将马赛克矩阵第一行第一列像素点的值取出来替换后面的像素点的值
                     参数1: 目标数据----> pixels(像素点)
                     参数2: 原始数据----> bitmapPixels(图片像素数组)
                     参数3: 长度
                     指针位移方式获取像素点数据
                     像素点: 分量组成,指针位移,移动分量----> 4个字节 = 一个像素
                     */
                    memcpy(pixel, bitmapData + bytesPerRow * index, bytesPerRow); //给我们的像素点赋值
                }
                else
                {
                    // 在第二个满足马赛克矩阵的坐标之前的所有的坐标
                    memcpy(bitmapData + bytesPerRow * index, pixel, bytesPerRow);
                }
            }
            else
            {                                   // 行向没有被整除的其他的坐标
                preIndex = (i - 1) * width + j; //获取当前行上一行的坐标
                memcpy(bitmapData + bytesPerRow * index, bitmapData + bytesPerRow * preIndex, bytesPerRow);
            }
        }
    }

    // 6, 获取图片数据集合
    NSInteger dataLength = width * height * bytesPerRow;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, bitmapData, dataLength, NULL);
    CGBitmapInfo btimainfo = CGImageGetBitmapInfo(imgRef);
    //7, 创建要输出的图像
    CGImageRef mosaicImageRef = CGImageCreate(width, height,
                                              bitsPerComponent,           //表示每一个像素点，每一个分量的大小 8
                                              bitsPerPixel,               //每一个像素点的大小  4 * 8 = 32
                                              width * bytesPerRow,        //每一行内存大小
                                              colorSpace,                 //颜色空间
                                              btimainfo,  //位图信息
                                              provider,                   //数据源（数据集合）
                                              NULL,                       //数据解码器
                                              NO,                         // 是否抗锯齿
                                              kCGRenderingIntentDefault); //渲染器

    // 8 创建输出马赛克图片（填充颜色）
    CGContextRef outputContext = CGBitmapContextCreate(nil,
                                                       width,
                                                       height,
                                                       bitsPerComponent,
                                                       width * bytesPerRow,
                                                       colorSpace,
                                                       btimainfo);

    CGContextDrawImage(outputContext, CGRectMake(0.0f, 0.0f, width, height), mosaicImageRef); //  //绘制图片
    CGImageRef resultImageRef = CGBitmapContextCreateImage(outputContext);                    // //创建图片
    UIImage *resultImage = nil;
    if ([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)])
    {
        float scale = [[UIScreen mainScreen] scale];
        resultImage = [UIImage imageWithCGImage:resultImageRef scale:scale orientation:UIImageOrientationUp];
    }
    else
    {
        resultImage = [UIImage imageWithCGImage:resultImageRef];
    }
    //释放
    if (colorSpace)
    {
        CGColorSpaceRelease(colorSpace);
    }
    if (resultImageRef)
    {
        CFRelease(resultImageRef);
    }
    if (mosaicImageRef)
    {
        CFRelease(mosaicImageRef);
    }
    if (provider)
    {
        CGDataProviderRelease(provider);
    }
    if (context)
    {
        CGContextRelease(context);
    }
    if (outputContext)
    {
        CGContextRelease(outputContext);
    }
    return resultImage;
}
@end
