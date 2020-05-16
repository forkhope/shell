# 记录一些杂项的使用笔记

# 把变量赋值为换行符
在 bash 中，如果要把变量赋值为换行符，写为 '\n' 没有效果，需要写为 $'\n'。具体举例如下：
```bash
$ newline='\n'
$ echo $newline
\n
$ newline=$'\n'
$ echo $newline

```
可以看到，把 *newline* 变量赋值为 '\n'，得到的是 *\n* 这个字符串，而不是换行符自身。

这是 bash 和 C 语言不一样的地方。  
在 C 语言中，'\n' 对应换行符自身，只有一个字符；而 "\n" 对应一个字符串。  
但是在 bash 中，'\n' 也是对应一个字符串。

把 *newline* 赋值为 $'\n'，就能获取到换行符自身。查看 man bash 对这个写法的说明如下：
> Words of the form $'string' are treated specially. The word expands to string, with backslash-escaped characters replaced as specified by the ANSI C standard. Backslash escape sequences, if present, are decoded as follows:
```
    \n     new line
    \r     carriage return
    \t     horizontal tab
    \'     single quote
```
> The expanded result is single-quoted, as if the dollar sign had not been present.

即，$'string' 这个写法可以使用 C 语言的转义字符来获取到对应的字符自身。

# 判断文件的最后一行是否以换行符结尾
在 Linux 中，可以使用下面命令来判断文件的最后一行是否以换行符结尾：
```bash
test -n "$(tail filename -c 1)"
```

这里使用 `tail filename -c 1` 命令获取到 *filename* 文件的最后一个字符。

实际使用时，需要把 *filename* 换成具体要判断的文件名。

`tail` 命令可以获取文件末尾的内容。它的 `-c` 选项指定要获取文件末尾的多少个字节。

查看 man tail 对 `-c` 选项的说明如下：
> **-c, --bytes=K**
>
> output the last K bytes; alternatively, use -c +K to output bytes starting with the Kth of each file.

即，`tail -c 1` 命令指定获取所给文件的最后一个字符。

获取到文件的最后一个字符后，要判断该字符是不是换行符。这里不能直接判断该字符是否等于换行符，而是要判断该字符是否为空。

原因在于，使用 `$(tail filename -c 1)` 命令替换来获取内部命令的输出结果时，bash 会去掉末尾的换行符。

所以当文件的最后一行以换行符结尾时，`$(tail filename -c 1)` 命令替换会去掉获取到的换行符，最终结果为空，并不会返回换行符自身。

查看 man bash 对命令替换（command substitution）的说明如下：
> Command substitution allows the output of a command to replace the command name.  There are two forms:
```
        $(command)
    or
        `command`
```
> Bash performs the expansion by executing command and replacing the command substitution with the standard output of the command, with any trailing newlines deleted.  Embedded newlines are not deleted, but they may be removed during word splitting.

可以看到，经过命令替换后，会去掉末尾的换行符。

由于 `$(tail filename -c 1)` 命令替换会去掉末尾的换行符，这里使用 `test -n` 来判断最终结果是否为空字符串。

如果文件最后一行以换行符结尾，那么 `$(tail filename -c 1)` 的结果为空，`test -n` 命令会返回 1，也就是 false。

如果文件最后一行没有以换行符结尾，那么 `$(tail filename -c 1)` 的结果不为空，`test -n` 命令会返回 0，也就是 true。

可以根据实际需要，改用 `test -z` 来判断。如果文件最后一行以换行符结尾，`$(tail filename -c 1)` 的结果为空，`test -z` 命令会返回 0，也就是 true。

# 介绍 “v=var echo $v” 和 “v=var; echo $v” 命令的区别
在 Linux bash shell 中，当在同一行里面提供不同的命令时，命令之间需要用控制操作符隔开。  
常见的控制操作符有分号 ‘;’、管道操作符 ‘|’、与操作符 ‘&&’、或操作符 ‘||’ 等。  
例如，`v=var; echo $v` 命令先把 v 变量赋值为 var，再用 `echo` 命令打印 v 变量的值。

但是今天在查看安装 wine 命令的文章时，里面提供了如下的命令写法：
```
WINEPREFIX=/home/.no1-wine wine /home/.no1-wine/yyyy
```
在这个命令里面，为 WINEPREFIX 变量赋值的语句和后面执行的 `wine` 命令用空格隔开，而不是用分号 ‘;’ 隔开。  
当然，这个命令本身是合法命令，只是这里为什么要用空格隔开，而不是用分号隔开？  
这种写法跟使用分号隔开的区别是什么呢？

本着钻研精神，通过查看 GNU bash 的在线帮助手册，找到了这种写法的相关说明。具体介绍如下。

GNU bash 在线帮助手册的链接是 <http://www.gnu.org/software/bash/manual/bash.html>。  
后面贴出的英文说明都出自这个在线帮助链接。  
这是 GNU bash 的标准手册，权威可靠。

