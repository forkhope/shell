#!/bin/bash
#一个求和程序.由用户输入两个整数,程序会进行求和并输出.
#注意,在bash中,进行数值运算,要使用两个小括号,或者一个中括号
#当在两个下括号中对表达式进行求值时,变量前面可以不用加$符号

echo -e "Please input 2 number: \n"  #echo的-e选项表示支持反斜杠转义字符
read -p "first number: " first
read -p "second number: " second
total=$((first + second))  #注意这里使用了两个小括号,如果只使用一个会出错
echo -e "\nThe number $first + $second is $total"

total=$[$first + $first]     #我现在还不知道这条命令的原理
echo -e "\nThe number $first + $first is $total"

((total = second + second))  #也可以直接这样写,和C的用法一样.
echo -e "\nThe number $second + $second is $total"
exit 0
