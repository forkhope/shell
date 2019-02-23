#!/bin/bash
#介绍bash中 if 语句的判断依据.

equal()
{
	if (($1 == $2));then
		return 1
	fi
	
	return 0
}

#bash中, if 关键字后面紧跟的是一个可执行的命令,不能直接跟一个表达式.
# if 语句的判断依据为: 若命令的返回值为0,则if语句为真,执行then语句;若命令
#的返回值非0,则if语句为假,执行else语句(如果没有else语句,则终止if语句).
if equal 2 5
then
	echo "2 != 5"
else
	echo "2 == 5"
fi
exit 0
