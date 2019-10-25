# 记录 bash 函数的使用笔记

# 定义函数
在 bash 中，定义函数时，*function* 关键字是可选的，查看man bash手册，可以看到其定义函数的格式如下：
> name () compound-command [redirection]  
function name [()] compound-command [redirection]

从中可以看到，当不写 *function* 关键字时，函数名后面一定要跟着小括号`()`，而写了 *function* 关键字时，小括号是可选的。

关于 compound-command 的说明，同样可以查看 man bash 手册，里面提到下面几种形式：
> A compound command is one of the following:  
**(list)** list is executed in a subshell environment. Variable assignments and builtin commands that affect the shell's environment do not remain in effect after the command completes. The return status is the exit status of list.  
**{ list; }** list is simply executed in the current shell environment. list must be terminated with a newline or semicolon. The return status is the exit status of list.

常见的是 `{ list; }` 这种形式，但是写为 `(list)` 也可以。举例如下：
```bash
$ testpwd() (pwd)
$ testpwd
/home/somebody/sample/
$ testpwd() ( pwd )
$ testpwd
/home/somebody/sample/
$ testpwd() (pwd;)
$ testpwd
/home/somebody/sample/
```
这里定义了一个 *testpwd* 函数，它自身的代码是用小括号`()`括起来的 *pwd* 命令，这个命令跟 `()` 之间可以有空格，也可以没有空格。在命令后可以加分号，也可以不加分号。

**注意**：使用 `{ list; }` 这个写法时，在 list 后面一定要跟着分号';'，否则会报错。而且 `list;` 和左边的大括号 `{` 之间要有空格。如果写为 `{list;}` 会报错，而 `{ list;}` 不会报错，建议还是写为 `{ list; }` 的形式。举例如下：
```bash
$ lsfunc() {ls}
-bash: syntax error near unexpected token `{ls}'
$ function lsfunc() {ls;}
-bash: syntax error near unexpected token `{ls'
$ lsfunc() { ls;}
$ lsfunc
hello.c
```

调用 bash shell 的函数时，不需要写小括号`()`。例如执行上面的 lsfunc() 函数，直接写 `lsfunc` 就可以。如果写成 `lsfunc()` 反而变成重新定义这个函数。

# 函数返回值
Bash 要求函数的返回值必须为一个整数，不能用 *return* 语句返回字符串变量。一般来说，该整数返回值为 0，表示函数执行成功，非0 表示执行失败。

在自定义的函数里面，执行 *return* 语句会退出函数，不会退出整个脚本。在函数里面执行 *exit* 语句则会退出整个脚本，而不是只退出函数。

由于在函数内部用 *return* 返回，只能返回整数。如果想从函数内部把字符串传递到函数之外，可以用 *echo* 命令来实现，就是在函数内部打印字符串，然后调用者获取标准输出获取到打印的字符串。举例如下：
```bash
$ function foo() { echo "foo"; return 0; }; var=$(foo); echo ${var}, $?
foo, 0
```
可以看到，打印结果是 "foo, 0"。此时看起来，这个函数像是返回了两个值，一个是通过 `$(foo)` 获取 *foo* 函数的标准输出，另一个是 `$?` 会获取函数通过 *return* 语句返回的 0。如果在函数中写为 `return 1`，那么上面的 `$?` 打印的出来的值是 1。  

下面再举例说明如下：
```bash
$ foo() { echo "foo"; }; bar() { foo; }; foobar() { a=$(foo); }
$ var=$(foo); echo first: ${var}
first: foo
$ var=$(bar); echo second: ${var}
second: foo
$ var=$(foobar); echo third: ${var}
third:
```
可以看到， *foo* 函数将字符串写到标准输出，`var=$(foo);` 语句把 *foo* 函数的标准输出赋值给 var 变量，打印 var 变量的值是 "foo"。  
bar() 函数调用了 *foo* 函数，但是没有读取 *foo* 函数打印的标准输出，则这个标准输出会被 *bar* 函数继承，就好象这个标准输出是由 *bar* 函数输出一样，`var=$(bar);` 语句也会把 var 变量赋值为 "foo"。  
而 *foobar* 函数读取了 *foo* 函数的标准输出，*foobar* 函数自身没有用 *echo* 命令来输出内容，此时再通过 `$(foobar)` 来获取该函数的输出，会获取到空，因为 *foo* 函数中的标准输出给 *foobar* 读走了。

