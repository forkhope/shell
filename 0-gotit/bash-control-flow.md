# 记录 bash control flow 的相关笔记

# 详解 bash 的 select 命令弹出选择菜单
Bash 的 select 复合命令 (compound command) 可以弹出一个菜单列表给用户选择，并根据用户的选择进行相应的处理。查看 man bash 里面对 select 命令的说明如下：
> **select name [ in word ] ; do list ; done**  
The list of words following "in" is expanded, generating a list of items. The set of expanded words is printed on the standard error, each preceded by a number. If the "in word" is omitted, the positional parameters are printed. The PS3 prompt is then displayed and a line read from the standard input. If the line consists of a number corresponding to one of the displayed words, then the value of name is set to that word. If the line is empty, the words and prompt are displayed again. If EOF is read, the command completes. Any other value read causes name to be set to null. The line read is saved in the virable REPLY. The list is executed after each selection until a break command is executed. The exit status of select is the exit status of the list command executed in list, or zero if no commands were executed.

**注意**：上面的 `[ in word ]` 表示 "in word" 是可选参数，用于提供菜单列表，实际输入的时候不需要输入 `[]` 这两个字符。这里的 `[]` 并不是 bash 里面的条件判断命令。Bash 有一个 `[` 条件判断命令，其格式是 `[ 参数... ]`，两者格式比较相似，注意区分，不要搞混。

当没有提供 *in word* 参数时，`select` 命令默认使用 *in "$@"* 参数，也就是传入脚本、或者传入函数的参数列表来作为菜单选项。

`select` 命令使用 *in word* 参数来指定菜单列表，不同的菜单项之间用空格隔开，不要用双引号把整个菜单列表括起来，否则会被当成一个菜单项。假设有一个 `testselect.sh` 脚本，内容如下：
```bash
#!/bin/bash

select animal in lion tiger panda flower; do
    if [ "$animal" = "flower" ]; then
        echo "Flower is not animal."
        break
    else
        echo "Choose animal is: $animal"
    fi
done

echo "++++ Enter new select ++++"
select animal in "lion tiger panda"; do
    echo "Your choose is: $animal"
    break
done
```
这个脚本的第一个 `select` 命令定义了四个菜单项：*lion*，*tiger*，*panda*，*flower*，如果用户选择了 *flower* 则执行 `break` 命令退出 select 的选择，否则会打印出用户选择的动物名。第二个 `select` 命令用双引号把菜单选项括起来，以便查看加了双引号后的效果。执行该脚本，输出结果如下：
```bash
$ ./testselect.sh
1) lion
2) tiger
3) panda
4) flower
#? 1
Choose animal is: lion
#? 2
Choose animal is: tiger
#? 7
Choose animal is:
#? lion
Choose animal is:
#? 4
Flower is not animal.
++++ Enter new select ++++
1) lion tiger panda
#? 1
Your choose is: lion tiger panda
```
可以看到，`select` 命令要通过菜单项前面的数字来选择对应的项，并把对应项的名称赋值给指定的 *animal* 变量。输入其他内容不会报错，但是会把 *animal* 变量值清空。**选择之后，`select` 命令不会自动退出，而是等待用户继续选择，需要执行 `break` 命令来退出，也可以按 CTRL-D 来输入EOF进行退出**。输入EOF退出后，*animal* 变量值会保持之前的值不变，不会被自动清空。

当用双引号把菜单列表括起来时，整个菜单列表被当成一个选项。如果某个选择项的内容确实要包含空格，就可以单独用双引号把这个选择项的内容括起来，避免该选项该分割成多个选项。

上面的 `#?` 是 bash 的 PS3 提示符，我们可以为 PS3 变量赋值，再执行 `select` 命令，从而打印自定义的提示信息。举例如下：
```bash
$ PS3="Enjoy your choose:> "
$ select animal in lion tiger; do echo "Choose: $animal"; break; done
1) lion
2) tiger
Enjoy your choose:> 1
Choose: lion
```
可以看到，为 PS3 变量赋值后，`select` 命令会打印所赋值的内容，作为提示符。

在 `select` 命令的内部语句里面，可以用 `exit` 命令来直接退出整个脚本的执行，从而退出 `select` 的选择。如果是在函数内调用 `select` 命令，则可以用 `return` 命令来直接退出整个函数，从而退出 `select` 的选择。

