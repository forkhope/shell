# 记录 bash parameters 的相关笔记

#  Bash 的 位置参数 (positional parameter)
假设执行 `./test.sh a b c` 这样一个命令，则可以使用下面的参数来获取一些值：
- `$0`
对应 "./test.sh" 这个值。如果执行的是 `./work/test.sh`， 则对应 `./work/test.sh` 这个值，而不是只返回文件名本身的部分。
- `$1`
会获取到 `a`，即 `$1` 对应传给脚本的第一个参数。
- `$2`
会获取到 `b`，即 `$2` 对应传给脚本的第二个参数，`$3` 对应传给脚本的第三个参数，以此类推。
- `$#`
会获取到 3，对应传入脚本的参数个数，统计的参数不包括 `$0`。
- `$@`
会获取到 `"a" "b" "c"`，也就是所有参数的列表，不包括 `$0`。
- `$*`
也会获取到 `"a" "b" "c"`， 其值和 `$@` 相同，但 `"$*"` 和 `"$@"` 有所不同。`"$*"` 把所有参数合并成一个字符串，而 `"$@"` 会得到一个字符串参数数组。

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
这个脚本分别遍历 `"$*"` 和 `"$@"` 扩展后的内容，并打印出来。执行 `./testparams.sh`，结果如下：
```bash
$ ./testparams.sh This is a test
****: This is a test
--------------
@@@@: This
@@@@: is
@@@@: a
@@@@: test
```
可以看到，`"$*"` 只产生一个字符串，for 循环只遍历一次。而 `"$@"` 产生了多个字符串，for 循环遍历多次，是一个字符串参数数组。

**注意**：如果传入的参数多于 9 个，则不能使用 `$10` 来引用第 10 个参数，而是要用 `${10}` 来引用。即，需要用大括号`{}`把大于 9 的数字括起来。例如，`${10}` 表示获取第 10 个参数的值，写为 `$10` 获取不到第 10 个参数的值。实际上，`$10` 相当于 `${1}0`，也就是先获取 `$1` 的值，后面再跟上 0，如果 `$1` 的值是 "first"，则 `$10` 的值是 "first0"。

查看 man bash 里面对 positional parameter 的说明如下：
> **Positional Parameters**  
    A  positional  parameter  is  a  parameter  denoted by one or more digits, other than the single digit 0.  Positional parameters are assigned from the shell's arguments when it is invoked, and may be reassigned using the set builtin command.  Positional parameters may not be assigned to with assignment statements.  The positional parameters are temporarily replaced when a shell function is executed.  
    When a positional parameter consisting of more than a single digit is expanded, it must be enclosed in braces.

即，最后一句提到当 positional parameter 由多位数字组成时，需要用大括号`{}`把多位数字括起来。

## 获取位置参数的个数
在 bash 中，可以使用 `$#` 来获取传入的命令行或者传入函数的参数个数。要注意的是，`$#` 统计的参数个数不包括脚本自身名称或者函数命数。例如，执行 `./a.sh a b`，则 `$#` 是 2，而不是 3。查看 man bash 的说明如下：
> **Special Parameters**  
**\#**      Expands to the number of positional parameters in decimal.

可以看到，`$#` 实际上是扩展为 位置参数 (positional parameters) 的个数，统计的参数不包括 `$0`。

# 使用 getopts 命令解析选项参数
## getopts 命令简介
在 bash shell 上执行命令，常常会用到一些选项参数来指定不同的操作。例如 `ls` 命令的 `-l`、`-a` 选项等。我们在编写 shell 脚本时，也可以自定义一些选项参数，并使用 bash 的 *getopts* 内置命令来解析选项参数。查看 man bash 里面对 *getopts* 内置命令的说明如下：
> **getopts optstring name [args]**  
getopts  is  used  by  shell procedures to parse positional parameters.  *optstring* contains the option characters to be recognized; if a character is followed by a colon, the option is expected to have an argument, which should be separated from it by white space.  The colon and question mark characters may not be used as option characters.  Each time it is invoked, getopts places the next option in the shell variable *name*,  initializing  *name*  if it does not exist, and the index of the next argument to be processed into the variable *OPTIND*.  *OPTIND* is initialized to 1 each time the shell or a shell script is invoked.  When an option requires an argument, getopts places that argument into the variable *OPTARG*.  The shell does not reset *OPTIND* automatically; it must be manually reset between multiple calls to getopts within the same shell invocation if a new set of  parameters is to be used.

