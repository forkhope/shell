# 记录 bash parameters 的相关笔记

# Bash 的位置参数和部分特殊参数
假设执行 `./test.sh a b c` 这样一个命令，则可以使用下面的参数来获取一些值：
- `$0`  
对应 *./test.sh* 这个值。如果执行的是 `./work/test.sh`， 则对应 *./work/test.sh* 这个值，而不是只返回文件名本身的部分。
- `$1`  
会获取到 a，即 `$1` 对应传给脚本的第一个参数。
- `$2`  
会获取到 b，即 `$2` 对应传给脚本的第二个参数。
- `$3`  
会获取到 c，即 `$3` 对应传给脚本的第三个参数。`$4`、`$5` 等参数的含义依此类推。
- `$#`  
会获取到 3，对应传入脚本的参数个数，统计的参数不包括 `$0`。
- `$@`  
会获取到 "a" "b" "c"，也就是所有参数的列表，不包括 `$0`。
- `$*`  
也会获取到 "a" "b" "c"， 其值和 `$@` 相同。但 `"$*"` 和 `"$@"` 有所不同。  
`"$*"` 把所有参数合并成一个字符串，而 `"$@"` 会得到一个字符串参数数组。
- `$?`  
可以获取到执行 `./test.sh a b c` 命令后的返回值。  
在执行一个前台命令后，可以立即用 `$?` 获取到该命令的返回值。  
该命令可以是系统自身的命令，可以是 shell 脚本，也可以是自定义的 bash 函数。

当执行系统自身的命令时，`$?` 对应这个命令的返回值。  
当执行 shell 脚本时，`$?` 对应该脚本调用 `exit` 命令返回的值。如果没有主动调用 `exit` 命令，默认返回为 0。  
当执行自定义的 bash 函数时，`$?` 对应该函数调用 `return` 命令返回的值。如果没有主动调用 `return` 命令，默认返回为 0。

下面举例说明 `"$*"` 和 `"$@"` 的差异。假设有一个 `testparams.sh` 脚本，内容如下：
```bash
#!/bin/bash

for arg in "$*"; do
    echo "****:" $arg
done
echo --------------
for arg in "$@"; do
    echo "@@@@:" $arg
done
```
这个脚本分别遍历 `"$*"` 和 `"$@"` 扩展后的内容，并打印出来。  

执行 `./testparams.sh` 脚本，结果如下：
```bash
$ ./testparams.sh This is a test
****: This is a test
--------------
@@@@: This
@@@@: is
@@@@: a
@@@@: test
```
可以看到，`"$*"` 只产生一个字符串，for 循环只遍历一次。  
而 `"$@"` 产生了多个字符串，for 循环遍历多次，是一个字符串参数数组。

**注意**：如果传入的参数多于 9 个，则不能使用 `$10` 来引用第 10 个参数，而是要用 `${10}` 来引用。

即，需要用大括号`{}`把大于 9 的数字括起来。  
例如，`${10}` 表示获取第 10 个参数的值，写为 `$10` 获取不到第 10 个参数的值。  
实际上，`$10` 相当于 `${1}0`，也就是先获取 `$1` 的值，后面再跟上 0。  
如果 `$1` 的值是 "first"，则 `$10` 的值是 "first0"。

查看 man bash 里面对位置参数（positional parameters）的说明如下：
> **Positional Parameters**  
> A positional parameter is a parameter denoted by one or more digits, other than the single digit 0.
>
> Positional parameters are assigned from the shell's arguments when it is invoked, and may be reassigned using the set builtin command.  
> Positional parameters may not be assigned to with assignment statements.  
> The positional parameters are temporarily replaced when a shell function is executed.
>
> When a positional parameter consisting of more than a single digit is expanded, it must be enclosed in braces.

即，最后一句提到，当位置参数由多位数字组成时，需要用大括号`{}`把多位数字括起来。

## 获取位置参数的个数
在 bash 中，可以使用 `$#` 来获取传入的命令行或者传入函数的参数个数。  
要注意的是，`$#` 统计的参数个数不包括脚本自身名称或者函数名称。  
例如，执行 `./a.sh a b`，则 `$#` 是 2，而不是 3。

查看 man bash 的说明如下：
> **Special Parameters**  
**\#**      Expands to the number of positional parameters in decimal.

可以看到，`$#` 实际上是扩展为位置参数（positional parameters）的个数，统计的参数不包括 `$0`。

# 使用 getopts 命令解析选项参数
## getopts 命令简介
在 bash shell 上执行命令，常常会用到一些选项参数来指定不同的操作。例如 `ls` 命令的 `-l`、`-a` 选项等。

我们在编写 shell 脚本时，也可以自定义一些选项参数，并使用 bash 的 *getopts* 内置命令来解析选项参数。

查看 man bash 里面对 *getopts* 内置命令的英文说明如下：
> **getopts optstring name [args]**  
> *getopts* is used by shell procedures to parse positional parameters. *optstring* contains the option characters to be recognized; if a character is followed by a colon, the option is expected to have an argument, which should be separated from it by white space.  
> The colon and question mark characters may not be used as option characters.  
> Each time it is invoked, getopts places the next option in the shell variable *name*, initializing *name* if it does not exist, and the index of the next argument to be processed into the variable *OPTIND*.  
> *OPTIND* is initialized to 1 each time the shell or a shell script is invoked.  
> When an option requires an argument, getopts places that argument into the variable *OPTARG*.  
> The shell does not reset *OPTIND* automatically; it must be manually reset between multiple calls to getopts within the same shell invocation if a new set of parameters is to be used.

> When the end of options is encountered, getopts exits with a return value greater than zero.   
> *OPTIND* is set to the index of the first non-option argument, and *name* is set to `?`.

> getopts normally parses the positional parameters, but if more arguments are given in *args*, getopts parses those instead.

> getopts can report errors in two ways. If the first character of *optstring* is a colon, *silent* error reporting is used.  
> In normal operation, diagnostic messages are printed when invalid options or missing option arguments are encountered.  
> If the variable OPTERR is set to 0, no error messages will be displayed, even if the first character of *optstring* is not a colon.

> If an invalid option is seen, getopts places `?` into *name* and, if not silent, prints an error message and unsets *OPTARG*.  
> If getopts is silent, the option character found is placed in *OPTARG* and no diagnostic message is printed.

> If a required argument is not found, and getopts is not silent, a question mark (?) is placed in *name*, *OPTARG* is unset, and a diagnostic message is printed.  
> If getopts is silent, then a colon (:) is placed in *name* and *OPTARG* is set to the option character found.

**注意**：`getopts` 是 bash 的内置命令。对于 bash 内置命令来说，不能用 man 命令查看它们的帮助说明。  
要使用 help 命令查看。也可以在 man bash 里面搜索命令名称查看相应的说明。
```bash
$ man getopts
No manual entry for getopts
$ help getopts
getopts: getopts optstring name [arg]
    Parse option arguments.
```
可以看到，man getopts 提示找不到 getopts 命令的说明，而 help getopts 打印了它的说明。

