#coding:utf-8

import codecs
import sys
#不加如下行，无法打印Unicode字符，产生UnicodeEncodeError错误。?
sys.stdout = codecs.lookup('iso8859-1')[-1](sys.stdout)

from lxml import etree

html = r'''<div>
    <div>redice</div>
        <div id="email">redice@163.com</div>
            <div name="address">中国</div>
                <div>http://www.redicecn.com</div>
                </div>'''

tree = etree.HTML(html)


#获取email。email所在的div的id为email
nodes = tree.xpath("//div[@id='email']")
print nodes[0].text

#获取地址。地址所在的div的name为address
nodes = tree.xpath("//div[@name='address']")
print nodes[0].text

#获取博客地址。博客地址位于email之后兄弟节点的第二个
nodes = tree.xpath("//div[@id='email']/following-sibling::div[2]")
print nodes[0].text

