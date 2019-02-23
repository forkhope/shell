#!/bin/bash
#实现一个可旋转的方块. 在俄罗斯方块中,任何一种方块都是由四个小方块组成.所以
#可以用四个坐标为确定一个方块的样式,如下面boxCur数组所示:该方块的第一个小方
#块的坐标是(0,0),第二个小方块的坐标是(0,1),x坐标没变,y坐标加1,表明第二个小方
#块在第一个小方块的下方,第三个小方块的坐标是(2,1),x坐标加2,y坐标加1,表明第三
#个小方块在第一个小方块的对角线,类似可知,地四个小方块在第一个小方块的对角线
#的下方,可以得到这个方块是如下的形式(x轴在前,y轴在后,每个小方块的宽度是2):
#   []       第一个小方块的坐标是 (0,0)
#   [][]     第二个小方块的坐标是 (0,1)，第三个小方块的坐标是 (2,1) 
#     []     地四个小方块的坐标是 (2,2)

#定义整数常量变量,这些变量的值在程序中不会被修改,用于取代"魔法数字"
leftX=5          #边框离终端左边的距离
topY=2           #边框离终端上边的距离
width=20         #边框内部的宽度是 20 个字符宽,不包含边框本身的宽度
height=15        #边框内部的高度是 15 个字符高,不包含边框本身的高度
blockW=2         #每个小方块的宽度是 2 个字符宽
blockH=1         #每个小方块的高度是 1 个字符高
boxCurX=0        #方块当前离左边边框内侧的距离
boxCurY=0        #方块当前离上边边框内侧的距离
boxCur=(0 0 0 1 2 1 2 2)   #定义当前要显示的方块,这是一种反Z字型的方块
box=(0 0 0 1 2 1 2 2 0 1 2 0 2 1 4 0) #方块所有样式的坐标点(x轴在前,y轴在后)
countBox=2       #方块的所有可能旋转数目是 2 种,这是一个反Z字型的方块.
boxRotate=0      #方块的旋转角度初始化为0

Frame()          #显示边框
{
	echo -ne "\033[1;7;32;42m"    #高亮反白显示,绿色文本,绿色背景
	
	local i
	((t1 = leftX + 2 + width))       #计算右边边框的x轴坐标
	for ((i = 0; i != height; ++i)) 
	do
		((t2 = i + topY + 1))        #计算单位边框左、右部的y轴坐标
		echo -ne "\033[${t2};${leftX}H||"
		echo -ne "\033[${t2};${t1}H||"
	done

	((t2 = topY + 1 + height))       #计算边框底部的y轴坐标
	for ((i = 0; i != width / 2 + 2; ++i))
	do
		((t1 = i * 2 + leftX))       #计算边框顶、底部的x轴坐标
		echo -ne "\033[${topY};${t1}H=="  
		echo -ne "\033[${t2};${t1}H=="
	done
	echo -ne "\033[0m"
}

#绘画当前旋转角度的方块,需要传递一个参数,$1==0时,消除方块;$1==1时,显示方块
DrawCurBox()   
{
	local i j x y bDraw s sBox

	bDraw=$1
	s=""    # s 用来包含绘画全部方块的控制码
	if ((bDraw == 0))
	then
		sBox="\040\040"
	else
		sBox="[]"
		s=$s"\033[1;7;31;41m"
	fi
	
	#在 box 数组中,x轴坐标在前,y轴坐标在后;i 用来取x轴坐标,j 用来取y轴坐标
	for ((i = 0; i != 8; i += 2)) 
	do
		((j = i + 1))
		((x = leftX + blockW + boxCurX + ${boxCur[$i]})) #计算方块的x轴坐标
		((y = topY  + blockH + boxCurY + ${boxCur[$j]})) #计算方块的y轴坐标
		s=$s"\033[${y};${x}H${sBox}"   #包含绘画该方块的控制码到 s 中
	done
	s=$s"\033[0m"
	echo -ne $s
}

BoxMove()     #判断方块是否能够移动到新位置,该函数需要两个参数
{
	local i j x y xTest yTest
	xTest=$1  #第一个传进来的参数是新方块离左边边框内侧的距离
	yTest=$2  #第二个传进来的参数是新方块离上边边框内侧的距离
	for ((i = 0; i != 8; i += 2))
	do
		((j = i + 1))
		((x = xTest + ${boxCur[$i]}))
		((y = yTest + ${boxCur[$j]}))
		#因为方块本身要占去一定的宽和高,所以当相等的时候,已经撞到墙壁
		if ((x < 0 || x >= width || y < 0 || y >= height))  
		then
			return 1   #此时，表明新方块会撞到墙壁，不能移动
		fi
	done
	return 0           #此时，表明新方块没有撞到墙壁，可以移动   
}

BoxRotate()   #旋转方块
{
	local i j x y newRotate boxTest
	
	((boxRotate = boxRotate + 1))
	if ((boxRotate == countBox))  #如果新的旋转角度等于方块最大的旋转数目
	then
		boxRotate=0               #则将新的旋转角度置为0,从头开始旋转
	fi

	#把新的方块坐标赋给boxTest数组,该数组用来测试是否可以旋转
	for ((i = 0; i != 8; ++i))
	do
		boxTest[$i]=${box[boxRotate * 8 + $i]} 
	done

	#测试是否可以旋转
	for ((i = 0; i != 8; i += 2))
	do
		((j = i + 1))
		((x = boxCurX + ${boxTest[$i]}))
		((y = boxCurY + ${boxTest[$j]}))
		if ((x < 0 || x >= width || y < 0 || y >= height))
		then
			return 1    #不能旋转，跳出循环，返回
		fi
	done

	#可以旋转
	DrawCurBox 0        #消除原先的方块
	for ((i = 0; i != 8; ++i))
	do
		boxCur[$i]=${boxTest[$i]}    #更新 boxCur 数组的值
	done
	DrawCurBox 1        #显示新的方块
}

BoxDown()   #方块下落一行
{
	local boxNewY 
	
	boxNewY=$((boxCurY + blockH))
	if BoxMove ${boxCurX} ${boxNewY}
	then
		DrawCurBox 0   #将原先的方块消除
		((boxCurY = boxNewY))
		DrawCurBox 1   #显示新的方块
	fi
}

BoxLeft()   #方块左移一列
{
	local boxNewX 

	((boxNewX = boxCurX - blockW))
	if BoxMove $boxNewX $boxCurY
	then
		DrawCurBox 0
		((boxCurX = boxNewX))
		DrawCurBox 1
	fi
}

BoxRight()  #方块右移一列
{
	local boxNewX 

	((boxNewX = boxCurX + blockW))
	if BoxMove $boxNewX $boxCurY
	then
		DrawCurBox 0
		((boxCurX = boxNewX))
		DrawCurBox 1
	fi
}

MainRun()    #程序的主运行函数
{
	clear
	echo -ne "\033[?25l"    #隐藏光标
	Frame
	DrawCurBox 1

	while :
	do
		read -s -n 1 char
		case $char in
			"k")
				BoxRotate;;
			"j")
				BoxDown;;
			"h")
				BoxLeft;;
			"l")
				BoxRight;;
			"q")
				Key_exit;;
		esac
	done
}

Key_exit()
{
	echo -ne "\033[$((topY + height + 2));0H"  #将光标置到边框底部
	echo -e  "\033[?25h"
	exit 0
}

#脚本运行从这里开始
MainRun