另外，有一个 `getopt` 外部命令也可以解析命令选项，名称比 `getopts` 少了一个 *s*，用法也有所差异，不要把这两个命令搞混了。

## getopts optstring name [args]
基于 `getopts optstring name [args]` 这个命令格式，对 getopts 命令各个参数的含义说明如下。

`optstring` 参数指定支持的选项参数列表，每个字符对应一个选项。  
如果字符后面跟着冒号 `:`，那么在输入该选项时预期后面跟着一个参数，选项和参数之间用空格隔开。  
不能使用冒号 `:` 和问号 `?` 来作为选项。

例如，一个有效的 optstring 参数值是 "hi:"。  
那么 `-h` 就是一个选项；`-i` 也是一个选项。  
由于在 `i` 后面跟着冒号 `:`，那么输入 `-i` 选项时还要提供一个参数，如 `-i insert` 等。  
如果实际执行的时候，在 `-i` 后面不提供参数，`getopts` 命令会报错。

**注意**：optstring 参数的选项列表不包含 `-` 字符，但是在实际输入选项参数时，getopts 命令要求选项参数以 `-` 开头，否则会报错。  
以上面例子来说，`-h` 是一个选项，但是 `h` 并不是一个有效的选项。

`name` 参数用于保存解析后的选项名。  
每调用一次 getopts 命令，它只解析一个选项，并把解析的值存入 *name* 变量中。  
解析后的值不包含 `-` 字符。  
例如解析 `-h` 选项后，*name* 变量的值是字符 h。  
该变量的名称不要求只能是 *name* 字符串，也可以是其他合法的变量名，例如 *opt*、*arg* 等等。

如果要解析多个选项时，需要在 while 或者 for 循环中多次执行 getopts 命令，来逐个解析参数选项，直到解析完毕为止。  
解析完毕，`getopts` 命令会返回 false，从而退出循环。

如果提供的选项不在 optstring 指定的列表里面，*name* 的值会被设成问号 `?`。  
但是 `getopts` 命令还是返回true，不会报错。

`[args]` 是一个可选参数，用于指定选项参数的来源。  
`getopts` 命令默认解析位置参数提供的参数，例如 `$1`、`$2`、...、等等。  
如果提供了 *args* 参数，那么从 *args* 中解析选项参数，不再从位置参数中解析。

也就是说，在 shell 脚本里面直接执行 `getopts` 命令，它默认解析的选项参数是执行脚本时提供的参数。  
例如有一个 `testgetopts.sh` 脚本，那么执行 `./testgetopts.sh -a -b` 命令，`getopts` 会解析 `-a`、`-b` 选项。

如果是在函数内执行 `getopts` 命令，它解析的选项参数是调用函数时提供的参数。  
例如有一个 *test_getopts* 函数，该函数内调用 `getopts` 命令，那么执行 `test_getopts -a -b` 语句，`getopts` 命令会解析 `-a`、`-b` 选项。  

如果提供了 *args* 参数，`getopts` 命令改成解析 *args* 参数包含的选项。  
例如执行 `args="-a -b"; getopts "ab" opt $args` 语句，`getopts` 命令解析的是 *args* 变量指定的 "-a -b" 字符串。

`OPTARG`  是 `getopts` 命令用到的一个全局变量，保存解析出来的带冒号选项后面的参数值。  
例如解析上面提到的 `-i insert` 选项，那么 OPTARG 的值就是 *insert*。

`OPTIND`  是 `getopts` 命令用到的一个全局变量，保存下一个待解析的参数index。  
当启动新的shell时，OPTIND 的默认值是 1，调用一次 `getopts` 命令，OPTIND 的值加 1。  
如果带冒号的选项后面提供了参数，OPTIND 的值会加 2。  
当 `getopts` 命令解析完所有参数后，shell 不会自动重置 OPTIND 为 1。  

如果在同一个 shell 脚本里面要解析不同的选项参数，需要手动为 OPTIND 赋值为 1，否则会解析到不预期的选项。  
后面会以一个 `testgetopts.sh` 脚本为例进行说明。

## getopts 命令的返回值
查看 man bash 里面对 getopts 命令的返回值说明如下：
> getopts returns true if an option, specified or unspecified, is found.  
> It returns false if the end of options is encountered or an error occurs.

可以看到，**即使提供不支持的选项，getopts 命令也是返回true**。

当解析完所有选项后，getopts 会返回 false，遇到错误时也会返回 false。  
遇到错误的情况有如下几种：
- 选项没有以 `-` 开头
- 带有冒号的选项要求后面提供一个参数，但是没有提供该参数

## `testgetopts.sh` 脚本
下面以一个 `testgetopts.sh` 脚本为例来说明 getopts 命令的用法，其内容如下：
```bash
#!/bin/bash

function test_getopts_ab()
{
    local opt_ab
    while getopts "ab" opt_ab; do
        echo $FUNCNAME: $OPTIND: $opt_ab
    done
}

echo Before Call test_getopts_ab: OPTIND: $OPTIND ++
test_getopts_ab "-a" "-b"
echo After Call test_getopts_ab: OPTIND: $OPTIND --

while getopts "ef" opt_ef; do
    echo $OPTIND: $opt_ef
done

OPTIND=1
echo Reset OPTIND to: $OPTIND

number=6;
while getopts "s:g" opt_sg; do
    case $opt_sg in
        g) echo $number ;;
        s) number=$OPTARG ;;
        ?) echo "unknown option: $opt_sg" ;;
    esac
done
```
这个脚本先在 *test_getopts_ab* 函数中调用 getopts 命令，解析传入的 `"-a" "-b"` 选项。  
然后调用 getopts 命令解析执行脚本时传入的命令行选项参数。  
最后重置 OPTIND 的值，重新解析命令行选项参数。

以 `getopts "ab" opt_ab` 语句来说，"ab" 对应上面提到的 *optstring* 参数，它支持的选项就是 `-a`、`-b`。  
opt_ab 对应上面提到的 *name* 变量名，保存解析得到的选项，不包含 `-` 字符。

执行这个脚本，结果如下：
```bash
$ ./testgetopts.sh -s 7 -g -f
Before Call test_getopts_ab: OPTIND: 1 ++
test_getopts_ab: 2: a
test_getopts_ab: 3: b
After Call test_getopts_ab: OPTIND: 3 --
./testgetopts.sh: illegal option -- g
4: ?
5: f
Set OPTIND to: 1
7
./testgetopts.sh: illegal option -- f
unknown option: ?
```
可以看到，*test_getopts_ab* 函数解析完选项参数后，在函数外打印 OPTIND 的值是 3。  
之后再次调用 `getopts` 命令，OPTIND 值没有从 1 开始，还是从 3 开始取值，取到了传给 `testgetopts.sh` 的第三个参数 `-g`，跳过了前面的 `-s 7` 两个参数。  
这并不是预期的结果。正常来说，预期是从第一个选项参数开始解析。  
由于 `getopts "ef" opt_ef` 语句不支持 `-g` 选项，打印报错信息，并把 opt_ef 赋值为问号 `?`。