在 GNU bash 在线帮助手册里面，也用到了类似上面命令的写法。  
在 “10.2 Compilers and Options” 小节提供的编译 bash 命令如下：
```
CC=c89 CFLAGS=-O2 LIBS=-lposix ./configure
```
可以看到，这个命令也是先提供变量赋值语句，再提供要执行的命令，中间用空格隔开。  
在源码编译其他 Linux 软件时，也会用到类似的写法。

# Bash 的简单命令
在 GNU bash 在线帮助手册的 “3.2.1 Simple Commands” 小节介绍了简单命令的概念：
> A simple command is the kind of command encountered most often.  
> It’s just a sequence of words separated by blanks, terminated by one of the shell’s control operators (see Definitions).  
> The first word generally specifies a command to be executed, with the rest of the words being that command’s arguments.

这里面提到，简单命令是一串用空白字符隔开的单词，由 shell 的控制操作符（control operator）所终止。  
一般来说，简单命令的第一个单词就是要执行的命令，后面跟着的单词是该命令的参数。

可以终止简单命令的控制操作符要查看 “2 Definitions” 小节，具体说明如下：
> **control operator**  
> A token that performs a control function.   
> It is a newline or one of the following: ‘||’, ‘&&’, ‘&’, ‘;’, ‘;;’, ‘;&’, ‘;;&’, ‘|’, ‘|&’, ‘(’, or ‘)’.

如前面说明，常见的控制操作符有分号 ‘;’、管道操作符 ‘|’、与操作符 ‘&&’、或操作符 ‘||’ 等。

结合这两个说明，一般来说，简单命令以命令名开头，以控制操作符结尾。  
不同的简单命令之间要用控制操作符或者换行符隔开。

但是在上面提供的 `CC=c89 CFLAGS=-O2 LIBS=-lposix ./configure` 命令中，赋值语句和要执行命令之间没有用控制操作符隔开。  
这就比较奇怪。这也是本篇文章所要讨论的问题。

# Bash 的环境变量
在 GNU bash 在线帮助手册的 “3.7.4 Environment” 小节里面，介绍了先提供变量赋值语句、再提供被执行命令这个写法的作用。  
具体说明如下：
> When a program is invoked it is given an array of strings called the environment.  
> This is a list of name-value pairs, of the form name=value.  
> The environment for any simple command or function may be augmented temporarily by prefixing it with parameter assignments, as described in Shell Parameters.  
> These assignment statements affect only the environment seen by that command.

可以看到，bash 在执行命令时，会为执行命令的进程准备一些环境变量。  
环境变量是由 `name=value` 这种形式的列表组成。

**在简单命令前面提供变量赋值语句，可以在执行该命令时提供临时的环境变量**。  
**所给的变量赋值语句只影响执行该命令时的环境。**

这就是 `CC=c89 CFLAGS=-O2 LIBS=-lposix ./configure` 这种命令写法的作用所在。  
这个命令为 CC、CFLAGS、LIBS 这三个变量赋值，且把这三个变量赋值语句添加到执行 `./configure` 命令时的环境里面。  
那么，`./configure` 命令就可以通过 CC、CFLAGS、LIBS 这三个变量名来获取对应的值。  
这三个赋值语句只影响执行 `./configure` 命令时的环境，不影响当前 shell 的环境。  
也就是说，在当前 shell 中并没有定义 CC、CFLAGS、LIBS 这三个变量。

如果写成 `CC=c89 CFLAGS=-O2 LIBS=-lposix; ./configure` 的形式，用分号 ‘;’ 隔开赋值语句和被执行的命令。  
如前面说明，分号会终止一个简单命令。  
那么赋值语句和被执行的命令之间是两个简单命令，拥有各自不同的进程环境。  
执行 `./configure` 命令时的环境变量没有包含 CC、CFLAGS、LIBS 这三个变量。

# 简单命令的扩展顺序
在 GNU bash 在线帮助手册的 “3.7.1 Simple Command Expansion” 小节里面有如下说明：
> When a simple command is executed, the shell performs the following expansions, assignments, and redirections, from left to right.
> 1. The words that the parser has marked as variable assignments (those preceding the command name) and redirections are saved for later processing.

> If no command name results, the variable assignments affect the current shell environment.  
> Otherwise, the variables are added to the environment of the executed command and do not affect the current shell environment. 

可以看到，当执行一个简单命令时，命令名前面的变量赋值语句会被标识起来，留待后面处理。  
也就是说，在变量名前面提供变量赋值语句，确实是合法有效的写法。

如果变量赋值语句后面没有跟着任何命令名，那么这个赋值语句会影响当前 shell 环境。  
即，会在当前 shell 中定义所赋值的变量。该变量在当前 shell 中可见。

如果变量赋值语句后面跟着命令名，则这个变量会被添加到运行该命令时的环境变量里面，且不会影响当前 shell 环境。  
即，在当前 shell 中没有定义所赋值的变量。该变量在当前 shell 中不可见。

