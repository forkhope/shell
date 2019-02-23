#!/bin/bash
#显示一个蓝色的长方形.

space()           #最左边的墙和终端最左边的间隔
{
	#echo命令默认会加上换行符,而-n选项让echo不输出行尾的换行符
	echo -n "         " #9个空格
}

wall_interval()   # interval:间隔的意思.该函数将两边的墙隔开
{
	echo -ne "\033[0m"
	echo -n "                     " #21个空格
}

display()          #显示给定数目个给定的字符
{
	local i
	echo -ne "\033[0m"
	space
	echo -ne "\033[44;32m"  #蓝色背景,绿色文本
	for ((i = 0; i != $1; ++i));
	do
		echo -ne $2; 
	done;
}

wall()               #将两边的墙显示出来
{
	local i
	for ((i = 0; i != 21; ++i));
	do
		echo
		display 2 "|"
		wall_interval
		display 2 "|";
	done;
}

clear      #清屏
echo       #换行
display 34 "="
wall
echo
display 34 "="
echo -e "\033[0m"
exit 0