手动将 OPTIND 值重置为 1 后，`getopts "s:g" opt_sg` 可以从第一个选项参数开始解析。  
先处理 `-s 7` 选项，`getopts` 把 7 赋值给 OPTARG，脚本里面再把 OPTARG 的值赋给 number 变量。  
然后继续处理 `-g` 选项，打印出 number 变量的值。  
最后处理 `-f` 选项，该选项不支持，opt_sg 的值被设成问号 `?`，打印 "unknown option" 的信息。  
处理完所有选项后，getopts 返回 false，退出 while 循环。

## 错误判断
`getopts` 命令处理完选项参数、或者遇到错误时，都会返回 false，不能通过判断返回值来确认是否遇到了错误。

当在 while 或者 for 循环中调用 getopts 时，可以通过 OPTIND 的值来判断 getopts 是否遇到了错误。  
如果 OPTIND 的值减去 1 后，不等于传入的参数个数，那么就是遇到了错误导致提前退出循环。

当 getopts 处理选项参数时，OPTIND 的值从 1 开始递增。  
处理所有参数后，OPTIND 指向最后一个参数，相当于是所有参数个数加 1。  
所以 OPTIND 的值减去 1 就应该等于传入的参数个数。

Bash 的 `$#` 表达式可以获取传入的参数个数，如果这两个值不相等，那么 getopts 就没有解析完选项参数，也就是遇到了错误导致提前退出循环。

假设有一个 `test.sh` 脚本，内容如下：
```bash
#!/bin/bash

while getopts "abcd" arg; do
    echo $OPTIND: $arg
done

echo OPTIND: $OPTIND. \$\#: $#
if [ "$(($OPTIND - 1))" != "$#" ]; then
    echo Error occurs.
fi
```
传入不同的选项参数，执行该脚本的结果如下：
```bash
$ ./test.sh -a -b -c
2: a
3: b
4: c
OPTIND: 4. $#: 3
$ ./test.sh -a -b
2: a
3: b
OPTIND: 3. $#: 2
$ ./test.sh -a b
2: a
OPTIND: 2. $#: 2
Error occurs.
```
可以看到，当正常遇到选项末尾时，OPTIND 变量的值是选项个数加 1。  
当遇到错误时，OPTIND 变量的值不是选项个数加 1。  
所以当 OPTIND 变量的值减去1，不等于 `$#` 时，就表示遇到了错误。

## 通过 source 多次执行脚本对 OPTIND 的影响
通过 source 命令调用脚本是运行在当前 shell 下，由于 shell 不会自动重置 OPTIND 的值，如果要调用的脚本使用了 `getopts` 命令解析选项参数，在每次调用 getopts 之前，一定要手动重置 OPTIND 为 1，否则 OPTIND 的值不是从 1 开始递增，会获取到不预期的选项参数值。

假设有一个 `test.sh` 脚本，其内容如下：
```bash
#!/bin/bash

echo \$\#: $#, \$\@: $@, OPTIND: $OPTIND
getopts "abc" opt
echo $?, $opt
```
分别不使用 source 命令和使用 source 命令执行该脚本，结果如下：
```bash
$ ./test.sh -a
$#: 1, $@: -a, OPTIND: 1
0, a
$ ./test.sh -b
$#: 1, $@: -b, OPTIND: 1
0, b
$ source ./test.sh -a
$#: 1, $@: -a, OPTIND: 1
0, a
$ source ./test.sh -b
$#: 1, $@: -b, OPTIND: 2
1, ?
```
可以看到，执行 `./test.sh -a` 命令和 `./test.sh -b` 命令的输出结果都正常。  
执行 `source ./test.sh -a` 命令的结果也是正常。  
但是接着执行 `source ./test.sh -b` 命令，调用 getopts 之前，打印出 OPTIND 的值是 2，要获取第二个选项参数。  
由于没有提供第二个选项参数，获取到的选项参数值是问号 `?`，用 `$?` 获取 getopts 命令的返回值是 1，执行报错。

即，如果一个脚本使用了 getopts 命令，而该脚本又要用 source 命令来执行时，脚本需要手动设置 OPTIND 变量的值为1，否则会遇到上面的异常。

当我们自己写了一个脚本，并在 `.bashrc` 文件中配置 alias 使用 source 命令来执行该脚本，例如下面的设置：
```bash
alias c='source quickcd.sh'
```
当 `quickcd.sh` 脚本使用了 `getopts` 命令，且没有重置 OPTIND 的值，那么多次执行 c 这个命令，就会遇到上面描述的异常。

# 用 $ 获取变量值是否要加双引号
在 bash shell 脚本中，用 $ 来获取变量值时，有一些不加双引号，例如 `$arg`。有一些会加双引号，例如 `"$arg"`。  
下面具体说明这两种形式之间的区别，什么情况下要加双引号，什么情况可以不加双引号。

在 bash 中，各个参数之间默认用隔开。  
当参数值本身就带有空格时，如果不加双引号把参数值括起来，那么这个参数值可能会被扩展为多个参数值，而丢失原本的完整值。  
具体举例说明如下：
```bash
$ function test_args() { echo \$\#: $#; echo first: $1; echo second: $2; }
$ args="This is a Test"
$ test_args $args
$#: 4
first: This
second: is
$ test_args "$args"
$#: 1
first: This is a Test
second:
```
这里定义了一个 *test_args* 函数，打印传入的 `$1`、`$2` 参数值。  
所给的 *args* 变量指定的字符串含有空格。

可以看到，当执行 `test_args $args` 时，args 变量的值被空格隔开成四个参数。  
而执行 `test_args "$args"` 时，args 变量的值保持不变，被当成一个参数。  
使用双引号把字符串括起来，可以避免空格导致单词拆分。

**即，当我们需要保持变量本身值的完整，不想被空格扩展为多个参数，那么就需要用双引号括起来**。

在给脚本或函数传递参数时，我们可能不确定获取到的参数值是否带有空格。  
为了避免带有空格导致不预期的单词拆分，造成参数个数发生变化，建议传参时每个参数都使用双引号括起来。

# 用 $ 获取变量值是否要加大括号
在 bash shell 脚本中，用 $ 来获取变量值时，有一些不加大括号，例如 `$var`。有一些会加大括号，例如 `${var}`。  
下面具体说明这两种形式之间的区别，什么情况下要加大括号，什么情况可以不加大括号。

查看 man bash 里面对 `${parameter}` 表达式的含义说明如下：
> **${parameter}**  
> The value of parameter is substituted.  
> The braces are required when parameter is a positional parameter with more than one digit, or when parameter is followed by a character which is not to be interpreted as part of its name.  
> The parameter is a shell parameter or an array reference (Arrays).

即，大括号 `{}` 的作用是限定大括号里面的字符串是一个整体，不会跟相邻的字符组合成其他含义。

