#!/bin/bash
#实现一个会动的方块.通过清屏来实现的简易版

top()        #显示方块和上方之间的间隔
{
	local i
	echo -ne "\033[0m"
	for ((i = 0; i != $1; ++i))
	do
		echo
	done
}

left()       #显示方块和左方之间的间隔
{
	local i
	echo -ne "\033[0m"
	for ((i = 0; i != $1; ++i))
	do
		echo -ne " "
	done
}

key_exit()   #脚本的退出设置
{
	echo -ne "\033[0m"
	echo -ne "\033[?25h"  #显示光标
	clear
	exit 0
}

display()   #显示方块
{
	clear   #清屏，从而消除原先的方块
	top  $1
	left $2
	echo -ne "\033[43m[][]\n"
	left $2
	echo -ne "\033[43m[][]\n"
	echo -ne "\033[0m"
}

#脚本的主函数部分
clear
echo -ne "\033[?25l"     #隐藏光标
tnum=12
lnum=10
display $tnum $lnum
#可以使用while :;来实现一个死循环.":"是bash的空命令,不做任何动作,只返回true
while true;do
#read的-s选项表示不回显,-n选项表示读入的字符个数,后面的1表示只读一个字符
read -s -n 1 char        
case $char in
	"k")          #按k，方块向上移，tnum减1
		((--tnum));;
	"j")          #按j，方块向下移，tnum加1
		((++tnum));;
	"h")          #按h，方块向左移，lnum减1
	 	((--lnum));;
	"l")          #按l，方块向右移，lnum加1
		((++lnum));;
	"q")          #按q，退出循环，脚本结束
		key_exit;;
esac
#下面的if语句防止tnum和lnum越界
if (($tnum < 2));then
	tnum=2
elif (($tnum > 20));then
	tnum=20
elif (($lnum < 2));then
	lnum=2
elif (($lnum > 34));then
	lnum=34
fi
#显示新的方块
display $tnum $lnum
done
exit 0