**注意**：这种在函数内部通过 *echo* 命令输出字符串的做法有个缺陷，就是不能再在函数里面执行 *echo* 语句来打印调试信息，这些调试信息会被函数外的语句一起读取到，有用的结果和调试信息都混在一起，如果函数外的语句没有打印这些结果，就会看不到调试信息。

执行某个函数后，可以使用 `$?` 表达式来获取函数的 return 返回值，但是要注意下面的一种情况：
```bash
var=$(foo)
if [ "$?" == "0" ]; then
    echo success
fi
```
此时，不要在 `var=$(foo)` 和 `if [ "$?" == "0" ]; then` 之间添加任何语句！否则，`$?` 获取到将不是 `$(foo)` 的 return 值，判断就有问题，特别是不要添加 echo 调试语句。

换句话来说，这种先执行一个语句，再判断 `$?` 的方法不是很可靠，会受到各种影响，要特别注意代码语句的顺序。

# 使用函数名作为函数指针
Bash中可以通过如下的方式来达到类似C语言函数指针的功能。假设有一个 `test.sh` 脚本，内容如下：
```bash
#!/bin/bash

# 注意$1后面有一个分号';', 少这个分号会报错
echo_a() { echo aaaa $1; }
echo_b() { echo bbbb $1; }
if [ "$1" == "-a" ]; then
    # 这里的 echo_a 没有加双引号
    echo_common=echo_a
elif [ "$1" == "-b" ]; then
    # 上面的echo_a没加双引号, 这里加了.
    # 实际上, 可加可不加, 都可以正确执行.
    echo_common="echo_b"
else
    echo ERROR; exit 1
fi
${echo_common} common
```
这个脚本通过 echo_common 变量来保存函数名，相当于是函数指针，再通过 `${echo_common}` 来调用它保存的函数。  
在 bash shell 中执行 `./test.sh -a` 命令，会输出 "aaaa common"；执行 `.test.sh -b`，会输出 "bbbb common" 命令。

# 函数内执行cd命令的影响
在函数里面执行 *cd* 命令，切换到某个目录后，函数退出时，当前工作目录还是会保持在那个目录，而不会自动恢复为原先的工作目录，需要手动执行 `cd -` 命令再切换回去。

假设有一个 `testcd.sh` 脚本，里面的内容如下：
```bash
#!/bin/bash

echo "now, the pwd is: $(pwd)"
cd_to_root() { cd /usr/; }
cd_to_root
echo "after execute the cd_to_root, pwd is: $(pwd)"
```
这个函数先打印出执行脚本时工作目录路径，然后执行自定义的 *cd_to_root* 函数，在函数内部切换工作目录到 "/usr/"，最后在 *cd_to_root* 函数外面打印工作目录路径。

执行 `./testcd.sh` 脚本，会输出下面的内容：
```bash
[~/sample]$ ./testcd.sh
now, the pwd is: /home/somebody/sample
after execute the cd_to_root, pwd is: /usr
[~/sample]$ pwd
/home/somebody/sample
```
可以看到，如果在函数里面执行过 *cd* 命令，函数退出后，当前工作目录还是 *cd* 后的目录。  
但是脚本执行结束后，当前 shell 的工作目录还是之前的工作目录，不是脚本里面 *cd* 后的目录。  

在每个 shell 下面，当前工作目录 (working directory ) 是全局的状态，一旦改变，在整个 shell 里面都会改变。而 bash 执行脚本时，是启动一个新的子 shell 来执行，所以脚本内部执行 *cd* 命令，会影响运行这个脚本的子 shell 的工作目录，但不影响原先父 shell 的工作目录。

# 声明函数内变量为局部变量
在 bash 中，没有使用 *local* 命令来声明的变量都是全局变量，即使在函数内部定义的变量也是全局变量。如果没有注意到这一点，在函数内操作变量可能会影响到外部变量的值，造成不预期的结果。

