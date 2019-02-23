#一个用于批量重命名的脚本
#正则表达式中,单引号和双引号的区别在于:被单引号括起来的是纯粹的字符串,不会发
#生变量替换;被双引号括起来的会进行变量替换.一般常量用单引号''括起来,如果含有
#变量则用双引号""括起.下面的sed语句就要使用双引号,否则不会进行变量替换.例如,
#echo "$a"会输出变量存储的值,echo '$a'会输出字符串$a.
#!/bin/bash
read -p "请输入要替换的源字符串: " srcname
read -p "请输入替换后的目标字符串: " desname
for i in `ls | grep $srcname`
do
	#mv $i `echo $i | sed 's/'$srcname'/'$desname'/'`
	mv $i `echo $i | sed "s/$srcname/$desname/"` #这里的sed语句要使用双引号
done
exit