> When the end of options is encountered, getopts exits with a return value greater than zero.  *OPTIND* is set to the index of the first non-option argument, and *name* is set to `?`.

> getopts normally parses the positional parameters, but if more arguments are given in *args*, getopts parses those instead.

> getopts  can  report errors in two ways.  If the first character of *optstring* is a colon, *silent* error reporting is used.  In normal operation, diagnostic messages are printed when invalid options or missing option arguments are encountered.  If the variable OPTERR is set to 0, no error messages will be displayed, even if the first character of *optstring* is not a colon.

> If an invalid option is seen, getopts places `?` into *name* and, if not silent, prints an error message and unsets *OPTARG*.  If getopts is silent, the option character found is placed in *OPTARG* and no diagnostic  message  is printed.

> If  a  required argument is not found, and getopts is not silent, a question mark (?) is placed in *name*, *OPTARG* is unset, and a diagnostic message is printed.  If getopts is silent, then a colon (:) is placed in *name* and *OPTARG* is set to the option character found.

> getopts returns true if an option, specified or unspecified, is found.  It returns false if the end of options is encountered or an error occurs.

**注意**：`getopts` 是 bash 的内置命令。对于 bash 内置命令来说，不能用 man 命令查看它们的帮助说明，要使用 help 命令查看，也可以在 man bash 里面搜索命令名称查看相应的说明：
```bash
$ man getopts
No manual entry for getopts
$ help getopts
getopts: getopts optstring name [arg]
    Parse option arguments.
    ......
```
可以看到，man getopts 提示找不到 getopts 命令的说明，而 help getopts 打印了它的说明。

另外，有一个 `getopt` 外部命令也可以解析命令选项，名称比 `getopts` 少了一个 *s*，用法也有所差异，不要把这两个命令搞混了。

## getopts optstring name [args]
基于 `getopts optstring name [args]` 命令格式，对 getopts 命令的用法说明如下。
- `optstring`  
该参数指定支持的选项参数列表，每个字符对应一个选项。如果字符后面跟着冒号 `:`，那么在输入该选项时预期后面跟着一个参数，选项和参数之间用空格隔开。不能使用冒号 `:` 和问号 `?` 来作为选项。  
例如，一个有效的 optstring 参数值是 "hi:"。那么 `-h` 就是一个选项；`-i` 也是一个选项，由于在 `i` 后面跟着冒号 `:`，那么输入 `-i` 选项时还要提供一个参数，如 `-i insert` 等，如果不提供参数，getopts 命令会报错。  
**注意**：optstring 参数的选项列表不包含 `-` 字符，但是在实际输入选项参数时，getopts 命令要求选项参数以 `-` 开头，否则会报错。以上面例子来说，`-h` 是一个选项，但是 `h` 并不是一个有效的选项。
- `name`  
该参数用于保存解析后的选项名。每调用一次 getopts 命令，它只解析一个选项，并把解析的值存入 *name* 变量中，解析后的值不包含 `-` 字符。例如解析 `-h` 选项后，*name* 变量的值是字符 h。该变量的名称不要求只能是 *name* 字符串，也可以是其他合法的变量名，例如 *opt*、*arg* 等等。  
如果要解析多个选项时，需要在 while 或者 for 循环中多次执行 getopts 命令，来逐个解析参数选项，直到解析完毕为止。解析完毕，getopts 命令会返回 false，从而退出循环。  
如果提供的选项不在 optstring 指定的列表里面，*name* 的值会被设成问号 `?`，但是 getopts 命令还是返回true，不会报错。
- `[args]`  
这是一个可选参数，用于指定选项参数的来源。getopts 命令默认解析 positional parameters 提供的参数，例如 `$1`、`$2`、...、等等。如果提供了 *args* 参数，那么从 *args* 中解析选项参数，不再从 positional parameters 中解析。  
即，在 shell 脚本里面直接执行 getopts 命令，它解析的选项参数是执行脚本时提供的参数。例如有一个 `testgetopts.sh` 脚本，那么执行 `./testgetopts.sh -a -b` 命令，getopts 解析的就是 `-a`、`-b` 选项。  
如果是在函数内执行 getopts 命令，它解析的选项参数是调用函数时提供的参数。例如有一个 *test_getopts* 函数，该函数内调用 getopts 命令，那么执行 `test_getopts -a -b` 语句，`getopts` 解析的就是 `-a`、`-b` 选项。  
如果提供了 *args* 参数，getopts 改成解析 *args* 参数包含的选项。例如执行 `args="-a -b"; getopts "ab" opt $args` 语句，getopts 解析的就是 args 变量指定的 "-a -b" 字符串。
- `OPTARG`  
这是 getopts 命令用到的一个全局变量，保存解析出来的带冒号选项后面的参数值。例如解析上面提到的 `-i insert` 选项，那么 OPTARG 的值就是 *insert*。
- `OPTIND`  
这是 getopts 命令用到的一个全局变量，保存下一个待解析的参数index。当启动新的shell时，OPTIND 的默认值是 1，调用一次 `getopts` 命令，OPTIND 的值加 1，如果带冒号的选项后面提供了参数，OPTIND 的值会加 2。当 getopts 命令解析完所有参数后，shell 不会自动重置 OPTIND 为 1。如果在同一个 shell 脚本里面要解析不同的选项参数，需要手动为 OPTIND 赋值为 1，否则会解析到不预期的选项。后面会以一个 `testgetopts.sh` 脚本为例进行说明。