我们可以修改 bash 的 IFS 变量值，指定不同菜单项之间的分割字符，但在使用上有一个注意事项，具体说明如下：
```bash
$ IFS=/
$ animal_list="big lion/small tiger"
$ select animal in $animal_list; do echo "Choose: $animal"; break; done
1) big lion
2) small tiger
#? 1
Choose: big lion
$ select animal in big lion/small tiger; do echo "Choose: $animal"; break; done
1) big
2) lion/small
3) tiger
#? 2
Choose: lion/small
```
上面的例子把 IFS 赋值为 `/`，然后定义 *animal_list* 变量，用 `/` 隔开了 *big lion*、*small tiger* 两项，用 `select` 命令从 *animal_list* 变量获取菜单选项时，可以看到不再用空格来隔开选项，而是用 IFS 赋值后的 `/` 来隔开选项。

当 `select` 命令不从 *animal_list* 变量获取菜单选项，而是直接写为 `select animal in big lion/small tiger` 命令时，它还是用空格来隔开选项，而不是用 IFS 赋值后的 `/` 来隔开选项。原因是，IFS 用于 bash 扩展后的单词拆分，使用 `$animal_list` 获取 *animal_list* 变量值就是一种扩展，从而发生单词拆分，用 IFS 的值来拆分成几个单词。直接写为 `in big lion/small tiger` 没有发生扩展，所以没有使用 IFS 来拆分单词。查看 man bash 对 IFS 的说明如下：
> **IFS**
The  Internal  Field  Separator that is used for word splitting after expansion and to split lines into words with the read builtin command.  The default value is ``\<space\>\<tab\>\<newline\>''.

翻译成中文就是，IFS (Internal  Field  Separator) 用于在扩展后进行单词拆分，并使用 read 内置命令将行拆分为单词。

# Bash 的 case 命令详解
Bash 的 case 复合命令 (compound command) 可以在匹配特定的模式时，执行相应的命令。查看 man bash 里面对 case 命令的说明如下：
> **case word in [ [(] pattern [ | pattern ] ... ) list ;; ] ... esac**  
A case command first expands word, and tries to match it against each pattern in turn The word is expanded using tilde expansion, parameter and variable expansion, arithmetic substitution, command substitution, process substitution and quote removal. Each pattern examined is expanded using tilde expansion, parameter and variable expansion, arithmetic substitution, command substitution, and process substitution. When a match is found, the corresponding list is executed. If the ;; operator is used, no subsequent matches are attempted after the first pattern match. Using ;& in place of ;; causes execution to continue with the list associated with the next set of patterns. Using ;;& in place of ;; causes the shell to test the next pattern list in the statement, if any, and execute any associated list on a successful match. The exit status is zero if no pattern matches. Otherwise, it is the exit status of the last command executed in list.

**注意**：`case` 这个关键字是 bash 的内置命令，该命令要求最后一个参数必须是 `esac`，`esac` 关键字自身并不是 bash 的内置命令，它仅仅只是 `case` 命令要求必须提供的一个参数而已。

下面以一个 `testcase.sh` 脚本来举例说明 `case` 命令的详细用法，脚本内容如下：
```bash
#!/bin/bash

var=4
case $1 in
    1) echo "Your input is 1." ;;
    2 | 3 | 4)
        echo "Your input is 2, or 3, or 4."
        ;;&
    $var)
        echo "Sure, your input is 4."
        ;;
    lion)
        echo "Your input is lion."
        ;;
    "big lion")
        echo "Your input is big lion."
        ;&
    "fall through from big lion")
        echo "This is fall through from big lion."
        ;;
    *)
        echo "Your input is not supported."
        ;;
esac
```
执行这个脚本的结果如下：
```bash
$ ./testcase.sh 1
Your input is 1.
$ ./testcase.sh 2
Your input is 2, or 3, or 4.
Your input is not supported.
$ ./testcase.sh 4
Your input is 2, or 3, or 4.
Sure, your input is 4.
$ ./testcase.sh lion
Your input is lion.
$ ./testcase.sh "big lion"
Your input is big lion.
This is fall through from big lion.
$ ./testcase.sh tiger
Your input is not supported.
```
对这个执行结果和脚本的关键点说明如下：
- 在 `case` 命令后面跟着的参数是要匹配的模式，这里用 `$1` 来获取执行脚本时传入的第一个参数。在 `in` 参数跟着可以处理的模式列表，每一项用 `)` 作为结尾。
- 可以用 `2 | 3 | 4)` 这样的形式来匹配多个模式，每个模式用 `|` 隔开。如果写为 `1) | 2) | 3)` 的形式会报错。即，只有最后一个模式才用 `)` 来结尾。
- 模式列表不限于数字，可以是不带引号的字符串、带引号的字符串、bash 的扩展语句、通配符，等等。
- 如果要匹配的字符串带有空格，一定要用引号括起来，否则会报错。
- 上面使用了 `$var` 来匹配 var 变量的值。使用 `*` 通配符来表示匹配任意内容，类似于默认分支语句，这个语句一定要写在最后面，否则会先匹配到它，影响它后面语句的匹配。
- 每个模式处理完之后，一定要用 `;;`、`;&`、或者 `;;&` 来结尾。如果这三个都没有提供则会报错。
- `;;` 表示不再往下匹配，会结束整个 `case` 命令的执行。作用类似于 `select` 命令的 `break` 命令。
- `;&` 表示继续执行下面一个模式里面的语句，不检查下一个模式是否匹配。上面的 `"big lion")` 模式使用了 `;&` 结尾，从执行结果可以看到，它会往下执行 `"fall through from big lion")` 模式的语句。
- `;;&` 表示继续往下匹配，如果找到匹配的模式，则执行该模式里面的语句。上面的 `2 | 3 | 4)` 模式使用了 `;;&` 结尾，当匹配到 2 时，它继续往下匹配，中间没有找到匹配项，一直到 `*)` 才匹配，执行了 `*)` 模式里面的语句。当匹配到 4 时，往下匹配到了 `$var)` 模式，然后 `$var)` 模式里面用 `;;` 结束执行，没有再往下匹配。

