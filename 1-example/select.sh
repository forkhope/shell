#!/bin/bash
#使用select语句实现一个字符界面、用户交互选择的菜单.该语句会先显示PS3提示符
#(该提示符是系统变量),然后等待用户输入,输入的应当是菜单列表的一个数字.

#下面三条语句定义select菜单的参数.
PS3="Please select a option: " #定义select菜单的提示语句,默认为#?
IFS=:                          #定义select菜单多个选项间的分隔符,默认为空格
OPTIONS="Hello:date:cal:Quit"  #定义select菜单的选项,选项之间用分隔符分开

#下面使用select菜单. select菜单执行的时候相当于一个循环,它会不断执行,直到
#遇到exit语句或其他的退出语句为止.每次执行,也就是用户作出选择后,定义在语句
#select opt in $OPTIONS中的变量opt就保存了被选中的选项,程序会根据用户的选择
#作出相应的动作.一般会采用case语句来对应select菜单中的所有选项和出错选项.

#每次执行,result都会被重新赋值,具体的赋值情况是OPTIONS的不同而不同.
#注意,每个case分支的最后一条语句都必须是两个分号;;
select result in $OPTIONS
do
	case $result in
	Hello)
	 	echo "$result, I am lixianyi!";;  #此时, result == Hello
	date)
		$result;; #此时, result == cal
	cal)
		$result;; #此时, result == date
	Quit)
		echo "$result"                    #此时, result == Quit
		exit;; #退出select循环菜单
	*)                                    #此时, retult == ""
		echo "$result";; #处理其他的非法输入,相等于C语言中的default分支
	esac
done

exit