例如，有一个 var 变量值是 "Say"，现在想打印这个变量值，并跟着打印 "Hello" 字符串，也就是打印出来 "SayHello" 字符串。  
那么获取 var 变量值的语句和 "Hello" 字符串中间就不能有空格，否则 *echo* 命令会把这个空格一起打印出来。  
但是写为 `$varHello` 达不到想要的效果。  
具体举例如下：
```bash
$ var="Say"
$ echo $var Hello
Say Hello
$ echo $varHello

$ echo ${var}Hello
SayHello
$ echo "$var"Hello
SayHello
```
可以看到，`$var Hello` 这种写法打印出来的 "Say" 和 "Hello" 中间有空格，不是想要的结果。  
而 `$varHello` 打印为空，这其实是获取 varHello 变量的值，这个变量没有定义过，默认值是空。  
`${var}Hello` 打印出了想要的结果，用 `{}` 把 var 括起来，明确指定要获取的变量名是 var，避免混淆。  
`"$var"Hello` 用双引号把 `$var` 括起来，也可以跟后面的 "Hello" 字符串区分开。

即，当用 $ 获取变量值时，如果变量名后面跟着空白字符，隔开了其他内容，可以不用大括号来把变量名括起来。

**如果变量名后面直接跟着不属于变量名自身的其他字符，就需要用大括号把变量名括起来，以便明确该变量的名称**。

# 用 bash 的参数扩展操作字符串
在 bash 中，通常使用 `${parameter}` 表达式来获取 *parameter* 变量的值，这是一种参数扩展 (parameter expansion)。  
Bash 还提供了其他形式的参数扩展，可以对变量值做一些处理，起到操作字符串的效果。例如：
- `${parameter:offset:length}` 从 *parameter* 变量值的第 *offset* 个字符开始，获取 *length* 个字符，得到子字符串。
- `${#parameter}` 获取 *parameter* 变量值的字符串长度。
- `${parameter#word}` 从 *parameter* 变量值的开头往后删除匹配 *word* 的部分，保留后面剩余内容。
- `${parameter%word}` 从 *parameter* 变量值的末尾往前删除匹配 *word* 的部分，保留前面剩余内容。
- `${parameter^^pattern}` 把 *parameter* 变量值中匹配 *pattern* 模式字符的小写字母转成大写。
- `${parameter,,pattern}` 把 *parameter* 变量值中匹配 *pattern* 模式字符的大写字母转成小写。
- `${parameter/pattern/string}` 把 *parameter* 变量值中匹配 *pattern* 模式的部分替换为 *string* 字符串。

**注意**：这些表达式都不会修改 *parameter* 自身的变量值，它们只是基于 *parameter* 变量值扩展得到新的值。  
如果要保存这些值，需要赋值给具体的变量。

查看 man bash 的 *Parameter Expansion* 小节，就能看到相关说明。具体举例说明如下。

## ${parameter:offset} 和 ${parameter:offset:length}
查看 man bash 对 `${parameter:offset}` 和 `${parameter:offset:length}` 的说明如下：
> Substring Expansion. Expands to up to length characters of the value of parameter starting at the character specified by offset.   
> If parameter is @, an indexed array subscripted by @ or *, or an associative array name, the results differ as described below.  
> If length is omitted, expands to the substring of the value of parameter starting at the character specified by offset and extending to the end of the value.  length and offset are arithmetic expressions.  
> If offset evaluates to a number less than zero, the value is used as an offset in characters from the end of the value of parameter.  
> If length evaluates to a number less than zero, it is interpreted as an offset in characters from the end of the value of parameter rather than a number of characters, and the expansion is the characters between offset and that result.  
> Note that a negative offset must be separated from the colon by at least one space to avoid being confused with the :- expansion.

即，`${parameter:offset:length}` 表达式从 *parameter* 变量值的第 *offset* 个字符开始，一直获取 *length* 个字符，得到一个子字符串，会包括第 *offset* 个字符自身。

`${parameter:offset}` 表达式省略了 *length* 参数，会从 *parameter* 变量值的第 *offset* 个字符开始一直获取到末尾。

这里的 *length* 和 *offset* 可以是算术表达式。  
字符串的 *offset* 从 0 开始。

如果 *offset* 的数值小于 0，那么这个值被用作 *parameter* 变量值的末尾偏移，从后往前获取字符。  
如果 *length* 数值小于 0，它会被当成 *parameter* 变量值的末尾偏移，而不是当作总的字符数目，且扩展后的结果是在这两个偏移之间的字符。

**注意**：一个负数的偏移量必须用至少一个空格和冒号分割开，以避免和 `:-` 扩展产生混淆。  
即，这种情况下的冒号 `:` 和 负号 `-` 之间至少要有一个空格，类似于 `: -` 的形式。

具体举例说明如下：
```bash
$ value="This is a test string."
$ echo ${value:5}
is a test string.
$ echo ${value:5:2}
is
$ echo ${value:5: -4}
is a test str
$ echo ${value: -7:3}
str
$ echo ${value: -7: -1}
string
```
可以看到，`${value:5}` 获取从 *value* 变量值的第 5 个字符开始，一直到末尾的全部字符。  
注意偏移量是从 0 开始，获取到的子字符串包括第 5 个字符自身。

`${value:5:2}` 从 *value* 变量值的第 5 个字符开始，获取包括该字符在内的两个字符，也就是 "is" 字符串。

当所给的 *length* 参数值为负数时，负号和冒号之间要用空格隔开。  
此时 *length* 参数不表示要获取的字符个数，而是表示对应 *parameter* 变量值从后往前的偏移，而且这个偏移是从 1 开始。  
`${value:5: -4}` 表示从 *value* 变量值的第 5 个字符开始，一直获取到倒数第 4 个字符为止，不包括倒数第 4 个字符。

当所给的 *offset* 参数值为负数时，负号和冒号之间要用空格隔开。  
此时 *offset* 参数对应 *parameter* 变量值从后往前的偏移，而且这个偏移是从 1 开始。  
`${value: -7:3}` 表示从 *value* 变量值的倒数第 7 个字符串开始，获取包括该字符在内的三个字符，也就是 "str" 字符串。

`${value: -7: -1}` 表示从 *value* 变量值的倒数第 7 个字符串开始，一直获取到倒数第 1 个字符为止。  
包括倒数第 7 个字符，不包括倒数第 1 个字符。  
具体得到的是 "string" 字符串，不包含最后的点号 `.`。

## ${#parameter}
查看 man bash 对 `${#parameter}` 的说明如下：
> Parameter length. The length in characters of the value of parameter is substituted.  
> If parameter is * or @, the value substituted is the number of positional parameters.  
> If parameter is an array name subscripted by * or @, the value substituted is the number of elements in the array.

即，如果 *parameter* 变量值是字符串，则 `${#parameter}` 可以获取到对应字符串的长度。

具体举例说明如下：
```bash
$ value="123456"
$ echo ${#value}
6
```

