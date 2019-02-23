#!/bin/bash
filename=f.cc       #创建一个变量,名为filename

#如果想要删除文件,可以使用./file.sh clear命令
if [ $1 == "clear" ]
then
	rm f f.cc
	exit 0
fi

#如果想要再次编译,可以使用./file.sh gcc命令
if [ $1 == "gcc" ]
then
	g++ -o f f.cc
	exit 0
fi

#下面的echo语句预先为f.cc文件输入几句常用代码
echo "#include<iostream>
using std::cout;
using std::endl;
int main()
{
}">f.cc
vim $filename       #使用$符号来提取变量的值
if [ -e $filename ] #使用判断符号[]时要特别注意,头尾两边有两个空格,必不可少
then				#-e用来判断文件是否存在.如果文件f.cc存在,则执行下面语句
	g++ -o f f.cc
	./f
fi

#如果想要再次编辑文件,可以选择先不删除文件
read -p "是否要删除文件?(y/n): " choice
if [ "$choice" == "y" ]
then
	rm f f.cc
fi