为了避免对外部同名变量造成影响，函数内的变量最好声明为局部变量，使用 *local* 命令来声明。查看 man bash 里面对 *local* 命令的说明如下：
> **local [option] [name[=value] ...]**  
    For each argument, a local variable named name is created, and assigned value. The option can be any of the options accepted by declare. When local is used within a function, it causes the variable name to have a visible scope restricted to that func‐tion and its children. With no operands, local writes a list of local variables to the standard output. It is an error to use local when not within a function. The return status is 0 unless local is used outside a function, an invalid name is supplied, or name is a readonly variable.

**注意**：如上面说明，*local* 命令本身会返回一个值，正常的返回值是 0。假设有个 `testlocal.sh` 脚本，内容如下：
```bash
#!/bin/bash

foo() { return 1; }
bar() {
    ret=$(foo); echo first: $?
    local var=$(foo); echo second: $?
}
foobar() { return 0; }
bar
local out=$(foobar); echo third: $?
```
则执行 `./testlocal.sh` 脚本，会输出：
```bash
first: 1
second: 0
./testlocal.sh: 第 x 行:local: 只能在函数中使用
third: 1
```
可以看到，`ret=$(foo);` 语句没有使用 local 命令来定义 ret 变量，执行 *foo* 函数，该函数的返回值是 1，所以得到的 `$?` 是 1。

而 `local var=$(foo);` 语句使用 local 命令来定义 var 变量，执行 *foo* 函数，得到的 `$?` 却是 0，而*foo* 函数明明返回的是 1。原因就是该语句先通过 `$(foo)` 执行 *foo* 函数，然后用 `local var` 来定义 var 变量为局部变量，所以该语句对应的 `$?` 是 local 命令的返回值，而不是 *foo* 函数的返回值。

当在函数外执行 local 命令时，它会报错，可以看到虽然 *foobar* 函数返回是 0，但是第三个 echo 语句打印的 `$?`是 1，正好是 local 命令执行出错时的返回值。

即，对于 `local var=$(func);` 这种语句来说，它对应的 `$?` 不是所调用函数的返回值，而是local 命令的返回值。所以执行函数后，想用 `$?` 来判断函数的 return 返回值时，注意不要用这种写法。

为了避免这种情况，最好在函数开头就用 local 命令声明所有局部变量。在用 local 声明多个变量时，变量之间用空格隔开，不要加逗号。例如: `local a b c;`。

# 获取传入函数的所有参数
在 bash 中，可以使用 `$1`、`$2`、`$3`、...、`$n` 的方式来引用传入函数的参数，`$1` 对应第一个参数值，`$2` 对应第二个参数值，依次类推。如果 n 的值大于 9，那么需要用大括号`{}`把 n 括起来。

例如，`${10}` 表示获取第 10 个参数的值，写为 `$10` 获取不到第10个参数的值。实际上，`$10` 相当于 `${1}0`，也就是先获取 `$1` 的值，后面再跟上 0，如果 `$1` 是 "tian"，则 `$10` 的值是 "tian0"。下面通过一个 `testparams.sh` 脚本来举例说明，该脚本的内容如下：
```bash
#!/bin/bash

function show_params()
{
    echo $1 , $2 , $3 , $4 , $5 , $6 , $7 , $8 , $9 , $10 , ${10} , ${11}
}

show_params $@
```
这个脚本把传入自身的参数传给 *show_params* 函数，该函数再打印出各个参数，使用 `$10`、`${10}` 这两个形式来说明它们的区别。执行 `./testparams.sh` 脚本的结果如下：
```bash
$ ./testparams.sh 1a 2b 3c 4d 5e 6f 7g 8h 9i 10j 11k
1a , 2b , 3c , 4d , 5e , 6f , 7g , 8h , 9i , 1a0 , 10j , 11k
```
可以看到，传入的第 10 个参数值是 "10j"，而 `$10` 打印出来的结果是 "1a0"，也就是第一个参数 "1a" 后面再跟上 0。`${10}` 打印的结果才是第 10 个参数的值。相应地，`${11}` 也能正确打印第 11 个参数的值。

