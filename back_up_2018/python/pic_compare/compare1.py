# coding:utf-8
# usage: python compare1.py  a.jpg  .
# 用a.jpg 与 当前目录所有图片对比，输出 与每个图片的相似度

import glob  
import os  
import sys  
from PIL import Image  
   
EXTS = 'jpg', 'jpeg', 'JPG', 'JPEG', 'gif', 'GIF', 'png', 'PNG'  
   
def avhash(im):#通过计算哈希值来得到该张图片的"指纹"
    if not isinstance(im, Image.Image):#判断参数im，是不是Image类的一个参数
        im = Image.open(im)
    im = im.resize((8, 8), Image.ANTIALIAS).convert('L')  
    #resize，格式转换，把图片压缩成8*8大小，ANTIALIAS是抗锯齿效果开启，“L”是将其转化为  
    #64级灰度，即一共有64种颜色  
    avg = reduce(lambda x, y: x + y, im.getdata()) / 64.#递归取值，这里是计算所有  
                                                        #64个像素的灰度平均值  
    return reduce(lambda x, (y, z): x | (z << y),  
                  enumerate(map(lambda i: 0 if i < avg else 1, im.getdata())),  
                  0)#比较像素的灰度，将每个像素的灰度与平均值进行比较，>=avg：1；<avg：0  
   
def hamming(h1, h2):#比较指纹，等同于计算“汉明距离”（两个字符串对应位置的字符不同的个数）  
    h, d = 0, h1 ^ h2  
    while d:  
        h += 1  
        d &= d - 1  
    return h  
   
if __name__ == '__main__':  
    if len(sys.argv) <= 1 or len(sys.argv) > 3:#sys.argv是用来获取命令行参数的，[0]是本身路径  
        print "Usage: %s image.jpg [dir]" % sys.argv[0]#起码要有>1，才能有2张图比较  
    else:  
        im, wd = sys.argv[1], '.' if len(sys.argv) < 3 else sys.argv[2]  
        h = avhash(im)  
   
        os.chdir(wd)#chdir是更改目录函数  
        images = []  
        for ext in EXTS:  
            images.extend(glob.glob('*.%s' % ext))  
         #返回一个含有包含有匹配文件/目录的数组,在比对之前  
        seq = []  
        prog = int(len(images) > 50 and sys.stdout.isatty())  
        for f in images:  
            seq.append((f, hamming(avhash(f), h)))  
            if prog:  
                perc = 100. * prog / len(images)  
                x = int(2 * perc / 5)  
                print '\rCalculating... [' + '#' * x + ' ' * (40 - x) + ']',  
                print '%.2f%%' % perc, '(%d/%d)' % (prog, len(images)),  
                sys.stdout.flush()  
                prog += 1  
   
        if prog: print  
        for f, ham in sorted(seq, key=lambda i: i[1]):  
            print "%d\t%s" % (ham, f)  