**注意**：在 bash 的参数扩展中，数字属于位置参数（positional parameters），可以用数字来引用传入脚本或者函数的参数。  
当用在当前表达式时，就表示获取所传参数的字符串长度。  
例如 `$1` 对应传入的第一个参数，那么 `${#1}` 对应所传入第一个参数的字符串长度。  
具体举例如下：
```bash
$ function param_length() { echo ${#1}; }
$ param_length 123456
6
```
可以看到，*param_length* 函数使用 `${#1}` 获取到所给第一个参数值的长度。

## ${parameter#word} 和 ${parameter##word}
查看 man bash 对 `${parameter#word}` 和 `${parameter##word}` 的说明如下：
> Romove matching prefix pattern.  
> The work is expanded to produce a pattern just as in pathname expansion. If the pattern matches the beginning of the value of parameter, then the result of the expansion is the expanded value of parameter with the shortest matching pattern (the '#' case) or the longest matching pattern (the '##' case) deleted.  
> If parameter is @ or *, the pattern removal operation is applied to each positional parameter in turn, and the expansion is the resultant list.  
> If parameter is an array variable subscripted with @ or *, the pattern removal operation is applied to each member of the array in turn, and the expansion is the resultant list.

即，`${parameter#word}` 在 *parameter* 变量值中，从头开始匹配 *word* 模式对应的内容。  
如果匹配，则删除最短匹配部分并返回变量剩余部分内容。  
后面会具体举例说明，方便理解。

而 `${parameter##word}` 是在 *parameter* 变量值中，从头开始匹配 *word* 模式对应的内容。  
如果匹配，则删除最长匹配部分并返回变量剩余部分内容。

上面所说的 "最短匹配"、"最长匹配" 主要是针对有多个匹配的情况。  
如果 *parameter* 变量值中有多个地方匹配 *word* 模式，则 "最短匹配" 是指在第一次匹配时就停止匹配，并返回剩余的内容。  
而 "最长匹配" 会一直匹配到最后一次匹配为止，才返回剩余的内容。

这里的 *word* 模式可以使用通配符进行扩展，注意不是用正则表达式。

**注意**：上面所说的 “从头开始匹配” 是指把 *parameter* 变量值跟 *word* 模式从头开始比较，而不是在 *parameter* 变量值中任意匹配 *word* 模式。

具体举例说明如下：
```bash
$ value="This/is/a/test/string"
$ echo ${value#This}
/is/a/test/string
$ echo ${value#test}
This/is/a/test/string
$ echo ${value#*test}
/string
```
上面先定义了一个 *value* 变量，然后获取 `${value#This}` 的值。  
这个参数扩展表示在 *value* 变量值中从头开始匹配 "This" 字符串。  
如果匹配，则删除 "This" 字符串，返回 *value* 变量值剩余部分内容。  
这里能够匹配，所以去掉了 "This" 字符串，打印 "/is/a/test/string"。

但是 `echo ${value#test}` 的打印结果跟 *value* 变量值完全一样。  
即没有匹配到中间的 "test" 字符串，最短匹配为空，没有删除任何字符串。

使用 `${value#*test}` 才能匹配到 *value* 变量值中间的 "test" 字符串，并删除所有匹配的内容，打印 "/string"。  
这里用 `*` 通配符匹配在 "test" 前面的任意字符，从而匹配 *value* 变量值开头的部分。

**注意**：`${parameter##word}` 是操作 *parameter* 变量值，而不是操作 "parameter" 字符串。  
所以想要过滤某个字符串的内容，需要先把字符串赋值给某个变量，再用变量名来进行参数扩展。  
直接把字符串内容写在大括号 `{}` 里面不起作用，即使用引号把字符串括起来也不行。

具体举例说明如下：
```bash
$ echo ${This/is/a/test/string#This}    # 执行不会报错，但是输出为空

$ echo ${"This/is/a/test/string"#This}  # 添加引号会执行报错
-bash: ${"This/is/a/test/string"#This}: bad substitution
$ echo ${'This/is/a/test/string'#This}
-bash: ${'This/is/a/test/string'#This}: bad substitution
```
可以看到，这里的四个表达式都不能直接处理字符串自身的内容。

`${parameter##word}` 的用法跟 `${parameter#word}` 类似，也是删除匹配的内容，返回剩余的内容。  
区别在于，`${parameter#word}` 是匹配到第一个就停止。  
而 `${parameter##word}` 是匹配到最后一个才停止。

以上面的 *value* 变量为例，具体说明如下：
```bash
$ echo ${value#*is}
/is/a/test/string
$ echo ${value##*is}
/a/test/string
```
可以看到，`echo ${value##*is}` 打印的是 "/is/a/test/string"。  
所给的 `*is` 匹配到 "This" 这个字符串，没有再匹配后面的 "is" 字符串，所以只删除了 "This" 字符串。

而 `echo ${value##*is}` 打印的是 "/a/test/string"。  
它先匹配到 "This"，但还是继续往后匹配，最后一个匹配是 "is" 字符串，所以删掉了 "This/is" 字符串。

**再次强调**，上面说的 "匹配" 是从头开始匹配，而不是部分匹配。  
它是要求 *word* 模式扩展之后得到的字符串从头开始符合 *parameter* 变量值的内容，而不是在 *parameter* 变量值里面查找 *word* 模式。

例如下面的例子：
```bash
$ value="This/is/a/test/string./This/is/a/new/test"
$ echo ${value##*This}
/is/a/new/test.
$ echo ${value##This}
/is/a/test/string./This/is/a/new/test
```
可以看到，*value* 变量值有两个 "This" 字符串。  
`echo ${value##*This}` 匹配到了最后一个 "This" 字符串。  
但是 `echo ${value##This}` 还是只匹配到开头的 "This" 字符串。  
它不是在 *value* 变量值里面查找 "This" 这个子字符串，而是把 "This" 字符串和 *value* 变量值从头开始、逐个字符进行匹配。

而在 `echo ${value##*This}` 表达式中，`*This` 经过通配符扩展后，在 *value* 变量值中有几种形式的匹配。  
例如从头匹配到 "This" 字符串、匹配到 "This/is/a/test/string./This" 字符串。  
去掉最长匹配后，打印为 "/is/a/new/test."。  
注意体会其中的区别。

**注意**：在 bash 的参数扩展中，数字属于 *positional parameters*，可以用数字来引用传入脚本或者函数的参数。  
用在当前表达式时，就表示对传入的参数值进行处理。  
例如 `$1` 对应传入的第一个参数，那么 `${1##pattern}` 表示在传入第一个参数值中匹配 *pattern* 模式，并进行处理。

具体举例如下：
```bash
$ function param_tail() { echo ${1##*test}; }
$ param_tail "This is a test string."
string.
```
可以看到，*param_tail* 函数使用 `${1##*test}` 在传入的第一个参数中匹配 "test" 字符串、以及它前面的任意字符。  
如果能够匹配，去掉匹配的内容，只保留后面的部分。

