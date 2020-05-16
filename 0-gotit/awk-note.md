# 描述 awk 命令的使用

在 Linux 命令中，`awk` 命令常用于处理文本内容。下面基于实例介绍 `awk` 命令的常见用法。

# GNU gawk
`awk` 既是一个命令，也是一种程序语言，它可以有不同的实现版本。

在 Linux 系统中，`awk` 的实现版本是 GNU gawk。

在 shell 中执行 `awk` 命令，实际执行的是 `gawk` 命令。如下所示：
```bash
$ ls -l /usr/bin/awk
lrwxrwxrwx 1 root root 21  2月  1  2019 /usr/bin/awk -> /etc/alternatives/awk
$ ls -l /etc/alternatives/awk
lrwxrwxrwx 1 root root 13  3月  8  2019 /etc/alternatives/awk -> /usr/bin/gawk
$ ls -l /usr/bin/gawk
-rwxr-xr-x 1 root root 441512  7月  3  2013 /usr/bin/gawk
```
可以看到，*/usr/bin/awk* 文件最终链接到 */usr/bin/gawk* 文件，*/usr/bin/gawk* 文件没有再链接到其他文件。

在下面的描述中，如无特别说明，所说的 `awk` 是指 GNU gawk。

# awk 命令格式
查看 man awk 的说明，也是链接到 man gawk 的内容，这个说明比较难懂，不够清晰，可以再参考 GNU gawk 在线帮助手册 <https://www.gnu.org/software/gawk/manual/gawk.html> 的说明。

下面引用的内容就出自这个在线帮助手册，其中对 `awk` 的基本介绍如下：
> The basic function of awk is to search files for lines (or other units of text) that contain certain patterns.
> When a line matches one of the patterns, awk performs specified actions on that line.
> awk continues to process input lines in this way until it reaches the end of the input files.

`awk` 命令的基本用法说明如下：
> There are several ways to run an awk program. 
> If the program is short, it is easiest to include it in the command that runs awk, like this:  
> `awk 'program' input-file1 input-file2 …`  
> where program consists of a series of patterns and actions, an awk program looks like this:  
> `pattern { action }`
>
> When the program is long, it is usually more convenient to put it in a file and run it with a command like this:  
`awk -f program-file input-file1 input-file2 …`
>
> There are single quotes around program so the shell won’t interpret any awk characters as special shell characters. 
> The quotes also cause the shell to treat all of program as a single argument for awk, and allow program to be more than one line long.
>
> You can also run awk without any input files. If you type the following command line:  
> `awk 'program'`  
> awk applies the program to the standard input, which usually means whatever you type on the keyboard.

即，`awk` 命令在所给文件中查找包含特定模式的行，并对找到的行进行特定处理。  
这些特定处理由 *program* 参数指定。

上面提到，所给的 *program* 参数要用单引号括起来，避免 shell 对一些特殊字符进行扩展。

如果没有提供文件名，`awk` 命令默认会读取标准输入。

如果没有提供特定模式，默认处理所有行。

**注意**：跟在 `awk` 命令的 *program* 参数后面的参数会被认为是文件名，即使用引号把参数值括起来也还是当成文件名，不会当成字符串。