# 环境变量在子 shell 中的继承关系
在 GNU bash 在线帮助手册的 “3.7.3 Command Execution Environment” 小节里面有如下说明：
> When a simple command other than a builtin or shell function is to be executed, it is invoked in a separate execution environment that consists of the following.  
> Unless otherwise noted, the values are inherited from the shell.
> - shell variables and functions marked for export, along with variables exported for the command, passed in the environment (see Environment)

可以看到，bash 会在一个单独的执行环境中执行简单命令，并从父 shell 中继承一些值。  
其中，父 shell 里面定义的变量，默认不会被子 shell 继承。  
只有经过 `export` 命令导出的变量才会被子 shell 继承。

# 验证 “v=var echo $v” 和 “v=var; echo $v” 命令的区别
基于前面说明，可知 “v=var echo $v” 和 “v=var; echo $v” 命令之间的区别在于，执行命令时的环境变量有所不同。  
具体测试如下：
```bash
$ v=var echo $v

$ v=var; echo $v
var
$ v=var env | grep var
v=var
$ v=var; env | grep var

```
可以看到，`v=var echo $v` 命令打印的结果为空。  
在这个命令中，定义了一个 v 变量，并把这个变量添加到执行 `echo $v` 命令的环境变量里面。  
则 `echo` 命令可以通过 v 这个变量名来获取到对应的值。  
但是 `echo` 命令自身的代码没有获取 v 这个变量值，所以没有影响。  
这里的 `echo $v` 命令是获取当前 shell 里面的 v 变量值，作为参数传递给 `echo` 命令。  
由于这种写法定义的 v 变量在当前 shell 中不可见，所以获取到的值为空。  
最终打印结果为空。

而 `v=var; echo $v` 命令打印了 v 变量的值。  
这里在 `v=var` 之后加了分号 ‘;’，让 `v=var` 成为一个单独的简单命令。  
基于前面说明，v 变量在当前 shell 中可见。  
之后 `echo $v` 命令能够在当前 shell 中获取到 v 变量值，作为参数传递给 `echo` 命令。  
`echo` 命令收到传入的参数值，打印出 “var” 字符串。

进一步验证，`v=var env | grep var` 命令用 `env` 命令打印出运行时的环境变量，并过滤出 var 关键字。  
可以看到，打印出来的环境变量中包含了 `v=var` 这个赋值语句。  
这个打印结果和前面说明相符。在命令前面提供变量赋值语句，变量会添加到执行命令时的环境变量里面。

而 `v=var; env | grep var` 命令的打印结果为空。  
这个命令虽然在当前 shell 中定义了 v 变量，但是 v 变量没有添加到当前 shell 的环境变量里面。  
所以 `env` 的打印里面没有包含 `v=var` 这个赋值语句。

# 验证 “v=var ./test.sh” 和 “v=var; ./test.sh” 命令的区别
由于 `echo` 命令自身的代码没有获取 v 这个变量值，不能明显看到 v 变量添加到环境变量后的测试结果。

假设有一个 `test.sh` 脚本，内容如下：
```bash
#!/bin/bash
echo $v
```
这个脚本打印一个 v 变量的值。但是脚本自身没有定义 v 变量。

使用这个脚本进行测试的结果如下：
```bash
$ v=var ./test.sh
var
$ v=var; ./test.sh

```
可以看到，`v=var ./test.sh` 命令打印出 v 变量对应的值。  
虽然 `test.sh` 脚本自身没有定义 v 变量，但是执行时在命令名前面提供了 `v=var` 变量赋值语句。  
这会把 v 变量添加到了执行 `test.sh` 脚本时的环境变量里面，让 `test.sh` 脚本获取到了 v 变量的值。

而 `v=var; ./test.sh` 命令打印为空。  
这种写法是在当前 shell 中定义 v 变量。  
基于前面说明的“环境变量在子 shell 中的继承关系”，可知这个 v 变量不会被子 shell 继承。  
所以执行 `test.sh` 脚本时，不会获取父 shell 里面的 v 变量值。  
而 `test.sh` 脚本自身又没有定义 v 变量，所以打印结果为空。

最后，修改 `test.sh` 脚本为如下内容，让该脚本自身定义 v 变量：
```bash
#!/bin/bash
v=init
echo $v
```

再次测试的结果如下：
```bash
$ v=var ./test.sh
init
$ v=var; ./test.sh
init
```
可以看到，当 `test.sh` 脚本自身定义了 v 变量时，以 `test.sh` 脚本定义的值为准，不受环境变量的影响。

# 结语
总的来说，在命令名前面提供变量赋值语句，且变量赋值语句和命令名之间用空格隔开时，所给的变量赋值语句会添加到执行命令时的环境变量里面，且不影响当前 shell 的执行环境。

本篇文章的发起点从偶然看到一个 `WINEPREFIX=/home/.no1-wine wine /home/.no1-wine/yyyy` 命令开始，敏锐地察觉到这个写法的怪异之处。  
没有轻易放过这个疑问，通过查看 GNU bash 的在线帮助手册，找到这个写法对应的说明，可谓是因小见大、查缺补漏了。