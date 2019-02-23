#!/bin/bash
# 2010-4-19 第一版 
# 从baidu 获取的天气
city=$1
# wget -q 表示屏蔽输出,也就是不输出内容到终端上, －O表示输出网页到文档上
wget -q -O /tmp/baidu_weather.html "http://wap.baidu.com/tq?&ssid=0&from=0&area=${city}&uid=frontui_1265135393_3194&vit=tj&vit=tj&bd_page_type=1"
# w3m -dump 表示下载一个格式化的页面到stdout, -T 表示内容格式转换
cat /tmp/baidu_weather.html | w3m -dump -T text/html>/tmp/baidu_weather.txt

head -n 4 /tmp/baidu_weather.txt | sed '1d'