如果所给的 *parameter* 是一个数组变量且所给下标是 `@` 或者 `*`，那么会对每一个数组元素都进行匹配删除操作，最后得到的扩展结果是合成后的列表。  
当需要对多个字符串进行相同处理时，就可以把它们放到一个数组里面，然后使用这两个表达式来进行处理。

**下面的例子从多个文件路径中过滤出各自的文件名，去掉了目录路径部分**：
```bash
$ arrays=("src/lib/utils.c" "src/main/main.c" "include/lib/utils.h")
$ echo ${arrays[@]##*/}
utils.c main.c utils.h
```
可以看到，`${arrays[@]##*/}` 表达式使用 `arrays[@]` 来指定操作 *arrays* 数组的每一个元素。  
用 `*/` 来匹配目录路径的 `/` 字符，且在该字符前面可以有任意多的其他字符。  
用 `##` 指定进行最长匹配，从而会匹配到最后一个 `/` 字符为止。  
最终，该表达式删除匹配的部分，返回剩余的内容，也就是返回文件名自身。

## ${parameter%word} 和 ${parameter%%word}
查看 man bash 对 `${parameter%word}` 和 `${parameter%%word}` 的说明如下：
> Remove matching suffix pattern.  
> The word is expanded to produce a pattern just as in pathname expansion. If the pattern matches a trailing portion of the expanded value of parameter, then the result of the expansion is the expanded value of parameter with the shortest matching pattern (the '%' case) or the longest matching pattern (the '%%' case) deleted.  
> If parameter is @ or *, the pattern removal operation is applied to each positional parameter in turn, and the expansion is the resultant list.  
> If parameter is an array variable subscripted with @ or *, the pattern removal operation is applied to each member of the array in turn, and the expansion is the resultant list.

即，`${parameter%word}` 匹配 *parameter* 变量值的后缀部分，从后往前匹配 *word* 模式对应的内容。  
如果匹配，则删除最短匹配部分并返回变量剩余部分内容。  
所谓的 "最短匹配" 是指从 *parameter* 变量值的末尾开始，从后往前匹配，一匹配到就结束匹配。  
后面会举例说明，方便理解。

而 `${parameter%%word}` 匹配 *parameter* 变量值的后缀部分，从后往前匹配 *word* 模式对应的内容。  
如果匹配，则删除最长匹配部分并返回变量剩余部分内容。  
所谓的 "最长匹配" 是指从 *parameter* 变量值的末尾开始，从后往前匹配，一直匹配到最后一次匹配为止。

这里的 *word* 模式可以使用通配符进行扩展，注意不是用正则表达式。

前面说明的 `${parameter#word}` 是从变量值中删除匹配的前缀部分，保留后面剩余的内容。  
而 `${parameter%word}` 相反，是从变量值中删除匹配的后缀部分，保留后面剩余的内容。

具体举例说明如下：
```bash
$ value="This/is/a/test/string./This/is/a/new/test"
$ echo ${value%test}
This/is/a/test/string./This/is/a/new/
$ echo ${value%%test}
This/is/a/test/string./This/is/a/new/
$ echo ${value%%test*}
This/is/a/
$ echo ${value%is*}
This/is/a/test/string./This/
$ echo ${value#*is}
/is/a/test/string./This/is/a/new/test
```
可以看到，`${value%test}` 在 *value* 变量值中，从后往前匹配到 "test" 字符串，删除匹配的内容，获取到前面剩余的部分。  
而 `${value%%test}` 获取到的值跟 `${value%test}` 一样。  
因为该表达式是从末尾开始逐字匹配，所以不会往前匹配到第二个 "test" 字符串，只匹配了末尾的 "test" 字符串。

如果要往前匹配到第二个 "test" 字符串，可以使用 `*` 通配符。  
`${value%%test*}` 表示从后往前匹配，直到最后一个 "test" 模式才停止。

由于 `${parameter%word}` 表达式是从后往前匹配，所以 `*` 通配符要写在 *word* 模式的后面，才能匹配到中间的内容。  
如 `${value%is*}` 的输出结果所示。  
而 `${parameter#word}` 是从前往后匹配，所以 `*` 通配符要写在 *word* 模式的前面，才能匹配到中间的内容。  
如 `${value#*is}` 的输出结果所示。

## ${parameter^pattern}, ${parameter^^pattern}, ${parameter,pattern}, ${parameter,,pattern}
查看 man bash 对 `${parameter^pattern}, ${parameter^^pattern}, ${parameter,pattern}, ${parameter,,pattern}` 的说明如下：
> Case modification.  
> This expansion modifies the case of alphabetic characters in parameter. The pattern is expanded to produce a pattern just as in pathname expansion.  
> The ^ operator converts lowercase letters matching pattern to uppercase; the , operator converts matching uppercase letters to lowercase.  
> The ^^ and ,, expansions convert each matched character in the expanded value; the ^ and , expansions match and convert only the first character in the expanded value.  
> If pattern is omitted, it is treated like a ?, which matches every character.  
> If parameter is @ or *, the case modification operation is applied to each positional parameter in turn, and the expansion is the resultant list.  
> If parameter is an array variable subscripted with @ or *, the case modification operation is applied to each member of the array in turn, and the expansion is the resultant list.

即，这四个表达式会在 *parameter* 变量值中匹配 *pattern* 模式，并对匹配的字符进行大小写转换：
- `^` 操作符把小写字母转换为大写，且只转换开头的第一个字符
- `,` 操作符把大写字母转换为小写，且只转换开头的第一个字符
- `^^` 操作符把小写字母转换为大写，会转换每一个匹配的字符
- `,,` 操作符把大写字母转换为小写，会转换每一个匹配的字符

这里的 *pattern* 模式可以使用通配符进行扩展，注意不是用正则表达式。

**注意**：`^` 和 `,` 不是转换第一个匹配到的字符，而是只转换 *parameter* 变量值的首字符。  
所给的 *pattern* 模式必须和 *parameter* 变量值的首字符匹配才会转换，不会转换字符串中间的字符。

具体举例说明如下：
```bash
$ value="This Is a Test String."
$ echo ${value^t}
This Is a Test String.
$ echo ${value^^t}
This Is a TesT STring.
$ echo ${value,T}
this Is a Test String.
$ echo ${value,,T}
this Is a test String.
```
可以看到，使用 `${value^t}` 不会把 *value* 变量值中间小写的 `t` 字符换行为大写。  
因为这个表达式只匹配和转换 *value* 变量值的首字符，*value* 变量值并不是以小写字母 `t` 开头，不做转换。

而 `${value^^t}` 表达式会匹配 *value* 变量值中的每一个小写字母 `t`，并转换为大写。  
所以输出结果里面不再有小写的 `t` 字符。

类似的，`${value,T}` 表示把 *value* 变量值开头的大写 `T` 转换为小写的 `t`。  
`${value,,T}` 表示把 *value* 变量值所有的大写 `T` 转换为小写的 `t`。

如果省略 *pattern* 模式，则表示匹配任意字符，但并不表示会转换所有字符，`^` 和 `,` 操作符还是只转换首字符。

