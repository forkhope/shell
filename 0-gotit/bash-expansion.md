# 记录 bash expansion 的相关笔记

查看 man bash 的说明，查找 EXPANSION 关键字，就能找到 bash 扩展的详细描述。

# 算术扩展
在 bash 中，算术扩展（arithmetic expansion）可以获取算术表达式的运算结果。  
还可以进行加减乘除运算、比较大小、比较是否相等、进行与或非运算，等等。

查看 man bash 的说明如下：
> Arithmetic expansion allows the evaluation of an arithmetic expression and the substitution of the result. The format for arithmetic expansion is:  
```
       $((expression))
```
> The old format $[expression] is deprecated and will be removed in upcoming versions of bash.  
> The expression is treated as if it were within double quotes, but a double quote inside the parentheses is not treated specially. All tokens in the expression undergo parameter and variable expansion, command substitution, and quote removal.  
> The result is treated as the arithmetic expression to be evaluated. Arithmetic expansions may be nested.
>
> The evaluation is performed according to the rules listed below under ARITHMETIC EVALUATION. If expression is invalid, bash prints a message indicating failure and no substitution occurs.

即，`$((expression))` 算术扩展会按照 *ARITHMETIC EVALUATION* 描述的规则来评估 *expression* 算术表达式，并获取到该表达式的值。

算术表达式里面默认进行变量扩展、命令替换、移除引号。  
由于默认进行变量扩展，可以直接用变量名来获取变量值，不需要在变量名前面加 `$` 符号。

如果只是要评估算术表达式，不需要获取算术表达式的值，写为 `((expression))` 即可。  
查看 man bash 对 `((expression))` 复合命令的说明如下：
> **((expression))**  
The expression is evaluated according to the rules described below under ARITHMETIC EVALUATION.  
> If the value of the expression is non-zero, the return status is 0; otherwise the return status is 1.  
> This is exactly equivalent to let "expression".

即，写为 `((expression))` 这个形式，也会按照 *ARITHMETIC EVALUATION* 描述的规则来评估 *expression* 算术表达式，只是获取不到该表达式的值。  
它等价于 `let "expression"` 语句。

具体的 ARITHMETIC EVALUATION 规则可以查看 man bash 的说明，里面的关键点如下：
> The operators and their precedence, associativity, and values are the same as in the C language.

即，在 `((expression))` 表达式中，所使用的运算符、运算符优先级、运算符结合规则跟 C 语言一致。  
对于熟悉 C 语言的人来说，方便使用。

具体举例说明如下：
```bash
$ number=1
$ number+=5
$ echo $number
15
$ number=$((number + 3))
$ echo $number
18
$ ((number += 3))
$ echo $number
21
```
可以看到，先将 *number* 赋值为 1，然后执行 `number+=5` 语句。  
但是打印 *number* 变量值，结果是 15，而不是 6。  
即，直接写为 `number+=5` 的形式，是字符串拼接，而不是进行算术运算。

`number=$((number + 3))` 命令使用算术扩展，会获取到 *number* 变量值加上 3 之后的值，并赋值给 *number* 变量值，是 18。  
这个表达式进行了算术运算。

`((number += 3))` 命令没有使用算术扩展，只是处理算术表达式。  
通过算术表达式的 `+=` 赋值操作符，把 *number* 变量值加上 3，并赋值给 *number* 变量。  
这个写法跟 `number=$((number + 3))` 命令的效果相同。

在算术表达式内，直接通过 *number* 变量名就可以获取变量值，不需要写为 `$number` 的形式。

总的来说，在 bash 中，要进行算术表达式运算，需要使用特定的写法、或者在一些支持算术运算的命令中使用。  
直接写为算术表达式自身，并不能进行算术运算。

## 使用算法表达式进行比较判断
在 bash 的 算法表达式中，支持 `<=、>=、<、>、==、!=` 这 6 个常见的运算符，可用于进行比较判断。

假设有一个 `arth_check.sh` 脚本，内容如下：
```bash
#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 number1 number2"
    exit 1
fi

number1="$1"
number2="$2"

if ((number1 > number2)); then
    echo "$number1 > $number2"
elif ((number1 < number2)); then
    echo "$number1 < $number2"
elif ((number1 == number2)); then
    echo "$number1 == $number2"
else
    echo "Should never be here."
fi
```
这个 `arth_check.sh` 脚本要求提供两个参数，然后用算术表达式比较这两个参数值的大小关系。

使用 `if ((number1 > number2))` 语句进行比较判断，变量名和 `((` 和 `))` 之间可以不加空格，也不需要对 `>` 操作符进行转义。  
如果使用 `[` 命令来比较，则变量名和 `[` 和 `]` 之间必须加空格，还要用 `\` 对 `>` 操作符进行转义。  
也就是写为 `if [ number1 \> number2 ]`。  
可以看到，使用 `if ((number1 > number2))` 这个写法更加简单方便，可以避免不加空格、或者不转义带来的异常。

执行 `arth_check.sh` 脚本，结果如下：
```bash
$ ./arth_check.sh 1 2
1 < 2
$ ./arth_check.sh 2 1
2 > 1
$ ./arth_check.sh 2 2
2 == 2
```