## getopts 命令的返回值
查看 man bash 里面对 getopts 命令的返回值说明如下：
> getopts  returns true if an option, specified or unspecified, is found.  It returns false if the end of options is encountered or an error occurs.

可以看到，即使提供不支持的选项，getopts 命令也是返回true。当解析完所有选项后，getopts 会返回 false，遇到错误时也会返回 false。遇到错误的情况有如下几种：
- 选项没有以 `-` 开头
- 带有冒号的选项要求后面提供一个参数，但是没有提供参数

## `testgetopts.sh` 脚本
下面以一个 `testgetopts.sh` 脚本举例说明 getopts 命令的用法，其内容如下：
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
这个脚本先在 *test_getopts_ab* 函数中调用 getopts 命令，解析传入的 `"-a" "-b"` 选项，然后调用 getopts 命令解析执行脚本时传入的命令行选项参数，最后重置 OPTIND 的值，重新解析命令行选项参数。

以 `getopts "ab" opt_ab` 语句来说，"ab" 对应上面提到的 *optstring* 参数，它支持的选项就是 `-a`、`-b`。opt_ab 对应上面提到的 *name* 变量名，保存解析得到的选项，不包含 `-` 字符。

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
可以看到，*test_getopts_ab* 函数解析完选项参数后，在函数外打印 OPTIND 的值是 3，再次调用 getopts 命令，OPTIND 值没有从 1 开始，还是从 3 开始取值，取到了传给 `testgetopts.sh` 的第三个参数 `-g`，跳过了前面的 `-s 7` 两个参数，这并不是预期的结果。正常来说，预期是从第一个选项参数开始解析。由于 `getopts "ef" opt_ef` 语句不支持 `-g` 选项，打印报错信息，并把 opt_ef 赋值为问号 `?`。

手动将 OPTIND 值重置为 1 后，`getopts "s:g" opt_sg` 可以从第一个选项参数开始解析，先处理 `-s 7` 选项，getopts 把 7 赋值给 OPTARG，脚本里面再把 OPTARG 的值赋给 number 变量；然后继续处理 `-g` 选项，打印出 number 变量的值；最后处理 `-f` 选项，该选项不支持，opt_sg 的值被设成问号 `?`，打印 "unknown option" 的信息。处理完所有选项后，getopts 返回 false，退出 while 循环。

## 错误判断
`getopts` 命令处理完选项参数、或者遇到错误时，都会返回 false，不能通过判断返回值来确认是否遇到了错误。当在 while 或者 for 循环中调用 getopts 时，可以通过 OPTIND 的值来判断 getopts 是否遇到了错误。如果 OPTIND 的值减去 1 后，不等于传入的参数个数，那么就是遇到了错误导致提前退出循环。

当 getopts 处理选项参数时，OPTIND 的值从 1 开始递增，处理所有参数后，OPTIND 指向最后一个参数，相当于是所有参数个数加 1，所以 OPTIND 的值减去 1 就应该等于传入的参数个数，bash 的 `$#` 表达式可以获取传入的参数个数，如果这两个值不相等，那么 getopts 就没有解析完选项参数，也就是遇到了错误导致提前退出循环。假设有一个 `test.sh` 脚本，内容如下：
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
可以看到，当正常遇到选项末尾时，OPTIND 变量的值是选项个数加 1；当遇到错误时，OPTIND 变量的值不是选项个数加 1；所以当 OPTIND 变量的值减去1，不等于 `$#` 时，就表示遇到了错误。