`$1`、`$2` 这种写法在 bash 文档里面称之为 *positional  parameter*，中文直译过来是 “位置参数”。查看 man bash 里面的说明如下：
> **Positional Parameters**  
    A  positional  parameter  is  a  parameter  denoted by one or more digits, other than the single digit 0.  Positional parameters are assigned from the shell's arguments when it is invoked, and may be reassigned using the set builtin command.  Positional parameters may not be assigned to with assignment statements.  The positional parameters are temporarily replaced when a shell function is executed.  
    When a positional parameter consisting of more than a single digit is expanded, it must be enclosed in braces.

> **${parameter}**  
    The value of parameter is substituted.  The braces are required when parameter is a positional parameter with more than one digit, or when parameter is followed by a character which is not to be interpreted as part of its name.  The parameter is a shell parameter or an array reference (Arrays).

可以看到，这里面提到了需要用大括号`{}`把大于9的数字括起来，`{}` 的作用是限定大括号里面的字符串是一个整体。例如，有一个 var 变量值是 "Test"，现在想打印这个变量值，并跟着打印 "Hello" 字符串，也就是打印出来 "TestHello" 字符串，那么获取 var 变量值的语句和 "Hello" 字符串中间就不能有空格，否则 *echo* 命令会把这个空格一起打印出来，但是写为 `$varHello` 达不到想要的效果。具体举例如下：
```bash
$ var="Test"
[~/sample/gittest]$ echo $var Hello
Test Hello
[~/sample/gittest]$ echo $varHello

[~/sample/gittest]$ echo ${var}Hello
TestHello
```
可以看到，`$var Hello` 这种写法打印出来的 "Test" 和 "Hello" 中间有空格，不是想要的结果。而 `$varHello` 打印为空，这其实是获取 varHello 变量的值，这个变量没有定义过，默认值是空。`${var}Hello` 打印出了想要的结果，用 `{}` 把 var 括起来，明确指定要获取的变量名是 var，避免混淆。

上面贴出的 `testparams.sh` 脚本代码里面还用到了一个 `$@` 特殊参数，它会扩展为 *positional  parameter* 自身的列表。查看 man bash 的说明如下：
> **Special Parameters**  
**@**      Expands  to the positional parameters, starting from one.  When the expansion occurs within double quotes, each parameter expands to a separate word.  That is, "$@" is equivalent to "$1" "$2" ...

**注意**：`$@` 和 `"$@"` 这两种写法得到的结果可能会有所不同。`$@` 是扩展为 `$1` `$2` ...，而 `"$@"` 是扩展为 `"$1"` `"$2"` ...  
修改上面的 `testparams.sh` 脚本来举例说明 `$@` 和 `"$@"` 的区别：
```bash
#!/bin/bash

function show_params()
{
    echo $1 , $2 , $3
}

show_params $@
show_params "$@"
```
执行 `testparams.sh` 脚本，输出结果如下：
```bash
$ ./testparams.sh 1a 2b 3c
1a , 2b , 3c
1a , 2b , 3c
$ ./testparams.sh "1 a" "2 b" "3 c"
1 , a , 2
1 a , 2 b , 3 c
$ ./testparams.sh 1a 2b
1a , 2b ,
1a , 2b ,
```
可以看到，当传入脚本的参数值不带空格时，`$@` 和 `"$@"` 得到的结果相同。  
当传入脚本的参数值自身带有空格时，`$@` 得到的参数个数会变多，`"$@"` 可以保持参数个数不变。上面的 `$1` 是 "1 a"，`$@` 会拆分成 "1" "2" 两个参数，再传入 *show_params* 函数；`"$@"` 会保持为 "1 a" 不变，再传给*show_params* 函数。  
即，`"1 a" "2 b" "3 c"` 这三个参数，经过 `$@` 处理后，得到的是 `"1" "a" "2" "b" "3" "c"`  六个参数。经过 `"$@"` 处理后，得到的还是 `"1 a" "2 b" "3 c"` 三个参数。

同时也看到，即使只传入两个参数，引用 `$3` 也不会报错，只是会获取为空。