在实际应用中，可以把 `case` 命令和 `getopts` 命令结合使用，`getopts` 命令获取执行脚本时传入的选项参数，`case` 命令根据不同的选项参数进行不同的处理。一个简单的示例如下：
```bash
while getopts "bf" arg; do
    case ${arg} in
        b) handle_option_b ;;
        f) handle_option_f ;;
        ?) show_help ;;
    esac
done
```

也可以把 `select` 命令 和 `case` 命令结合使用，`select` 命令获取用户选择的项，`case` 命令根据用户选择的不同项进行不同的处理。这里不再举例。

#  Bash 的 while 和 until 命令详解
Bash 的 while 复合命令 (compound command) 和 until 复合命令都可以用于循环执行指定的语句，直到遇到 false 为止。查看 man bash 里面对 while 和 until 的说明如下：
> **while list-1; do list-2; done**  
**until list-1; do list-2; done**  
The while command continuously executes the list list-2 as long as the last command in the list list-1 returns an exit status of zero. The until command is identical to the while command, except that the test is negated; list-2 is executed as long as the last command in list-1 returns a non-zero exit status. The exit status of the while and until commands is the exit status of the last command executed in list-2, or zero if none was executed.

可以看到，`while` 命令先判断 *list-1* 语句的最后一个命令是否返回为 0，如果为 0，则执行 *list-2* 语句；如果不为 0，就不会执行 *list-2* 语句，并退出整个循环。即，`while` 命令是判断为 0 时执行里面的语句。

跟 `while` 命令的执行条件相反，`until` 命令是判断不为 0 时才执行里面的语句。

**注意**：这里有一个比较反常的关键点，bash 是以 0 作为 true，以 1 作为 false，而大部分编程语言是以 1 作为 true，0 作为 false，要注意区分，避免搞错判断条件的执行关系。

在 bash 中，使用 `test` 命令、`[` 命令来作为判断条件，但是 `while` 命令并不限于使用这两个命令来进行判断，实际上，在 `while` 命令后面可以跟着任意命令，它是基于命令的返回值来进行判断，分别举例如下。

下面的 while 循环类似于C语言的 while (--count >= 0) 语句，使用 `[` 命令来判断 count 变量值是否大于 0，如果大于 0，则执行 while 循环里面的语句：
```bash
count=3
while [ $((--count)) -ge 0 ]; do 
    # do some thing
done
```
下面的 while 循环使用 `read` 命令读取 filename 文件的内容，直到读完为止，`read` 命令在读取到 EOF 时，会返回一个非 0 值，从而退出 while 循环：
```bash
while read fileline; do
    # do some thing
done < filename
```
下面的 while 循环使用 `getopts` 命令处理所有的选项参数，一直处理完、或者报错为止：
```bash
while getopts "rich" arg; do
    # do some thing with $arg
done
```

如果要提前跳出循环，可以使用 `break` 命令。查看 man bash 对 `break` 命令说明如下：
> **break [n]**  
Exit from within a for, while, until, or select loop.  If n is specified, break n levels.  n must be ≥ 1.  If n is greater than the number of enclosing loops, all enclosing loops are exited. The return value is 0 unless n is not greater than or equal to 1.