以上面的 *value* 变量值举例如下：
```bash
$ echo ${value^}
This Is a Test String.
$ echo ${value^^}
THIS IS A TEST STRING.
$ echo ${value,}
this Is a Test String.
$ echo ${value,,}
this is a test string.
```
可以看到，`${value^}` 只会把 *value* 变量值首字符变成大写，由于原本就是大写，所以输出结果跟 *value* 值一样。  
`${value^^}` 把所有字符都转换为大写。  
`${value,}` 把 *value* 变量值首字符变成小写。  
`${value,,}` 把所有字符都转换为小写。

**注意**：如果要匹配多个字符，要用方括号 `[]` 把字符串括起来，进行 pathname expansion，才会得到多个可匹配的字符。  
直接把 *pattern* 模式写成字符串并不能匹配该字符串中的每一个字符。

以上面的 *value* 变量值举例如下：
```bash
$ echo ${value,TI}
This Is a Test String.
$ echo ${value,,TI}
This Is a Test String.
$ echo ${value,,[TI]}
this is a test String.
$ echo ${value,[TI]}
this Is a Test String.
```
可以看到，当所给模式写为 `TI` 时，无论是使用 `,` 还是 `,,` ，都不能把大写的 `T` 和 `I` 转换为小写。  
`${value,TI}` 甚至都不能转换开头的 `T` 字符。

而写为 `${value,,[TI]}` 就会把所有大写的 `T` 和 `I` 都转换为小写。  
`[TI]` 就是 pathname expansion 的一种写法，表示匹配方括号 `[]` 里面的每一个字符。  
基于字符匹配，不是基于字符串匹配。  
写为 `${value,[TI]}` 表示把首字符 `T` 或者首字符 `I` 转换为小写，只匹配首字符。

关于 pathname expansion 的具体写法可以查看 man bash 的 *Pathname Expansion* 部分。

最常见的就是用 `*` 通配符匹配零个或多个任意字符，用 `?` 匹配任意单个字符。  
上面说明中提到，如果省略 *pattern* 模式，就相当于写为 `?`。  
即 `${parameter^^}` 等价于 `${parameter^^?}`。

## ${parameter/pattern/string}
查看 man bash 对 `${parameter/pattern/string}` 的说明如下：
> Pattern substitution.  
> The pattern is expanded to produce a pattern just as in pathname expansion. Parameter is expanded and the longest match of pattern against its value is replaced with string.  
> If pattern  begins with  /, all matches of pattern are replaced with string. Normally only the first match is replaced. If pattern begins with #, it must match at the beginning of the expanded value of parameter.  
> If pattern begins with %, it must match at the end of the expanded value of parameter.  
> If string is null, matches of pattern are deleted and the / following pattern may be omitted.  
> If parameter is @ or *, the substitution operation is applied to each positional parameter in turn, and the expansion is the resultant list.  
> If parameter is an array variable subscripted with @ or *, the substitution operation is applied to each member of the array in turn, and the expansion is the resultant list.

即，`${parameter/pattern/string}` 表达式可以替换 *parameter* 变量值的字符串。  
所给的 *pattern* 模式会按照文件名扩展 (pathname expansion) 的方式来扩展，然后对 *parameter* 变量值进行扩展。  
其值中最长匹配 *pattern* 的部分会被替换成 *string* 指定的字符串。

如果 *pattern* 模式开始于 `/`，所有匹配 *pattern* 模式的地方都被替换成 *string* 字符串。  
通常仅仅替换第一个匹配的地方。

如果 *pattern* 模式开始于 `#`，它必须从头开始匹配 *parameter* 变量值。  
如果 *pattern* 模式开始于 `%`，它必须从后往前匹配  *parameter* 变量值。

如果 *string* 字符串是空，匹配 *pattern* 模式的地方会被删除，且跟在 *pattern* 模式之后的 `/` 字符可以省略。

具体举例说明如下：
```bash
$ value="This is a test string. This is a new test"
$ echo ${value/test/TEST}
This is a TEST string. This is a new test
$ echo ${value//test/TEST}
This is a TEST string. This is a new TEST
$ echo ${value/#test/TEST}
This is a test string. This is a new test
$ echo ${value/#This/THIS}
THIS is a test string. This is a new test
$ echo ${value/%test/TEST}
This is a test string. This is a new TEST
$ echo ${value/test}
This is a string. This is a new test
$ echo ${value//test}
This is a string. This is a new
```
可以看到，在 `${value/test/TEST}` 表达式中，*value* 变量值是要被替换的原始字符串。  
中间的 *test* 是要被替换的模式，且只替换第一个出现的 "test" 字符串，不会替换所有的 "test" 字符串。
后面的 *TEST* 是替换之后的内容。  
最终输出的结果是把 *value* 变量值中的第一个 "test" 字符串替换成了 "TEST"，第二个 "test" 字符串没有被替换。

`${value//test/TEST}` 表达式的 "/test" 模式以 `/` 开头，表示替换所有出现的 "test" 字符串。  
输出结果所有的 "test" 字符串都替换成了 "TEST"。

`${value/#test/TEST}` 表达式的 "#test" 模式以 `#` 开头，表示要从 *value* 变量值的第一个字符开始匹配。  
由于 *value* 变量值不是以 "test" 开头，所以匹配不到，并没有做替换。

要使用 `${value/#This/THIS}` 来把 *value* 变量值开头的 "This" 替换成 "THIS"。  
`${value/%test/TEST}` 表达式的情况类似，要求从 *value* 变量值的末尾往前匹配 "test" 字符串。  
这两者都是从最后一个字符往前开始匹配。

`${value/test}` 表达式没有提供替换后的 *string* 参数，表示从 *value* 变量值中删除第一个出现的 "test" 字符串。  
`${value//test}` 表达式的 "/test" 模式以 `/` 开头，表示从 *value* 变量值中删除所有出现的 "test" 字符串。

上面提到 "最长匹配" 部分会被替换。  
所谓的 "最长匹配" 是指被 *pattern* 模式括起来的最长部分。  
常见于用通配符匹配多个字符形成嵌套的情况。

具体举例如下：
```bash
$ value="This is a |test string|new test|, check it"
$ echo ${value/|*|/NEW STRING}
This is a NEW STRING, check it
$ echo ${value/|*|}
This is a , check it
```
可以看到，所给的匹配模式是 `|*|`。使用 `*` 通配符来匹配在两个 `|` 之间的任意字符串。  
在所给的 *value* 变量值里面，"|test string|"、"|test string|new test|" 这两种形式都匹配这个模式。  
实际被替换的是最后一种，也就是最长匹配。  
由于该模式没有以 `/` 开头，只处理第一个匹配的地方，所以 "|new test|" 不会被匹配到。

即，当 *pattern* 模式的扩展结果是不定长的字符串时，它会有一个前缀部分、中间变长部分、后缀部分。  
那么最长匹配是从前缀部分开始匹配，一直到最后一个匹配的后缀部分为止，而不是遇到第一个匹配的后缀部分就停止。  
中间变长部分可以包含多个前缀部分和后缀部分。

