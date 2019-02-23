#!/bin/bash
#2010-4-19 第一版
# 从baidu 查询武汉的天气

wget -q -O /tmp/wuhan_weather.html "http://m.baidu.com/s?word=%E6%AD%A6%E6%B1%89&ssid=0&from=0&bd_page_type=1&pu=&uid=&tn_1=webmain&tn_6=weather&st_1=111041&st_6=106001&ct_6=%E5%A4%A9%E6%B0%94%E6%9F%A5%E8%AF%A2"

cat /tmp/wuhan_weather.html | w3m -dump -T text/html>/tmp/wuhan_weather.txt

head -n 4 /tmp/wuhan_weather.txt | sed '1d'