## 通过 source 多次脚本对 OPTIND 的影响
由于 shell 不会自动重置 OPTIND 的值，通过 source 命令调用脚本是运行在当前 shell 下，如果要调用的脚本使用了 getopts 命令解析选项参数，在每次调用 getopts 之前，一定要手动重置 OPTIND 为 1，否则 OPTIND 的值不是从 1 开始递增，会获取到不预期的选项参数值。假设有一个 `test.sh` 脚本，其内容如下：
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
可以看到，执行 `./test.sh -a`、`./test.sh -b` 输出的结果都是正常的。执行 `source ./test.sh -a` 命令的结果也是正常，但是接着执行 `source ./test.sh -b` 命令，调用 getopts 之前，打印出 OPTIND 的值是 2，要获取第二个选项参数，由于没有提供，获取到的选项参数值是问号 `?`，用 `$?` 获取 getopts 命令的返回值是 1，执行报错。

即，如果一个脚本使用了 getopts 命令，而该脚本又要用 source 命令来执行时，脚本需要手动设置 OPTIND 变量的值为1，否则会遇到上面的异常。

当我们自己写了一个脚本，并在 `.bashrc` 中用 alias 命令设置用 source 执行该脚本时，可能就会遇到这种场景。

# 用 $ 获取变量值是否要加双引号
在 bash shell 脚本中，用 $ 来获取变量值时，有一些不加双引号，例如 `$arg`，有一些会加双引号，例如 `"$arg"`。这两种形式有什么区别，什么情况下要加双引号，什么情况可以不加？具体说明如下。

在 bash 中各个参数之间默认用空格隔开，当参数值本身就带有空格时，如果不加双引号把参数值括起来，那么这个参数值可能会被扩展为多个参数值，而丢失原本的完整值。例如：
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
这里定义了一个 *test_args* 函数，打印传入的 `$1`、`$2` 参数值。args 变量指定的字符串含有空格。可以看到，当执行 `test_args $args` 时，args 变量的值被空格隔开成四个参数，而执行 `test_args "$args"` 时，args 变量的值保持不变，被当成一个参数。使用双引号把字符串括起来，可以避免空格扩展。

即，当我们需要保持变量本身值的完整，不想被空格扩展为多个参数，那么就需要用双引号括起来。在给脚本或函数传递参数时，我们可能不确定获取到的参数值是否带有空格，为了避免出现不预期的空格扩展，加以传参时每个参数都使用双引号括起来。

# 用 $ 获取变量值是否要加大括号
在 bash shell 脚本中，用 $ 来获取变量值时，有一些不加大括号，例如 `$var`，有一些会加大括号，例如 `${var}`。这两种形式有什么区别，什么情况下要加双引号，什么情况可以不加？具体说明如下。

查看 man bash 里面对 `${parameter}` 表达式的含义说明如下：
> **${parameter}**  
    The value of parameter is substituted.  The braces are required when parameter is a positional parameter with more than one digit, or when parameter is followed by a character which is not to be interpreted as part of its name.  The parameter is a shell parameter or an array reference (Arrays).

即，`{}` 的作用是限定大括号里面的字符串是一个整体，不会跟相邻的字符组合成其他含义。

例如，有一个 var 变量值是 "Say"，现在想打印这个变量值，并跟着打印 "Hello" 字符串，也就是打印出来 "SayHello" 字符串，那么获取 var 变量值的语句和 "Hello" 字符串中间就不能有空格，否则 *echo* 命令会把这个空格一起打印出来，但是写为 `$varHello` 达不到想要的效果。具体举例如下：
```bash
$ var="Say"
$ echo $var Hello
Say Hello
$ echo $varHello

$ echo ${var}Hello
SayHello
```
可以看到，`$var Hello` 这种写法打印出来的 "Say" 和 "Hello" 中间有空格，不是想要的结果。而 `$varHello` 打印为空，这其实是获取 varHello 变量的值，这个变量没有定义过，默认值是空。`${var}Hello` 打印出了想要的结果，用 `{}` 把 var 括起来，明确指定要获取的变量名是 var，避免混淆。

即，当用 $ 获取变量值时，如果变量名后面跟着空白字符，隔开了其他内容，可以不用大括号来把变量名括起来。如果要在把变量值和其他字符拼接起来，变量名后面直接跟着其他字符，就要用大括号把变量名括起来。