下面再举例说明如下：
```bash
$ value="This is a test string, first check it"
$ echo ${value/t*st}
This is a check it
```
可以看到，在所给的 *value* 变量值里面，`t*st` 模式的后缀部分 "st" 匹配到了 "first" 字符串后面的 "st"。  
而不是匹配到 "test" 字符串的 "st"。  
最终结果取最长匹配的部分。

# 汇总说明字符串变量值相关的参数扩展表达式
Linux 的 bash shell 提供了多种形式的参数扩展表达式，可以获取变量自身的值，或者对变量值进行特定处理得到一个新的值，等等。  
本篇文章对字符串变量值相关的参数扩展表达式进行汇总说明。

假设在 bash 中定义了 `filepath=example/subdir/testfile.txt` 这样一个变量，可以使用下面的参数扩展来获取一些值：
- `${filepath}`  
获取 *filepath* 变量的值。  
例如，echo ${filepath} 命令打印的结果是 *example/subdir/testfile.txt*。
- `${#filepath}`  
获取到 *filepath* 变量值的字符个数，也就是字符串长度。  
例如，echo ${#filepath} 命令打印的结果是 27。
- `${filepath:4:3}`  
从 *filepath* 变量值开头的第 4 个字符开始，往后获取三个字符，得到一个子字符串。  
例如，echo ${filepath:4:3} 命令打印的结果是 *ple*。  
注意是从开头的第 0 个字符开始数起。  
这个表达式的格式是 ${parameter:offset:length}，offset 指定从哪个位置开始获取字符，length 指定获取多少个字符。
- `${filepath: -3:3}`  
从 *filepath* 变量值倒数的第 3 个字符开始，往后获取三个字符，得到一个子字符串。  
例如，echo ${filepath: -3:3} 命令打印的结果是 *txt*。  
负数的 offset 表示倒数的偏移值。冒号和负号之间要加空格。  
注意是从末尾的第 1 个字符开始往前数。
- `${filepath#*/}`  
在 *filepath* 变量值中，从头开始匹配所给的 `*/` 这个模式，删除第一个匹配的模式，返回后面剩余的内容。  
这里用 `*` 通配符来匹配开头的任意字符串。  
例如，echo ${filepath#*/} 打印的结果是 *subdir/testfile.txt*。  
这个表达式的格式是 `${parameter#word}`，从 parameter 变量值中删除最短匹配 word 的前缀部分。
- `${filepath##*/}`  
在 *filepath* 变量值中，从头开始匹配所给的 `*/` 这个模式，一直删除到最后一个匹配的模式，返回后面剩余的内容。  
这里用 `*` 通配符来匹配开头的任意字符串。  
例如，echo ${filepath##*/} 打印的结果是 *testfile.txt*。  
这个表达式的格式是 ${parameter##word}，从 parameter 变量值中删除最长匹配 word 的前缀部分。
- `${filepath%/*}`  
在 *filepath* 变量值中，从末尾往前匹配所给的 `/*` 这个模式，删除第一个匹配的模式，返回前面剩余的内容。  
这里用 `*` 通配符来匹配末尾的任意字符串。  
例如，echo ${filepath%/*} 打印的结果是 *example/subdir*。  
这个表达式的格式是 ${parameter%word}，从 parameter 变量值中删除最短匹配 word 的后缀部分。
- `${filepath%%/*}`  
在 *filepath* 变量值中，从末尾往前匹配所给的 `/*` 这个模式，一直删除到最后一个匹配的模式，返回前面剩余的内容。  
这里用 `*` 通配符来匹配末尾的任意字符串。  
例如，echo ${filepath%%/*} 打印的结果是 *example*。  
这个表达式的格式是 ${parameter%%word}，从 parameter 变量值中删除最长匹配 word 的后缀部分。
- `${filepath/[et]/M}`  
在 *filepath* 变量值中，把第一个匹配的小写字母 e、或者小写字母 t，替换成大写字母 M。  
这里用 `[et]` 路径名扩展来匹配小写字母 e、或者小写字母 t。  
这个表达式的格式是 ${parameter/pattern/string}，把匹配 pattern 的字符串替换成 string 字符串。  
只替换第一个匹配的模式字符串。这个模式字符串可以位于变量值的开头、中间、以及末尾部分。  
例如，echo ${filepath/[et]/M} 打印的结果是 *Mxample/subdir/testfile.txt*。
- `${filepath//[et]/M}`  
在 *filepath* 变量值中，把所有匹配的小写字母 e、或者小写字母 t，替换成大写字母 M。  
这里用 `[et]` 扩展来匹配小写字母 e、或者小写字母 t。  
让 pattern 模式字符串以字符 ‘/’ 开头，表示替换所有匹配的字符串。  
例如，echo ${filepath//[et]/M} 打印的结果是 *MxamplM/subdir/MMsMfilM.MxM*。
- `${filepath/subdir}`  
在 *filepath* 变量值中，删除匹配的 subdir 字符串。  
例如，echo ${filepath/subdir} 打印的结果是 *example//testfile.txt*。  
这个表达式没有提供替换之后的字符串，表示删除所匹配的字符串。  
**${parameter#word} 只能删除匹配的前缀。${parameter%word} 只能删除匹配的后缀**。  
而 **${parameter/pattern} 可以删除任意位置的匹配字符串，包括中间位置**。
- `${filepath^^}`  
把 *filepath* 变量值的所有字符都转换为大写。  
例如，echo ${filepath^^} 打印的结果是 *EXAMPLE/SUBDIR/TESTFILE.TXT*。  
这个表达式的格式是 ${parameter^^pattern}，把 parameter 变量值中匹配 pattern 模式的每一个小写字母都转成大写。  
如果没有提供 pattern 模式，表示匹配任意一个字符。
- `${filepath,,}`  
把 *filepath* 变量值的所有字符都转换为小写。  
例如，echo ${filepath,,} 打印的结果是 *example/subdir/testfile.txt*。  
这个表达式的格式是 ${parameter,,pattern}，把 parameter 变量值中匹配 pattern 模式的每一个大写字母都转成小写。  
如果没有提供 pattern 模式，表示匹配任意一个字符。
- `${filepath^}`  
把 *filepath* 变量值的首字符转成大写。  
例如，echo ${filepath^} 打印的结果是 *Example/subdir/testfile.txt*。  
这个表达式的格式是 ${parameter^pattern}，把匹配 pattern 模式的 parameter 变量值首字符转成大写。  
如果没有提供 pattern 模式，表示匹配任意单个字符。  
- `${filepath,}`  
把 *filepath* 变量值的首字符转成小写。  
例如，echo ${filepath,} 打印的结果是 *example/subdir/testfile.txt*。  
这个表达式的格式是 ${parameter,pattern}，把匹配 pattern 模式的 parameter 变量值首字符转成小写。  
如果没有提供 pattern 模式，表示匹配任意单个字符。  
