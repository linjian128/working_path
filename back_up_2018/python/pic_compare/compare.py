# -*- coding: utf-8 -*-
# usage: python compare.py
# 对比dd.png cc.png(裁剪后，box为裁剪参数) box = (IMAGE_X1,IMAGE_Y1,IMAGE_X2,IMAGE_Y2) #设定裁剪区域  
# 若没有不同，输出 “no diff”
# 若有不同，输出 图片“compare_out.jpg”

from PIL import Image
from PIL import ImageChops 

def compare_images(path_one, path_two, diff_save_location):
    """
    比较图片，如果有不同则生成展示不同的图片

    @参数一: path_one: 第一张图片的路径
    @参数二: path_two: 第二张图片的路径
    @参数三: diff_save_location: 不同图的保存路径
    """
    image_one = Image.open(path_one)
    image_two = Image.open(path_two)

    box = (0,80,1080,1920)

    diff = ImageChops.difference(image_one.crop(box),image_two.crop(box))

    if diff.getbbox() is None:
        # 图片间没有任何不同则直接退出
        print "no diff"
        return
    else:
        diff.save(diff_save_location)


if __name__ == '__main__':
    compare_images('dd.png',
                   'cc.png',
                   'compare_out.jpg')

