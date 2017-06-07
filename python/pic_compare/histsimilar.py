# -*- coding: utf-8 -*-  
  
from PIL import Image  
  
def make_regalur_image(img, size = (256, 256)):  
    return img.resize(size).convert('RGB')  
#几何转变，全部转化为256*256像素大小  
  
def split_image(img, part_size = (64, 64)):  
    w, h = img.size  
    pw, ph = part_size  
      
    assert w % pw == h % ph == 0  
      
    return [img.crop((i, j, i+pw, j+ph)).copy() \
                for i in xrange(0, w, pw) \
                for j in xrange(0, h, ph)]  
#region = img.crop(box)  
#将img表示的图片对象拷贝到region中，这个region可以用来后续的操作（region其实就是一个  
#image对象，box是个四元组（上下左右））  
  
def hist_similar(lh, rh):  
    assert len(lh) == len(rh)  
    return sum(1 - (0 if l == r else float(abs(l - r))/max(l, r)) for l, r in zip(lh, rh))/len(lh)  
#好像是根据图片的左右间隔来计算某个长度，zip是可以接受多个x,y,z数组值统一输出的输出语句  
def calc_similar(li, ri):  
#   return hist_similar(li.histogram(), ri.histogram())  
    return sum(hist_similar(l.histogram(), r.histogram()) for l, r in zip(split_image(li), split_image(ri))) / 16.0 #256>64  
    #其中histogram()对数组x（数组是随机取样得到的）进行直方图统计，它将数组x的取值范围分为100个区间，  
        #并统计x中的每个值落入各个区间中的次数。histogram()返回两个数组p和t2，  
        #其中p表示各个区间的取样值出现的频数，t2表示区间。  
        #大概是计算一个像素点有多少颜色分布的  
        #把split_image处理的东西zip一下，进行histogram,然后得到这个值  
  
def calc_similar_by_path(lf, rf):  
    li, ri = make_regalur_image(Image.open(lf)), make_regalur_image(Image.open(rf))  
    return calc_similar(li, ri)  
  
def make_doc_data(lf, rf):  
    li, ri = make_regalur_image(Image.open(lf)), make_regalur_image(Image.open(rf))  
    li.save(lf + '_regalur.png')#转换图片格式:img.save('file.jpg'),保存临时的  
    ri.save(rf + '_regalur.png')#img对象到硬盘  
    fd = open('stat.csv', 'w')#stat模块是做随机变量统计的，stat用来计算随机变量的期望值和方差  
        #这句是关键啊，把histogram的结果进行map处理  
    fd.write('\n'.join(l + ',' + r for l, r in zip(map(str, li.histogram()), map(str, ri.histogram()))))  
#   print >>fd, '\n'  
#   fd.write(','.join(map(str, ri.histogram())))  
    fd.close()  
    from PIL import ImageDraw  
    li = li.convert('RGB') #与save对象，这是转换格式  
    draw = ImageDraw.Draw(li)  
    for i in xrange(0, 256, 64):  
        draw.line((0, i, 256, i), fill = '#ff0000')  
        draw.line((i, 0, i, 256), fill = '#ff0000')  
        #从始至终划线!!!!!!!!!!!!!!!通过把每一列刷成红色，来进行颜色的随机分布划分  
        #用法：pygame.draw.line(Surface, color, start_pos, end_pos, width=1)  
    li.save(lf + '_lines.png')  
      
  
if __name__ == '__main__':  
    path = r'testpic/TEST%d/%d.JPG'  
    '''
    for i in xrange(1, 7):  
        print 'test_case_%d: %.3f%%'%(i,calc_similar_by_path('testpic/TEST%d/%d.JPG'%(i, 1), 'testpic/TEST%d/%d.JPG'%(i, 2))*100)  
      '''

#    make_doc_data('test/TEST4/1.JPG', 'test/TEST4/2.JPG')  