这个命令不能处理命令行参数提供的字符串值，具体举例说明如下：
```bash
$ cat testawk
This is a test string.
This is another TEST string.
$ awk '{print $3}' testawk
a
another
$ awk '{print $3}' "testawk"
a
another
$ awk '{print $3}' "This is a test string."
awk: fatal: cannot open file `This is a test string.' for reading (No such file or directory)
```
可以看到，`awk '{print $3}' testawk` 命令打印出 *testawk* 文件的第三列内容。

`awk '{print $3}' "testawk"` 命令也是打印出 *testawk* 文件的第三列内容。  
即使用双引号把 testawk 括起来，也不代表是打印 "testawk" 字符串的第三列。

而 `awk '{print $3}' "This is a test string."` 命令会执行报错，提示找不到名为 *This is a test string.* 的文件，它不会处理 "This is a test string." 这个字符串自身的内容，而是把该字符串当成文件名，要处理对应文件的内容。

如果确实需要用 `awk` 命令来处理字符串，可以用管道操作符 `|` 来连接标准输入。

例如用 `echo` 命令打印字符串的值，然后通过管道操作符把这个值传递到 `awk` 命令的标准输入。

具体举例如下：
```bash
$ echo "This is a test string." | awk '{print $4}'
test
$ value="This is a new test string."
$ echo "$value" | awk '{print $4}'
new
```
可以看到，`echo "This is a test string." | awk '{print $4}'` 命令通过 `echo` 先输出字符串的值，再通过管道操作符 `|` 把这个输出连接到 `awk` 命令的标准输入，就能对这个字符串进行处理，不会执行报错。

`echo "$value" | awk '{print $4}'` 命令打印出 *value* 变量值的第四列内容，可以用这个方式来对变量值进行处理。

**注意**：这里使用管道操作符 `|` 来连接标准输入，让 `awk` 命令能够处理传入到标准输入的字符串，但是使用重定向标准输入操作符 `<` 并不能让 `awk` 命令处理字符串。

重定向是基于文件的操作，所给的字符串会被当成文件名，举例如下：
```bash
$ awk '{print $4}' < "This is a test string."
-bash: This is a test string.: No such file or directory
```
可以看到，在重定向标准输入操作符 `<` 右边的 "This is a test string." 字符串被当成文件名，bash 提示找不到文件。

这里不是 `awk` 命令报错，而是 bash 在处理重定向的时候报错。

# awk program
使用 `awk` 命令的关键在于，*program* 参数要怎么写。

查看 GNU gawk 在线帮助手册的说明，列举部分内容如下：
- Programs in awk consist of pattern–action pairs.
- An action without a pattern always runs. 
- An awk program generally looks like this: [pattern]  { action }
- Patterns in awk control the execution of rules -- a rule is executed when its pattern matches the current input record.
- The purpose of the action is to tell awk what to do once a match for the pattern is found.
- An action consists of one or more awk statements, enclosed in braces (‘{…}’).

即，`awk` 命令的 *program* 参数由 *pattern* 和 *action* 组成。*Pattern* 用于指定匹配模式，并对匹配的行执行后面的 *action* 操作，不匹配的行不做处理。  
*Action* 用于指定要对匹配到的行进行什么样的操作，这些操作语句要包含在大括号 `{}` 里面。  
如果没有提供 *pattern* 参数，默认处理所有行。

部分 *pattern* 参数的写法说明如下：
- **/regular expression/**  
A regular expression. It matches when the text of the input record fits the regular expression. 
- **expression**  
A single expression. It matches when its value is nonzero (if a number) or non-null (if a string).

具体举例说明如下：
```bash
$ awk '/a.*/ {print $0}' testawk
This is a test string.
This is another TEST string.
$ awk '/test/ {print $0}' testawk
This is a test string.
$ awk 'test {print $0}' testawk
$ awk '"NONE" {print $0}' testawk
This is a test string.
This is another TEST string.
$ awk '$3 == "another" {print $0}' testawk
This is another TEST string.
```
可以看到，`awk '/a.*/ {print $0}' testawk` 命令使用 `a.*` 正则表达式来匹配包含字符 ‘a’ 的行，然后打印出整行内容。

`awk '/test/ {print $0}' testawk` 命令则是打印包含 "test" 字符串的行。

`awk 'test {print $0}' testawk` 命令什么都没有打印，这种写法并不表示打印包含 "test" 字符串的行。

`awk '"NONE" {print $0}' testawk` 命令打印出 *testawk* 文件的所有行，虽然这个文件并没有包含 "NONE" 字符串。  
基于上面说明，所给的 *pattern* 参数是一个用双引号括起来的非空字符串，表示总是匹配，不管这个字符串的内容是什么。

`awk '$3 == "another" {print $0}' testawk` 命令匹配第三列内容为 "another" 字符串的行，并打印出整行内容。

即，如果要指定匹配某个字符串，*pattern* 参数写为 “/regular expression/” 的形式会比较简单，要写为 “expression” 形式，需要了解 `awk` 的表达式写法。

# 获取所给行的内容
`awk` 在读取每行内容时，会基于分割字符把行内容拆分成多个单词，可以用 `$number` 来获取第 *number* 列的单词，*number* 值从 1 开始。  

例如，`$1` 对应第一列的单词，`$2` 对应第二列的单词，`$3` 对应第三列的单词，依此类推。

可以用 `$NF` 来获取拆分后的最后一列内容。

特别的，`$0` 获取到整行的内容，包括行首、或者行末的任意空白字符。

以 "This is a test string." 这一行进行举例，有如下的对应关系：
| 写法 | 对应的值 |
| --  | -- |
| $1  | This |
| $2  | is |
| $3  | a |
| $4  | test |
| $5  | string. |
| $NF | string. |
| $0  | This is a test string. |

# 使用 -F 选项指定分割字符
前面提到，`awk` 默认使用空格来拆分行内容为多个单词。如果想要基于其他字符来进行拆分，可以使用 `-F` 选项来指定分割字符。

GNU gawk 在线帮助手册对 `-F` 选项说明如下：
> **-F fs**  
> **--field-separator fs**  
> Set the FS variable to *fs*.

例如对 "clang/utils/analyzer/" 这样的目录路径来说，如果想要基于 `/` 进行拆分，以便获取各个目录名，就可以使用 `-F` 选项来指定分割字符为 `/`。

具体举例如下：
```bash
$ echo "clang/utils/analyzer/" | awk -F '/' '{print $1, $2}'
clang utils
$ echo "clang/utils/analyzer/" | awk -F '/' '{print "Last word is: " $NF}'
Last word is: 
```
可以看到，使用 `-F '/'` 指定分割字符后，所给内容会以 `/` 来进行拆分，拆分后的单词不包含 ‘/’ 这个字符。

由于所给内容的最后一个字符是 ‘/’，最后一列拆分后的内容为空，所以 `$NF` 的内容为空。

当需要基于特定字符分割行内容时，使用 `awk` 命令特别实用，`-F` 选项可以指定分割字符，然后用 `$number` 就能获取到第 *number* 列的内容，方便处理。

# print 语句
前面的例子都用了 `print` 语句来打印内容。

GNU gawk 在线帮助手册对 `print` 语句的说明如下：
> Use the print statement to produce output with simple, standardized formatting. 
> You specify only the strings or numbers to print, in a list separated by commas. 
> They are output, separated by single spaces, followed by a newline. The statement looks like this:  
> `print item1, item2, …`  
> The entire list of items may be optionally enclosed in parentheses.  
> The simple statement ‘print’ with no items is equivalent to ‘print $0’: it prints the entire current record.

即，`print` 语句打印所给字符串、或者数字的内容，不同内容之间要用逗号 ‘,' 隔开，但是打印出来的效果是用空格隔开。

经过测试，如果用其他字符隔开会不生效，打印的内容会连在一起。具体举例说明如下：
```bash
$ awk '/test/ {print $3, $5}' testawk
a string.
$ awk '/test/ {print $3 $5}' testawk
astring.
$ awk '/test/ {print $3_$5}' testawk
astring.
```
可以看到，在 `print` 后面写为 `$3, $5` 时，打印的两个字符串用空格隔开，而写为 ` $3 $5`、或者 `$3_$5`，打印的两个字符串直接连在一起，没有打印所给的空格、或者下划线 ‘_’。即，只能用逗号来隔开。

如果在 `print` 后面没有提供参数，默认相当于 `print $0`，会打印整行内容。  
如果没有提供任何 *action* 参数，连大括号 `{}` 都不提供，默认相当于 `{ print $0 }`。  
如果只提供大括号 `{}`，大括号里面没有内容，则是空操作，什么都不做。

具体举例如下：
```bash
$ awk '/test/ {print}' testawk
This is a test string.
$ awk '/test/' testawk
This is a test string.
$ awk '/test/ {}' testawk
```
可以看到，`awk '/test/ {print}' testawk` 命令在 `print` 后面提供参数，打印出整行内容。

`awk '/test/' testawk` 命令没有提供 *action* 参数，也是打印出整行内容。

`awk '/test/ {}' testawk` 命令提供了 *action* 参数，只是没有指定要做的操作，什么都没有打印。