即，`break` 命令可以跳出 for 循环、while 循环、until 循环、和 select 循环。

# Bash 的 for 命令详解
Bash 的 for 复合命令 (compound command) 可以用于循环执行指定的语句。该命令有两种不同的格式，查看 man bash 里面对 for 命令的说明，分别描述如下。

## for name [ [ in [ word ... ] ] ; ] do list ; done
> **for name [ [ in [ word ... ] ] ; ] do list ; done**  
The list of words following in is expanded, generating a list of items. The variable name is set to each element of this list in turn, and list is executed each time. If the in word is omitted, the for command executes list once for each positional parameter that is set. The return status is the exit status of the last command that executes. If the expansion of the items following in results in an empty list, no commands are executed, and the return status is 0.

这种格式的 `for` 命令先扩展 *word* 列表，得到一个数组，然后把 *name* 变量依次赋值为 *word* 列表的每一个元素，每次赋值都执行 *list* 指定的语句。如果没有提供 *word* 列表，则遍历传入脚本、或者传入函数的参数列表。假设有一个 `testfor_each.sh` 脚本，内容如下：
```bash
#!/bin/bash

for word in This is a sample of "for."; do
    echo -n "$word " | tr a-z A-Z
done
echo

for param; do
    echo -n "$param " | tr A-Z a-z
done
echo
```
这个脚本先使用 `for` 命令遍历 `This is a sample of "for."` 这个字符串的每一个单词，然后打印单词内容，用 `tr` 命令把小写字母转换为大写字母。之后，继续使用 `for` 命令遍历执行脚本时的参数列表，打印参数值，并转换为小写字母。`for param` 语句没有提供 *in word* 参数，默认会遍历传入脚本的 positional parameters。执行 `testfor_each.sh` 脚本，结果如下：
```bash
$ ./testfor_each.sh TEST \"FOR\" COMMAND WITH POSITIONAL PARAMETER
THIS IS A SAMPLE OF FOR.
test "for" command with positional parameter
```
对这个执行结果有个地方需要注意，在 `This is a sample of "for."` 这个字符串中，用双引号把 `for.` 括起来，但是打印出来的结果没有带双引号，这是因为 bash 在解析的时候，会去掉双引号。这里的双引号并不是字符串自身的内容，只是用于限定双引号内部的字符串是一个整体。

如果想要打印出双引号，需要用 `\"` 来进行转义，如上面的 `\"FOR\"`，打印结果包含了双引号。

## for (( expr1 ; expr2 ; expr3 )) ; do list ; done
> **for (( expr1 ; expr2 ; expr3 )) ; do list ; done**  
First, the arithmetic expression expr1 is evaluated according to the rules described below under ARITHMETIC EVALUATION. The arithmetic expression expr2 is then evaluated repeatedly until it evaluates to zero. Each time expr2 evaluates to a non-zero value, list is executed and the arithmetic expression expr3 is evaluated. If any expression is omitted, it behaves as if it evaluates to 1. The return value is the exit status of the last command in list that is executed, or false if any of the expres‐sions is invalid.

**注意**：这种格式的 `for` 命令里面，*expr1*、*expr2*、*expr3* 都是算术表达式，要使用 bash 算术表达式的写法，具体写法可以查看 man bash 里面的 "ARITHMETIC EVALUATION" 小节和 "((expression))" 表达式的说明。

假设有一个 `testfor_expr.sh` 脚本，内容如下：
```bash
#!/bin/bash

declare count
declare count_str
MAX=10

for ((i = 0; i < MAX; ++i)); do
    ((count+=$i))
    count_str+=$i
done
echo "count = $count"
echo "count_str = $count_str"
```
执行该脚本的结果如下：
```bash
$ ./testfor_expr.sh
count = 45
count_str = 0123456789
```
可以看到，要使用 `((count+=$i))` 这种写法才是进行算术运算，*count* 变量值才会像整数一样进行加减。写为 `count_str+=$i` 的形式，其实是进行字符串拼接。

在上面的两个小括号里面引用 *MAX* 变量值时没有加 `$` 符号，这是允许的。当然，写成 `$MAX` 也可以。

如果要提前跳出循环，可以使用 `break` 命令。查看 man bash 对 `break` 命令说明如下：
> **break [n]**  
Exit from within a for, while, until, or select loop.  If n is specified, break n levels.  n must be ≥ 1.  If n is greater than the number of enclosing loops, all enclosing loops are exited. The return value is 0 unless n is not greater than or equal to 1.

即，`break` 命令可以跳出 for 循环、while 循环、until 循环、和 select 循环。
