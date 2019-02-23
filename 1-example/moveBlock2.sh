#!/bin/bash
#实现一个会动的方块,包含边框,通过背景重绘来实现消除原先的方块.

#定义整数常量变量的区域,有利于程序阅读和修改,防止出现"魔法数字"的情况
#下面的坐标参考系是:以终端的左上角为坐标原点(0,0),x轴向右为正,y轴向下为正
leftX=4       #边框左上角的X轴坐标
topY=2        #边框左上角的Y轴坐标
width=20      #边框内部宽度,不包含边框的宽度
height=16     #边框内部高度,不包含边框的高度
cBorder=2     #边框颜色的最后一位数字,32、42都是绿色,32是文本颜色,42是背景色
((blockX = leftX + 8))      #方块的初始x轴坐标
((blockY = topY  + 1))      #方块的初始y轴坐标

frame()       #显示边框
{
	echo -e "\033[1;3${cBorder};4${cBorder}m" #高亮显示,绿色文本,绿色背景
	
	local i
	((t2 = width + leftX + 2))             #计算边框右部的x轴坐标
	for ((i = 0; i != height; ++i))
	do
		((t1 = i + topY + 1))              #计算部分边框左、右部的y轴坐标
		echo -ne "\033[${t1};${leftX}H||"  #\033[y;xH可以设置光标位置
		echo -ne "\033[${t1};${t2}H||"     #注意是y轴在前,x轴在后.
	done

	((t2 = height + topY))                 #计算边框底部的y轴坐标
	((number = width / 2 + 2))             #计算顶、底部有多少个=号
	for ((i = 0; i != number; ++i))
	do
		((t1 = i * 2 + leftX))             #计算部分边框顶、底部的x轴坐标
		echo -ne "\033[${topY};${t1}H=="
		echo -ne "\033[${t2};${t1}H=="
	done
	echo -ne "\033[0m"
}

showBlock()   #显示方块  
{
	echo -ne "\033[41m"
	#使用方块的初始坐标,该坐标在脚本的最上面定义
	echo -ne "\033[${blockY};${blockX}H[][]"
	echo -ne "\033[$((blockY + 1));$((blockX + 2))H[][]"
	echo -ne "\033[0m"
}

redraw()      #用黑色的背景把方块重新画一遍,起到覆盖原先方块的效果
{
	local i
	echo -ne "\033[${blockY};${blockX}H    "
	echo -ne "\033[$((blockY + 1));$((blockX + 2))H    "
}

key_exit()    #脚本退出,进行一些还原设置
{
	echo -ne "\033[$((topY + height));0H"    #将光标置到边框下边
	echo -ne "\033[?25h"                     #显示光标
	echo -e  "\033[0m"
	exit 0
}

#脚本的主函数部分
clear
echo -ne "\033[?25l"      #隐藏光标
frame
showBlock

while :
do
	read -s -n 1 char     #读一个字符,且不回显
	redraw
	case $char in 
		"j")              #输入j,方块下移
			((++blockY));;
		"k")              #输入k,方块上移
			((--blockY));;
		"h")              #输入h,方块左移
			((--blockX));;
		"l")              #输入l,方块右移
			((++blockX));;
		"q")              #输入q,脚本退出
			key_exit;;
	esac
	#下面的if判断防止方块的坐标越界
	if   ((blockY < topY + 1));then
		((blockY = topY + 1))
	elif ((blockY > height));then
		((blockY = height))
	elif ((blockX < leftX + 2));then
		((blockX = leftX + 2))
	elif ((blockX > width));then
		((blockX = width))
	fi
	showBlock
done

echo -e "\033[0m"
exit 0
