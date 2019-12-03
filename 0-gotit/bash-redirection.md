# 描述 bash 中重定向的使用

在 bash 中，执行一个命令之前，可以使用重定向操作符对该命令的输入、输出进行重定向，从其他文件获取输入，把命令输出写到其他文件。具体说明可以查看 man bash 的 *REDIRECTION* 小节。下面对部分关键内容进行举例说明。

# 重定向的概念
在 *REDIRECTION* 小节对重定向概念说明如下：
> Before  a command is executed, its input and output may be redirected using a special notation interpreted by the shell.  Redirection allows commands' file handles to be duplicated, opened, closed, made to refer to different files, and can change the files the command reads from and writes to.

> If the file descriptor number is omitted, and the first character of the redirection operator is <, the redirection refers to the standard input (file descriptor 0).  If the first character  of the redirection operator is >, the redirection refers to the standard output (file descriptor 1).

> Redirections using file descriptors greater than 9 should be used with care, as they may conflict with file descriptors the shell uses internally.

即，在执行一个命令之前，可以使用重定向操作符对该命令的输入、输出进行重定向，从其他文件获取输入，把命令输出写到其他文件。

在 Linux 中，打开文件后，会得到一个文件描述符（file descriptor），文件描述符的有效值是大于或等于 0 的整数，可以使用这个整数值来读写对应的文件。

重定向可以修改文件描述符对应的文件，从而在读写同一个文件描述符时，可以读写到其他文件。

重定向输入会把指定的文件描述符关联到以读模式打开的文件，那么读取指定文件描述符，就会读取文件内容。

重定向输出会把指定的文件描述符关联到以写模式打开的文件，那么写入内容到指定文件描述符，就会写入文件。

即，重定向前后会关联两个文件。在重定向之前，指定的文件描述符对应一个已经打开的文件。重定向之后，该文件描述符会对应另一个文件、或者对应另一个文件描述符，而另一个文件描述符也是对应另一个已经打开的文件。

当下面文件名用于重定向时，bash 会进行特殊处理：
- /dev/fd/fd：如果 *fd* 是一个已经打开的文件描述符整数值，则 /dev/fd/fd 文件会复制到文件描述符 *fd*
- /dev/stdin：复制到文件描述符 0，也可以写为 /dev/fd/0。文件描述符 0 一般对应标准输入
- /dev/stdout：复制到文件描述符 1，也可以写为 /dev/fd/1。文件描述符 1 一般对应标准输入
- /dev/stderr：复制到文件描述符 2，也可以写为 /dev/fd/2。文件描述符 2 一般对应标准错误输出

基于上面说明，可以使用 /dev/fd/5 来复制到文件描述符 5，文件描述符 5 必须对应一个打开的文件，否则会报错。也就是要有某个已打开文件的文件描述符是 5，/dev/fd/5 才能复制到文件描述符 5。

当使用大于 9 的文件描述符时，要特别小心，shell 自身可能也使用了某个大于 9 的文件描述符，会导致冲突。

# 重定向的先后顺序
在使用重定向，要注意重定向的先后顺序，这是很重要的点，*REDIRECTION* 小节的说明如下：
> Redirections are processed in the order they appear, from left to right.  
Note that the order of redirection is significant. For example, the command  
```
    ls > dirlist 2>&1
```
> directs both standard output and standard error to the file dirlist, while the command  
```
    ls 2>&1 > dirlist
````
> directs only the standard output to file dirlist, because the standard error was duplicated from the standard output before the standard output was redirected to dirlist.

即，当指定了多个重定向操作时，按照重定向出现的顺序，从左到右处理。

对 `ls > dirlist 2>&1` 命令来说，第一个 `>` 表示重定向 `ls` 命令的标准输出到 *dirlist* 文件，第二个 `2>&1` 表示复制标准错误输出到标准输出。由于标准输出已经被重定向到 *dirlist* 文件，所以 *dirlist* 文件会包含 `ls` 命令的标准输出和标准错误输出。

而 `ls 2>&1 > dirlist` 命令只重定向标准输出到 *dirlist* 文件，标准错误输出只会打印到终端。具体说明如下：
- 第一个 `2>&1` 表示复制标准错误输出的文件描述符 2 到标准输出的文件描述符 1，实际上是把标准错误输出写入到标准输出对应的文件。此时标准输出还没有重定向，会关联到终端，所以标准错误输出会写入到终端。
- 第二个 `>` 表示把标准输出重定向到 *dirlist* 文件，会把文件描述符 1 指向 *dirlist* 文件，不会影响文件描述符 2，标准错误输出的文件描述符 2 还是指向终端。所以， 标准错误输出没有重定向到 *dirlist* 文件。

具体举例测试如下：
```bash
$ ls not_exist 2>&1 > dirlist
ls: cannot access not_exist: No such file or directory
$ ls not_exist > dirlist 2>&1
$ cat dirlist
ls: cannot access not_exist: No such file or directory
```
在当前目录下，没有 *not_exist* 文件，那么 `ls not_exist` 会报错，提示找不到该文件。

如前面说明，`ls not_exist 2>&1 > dirlist` 命令不能把标准错误输出重定向到 *dirlist* 文件，所以报错信息直接打印在终端上。

`ls not_exist > dirlist 2>&1` 命令可以把标准错误输出重定向到 *dirlist* 文件，终端上没有看到报错信息。用 `cat dirlist` 命令输出 *dirlist* 文件内容，可以看到报错信息写入到了该文件。

# 使用 exec 命令对当前 shell 进行重定向
Bash 在执行命令时，会启动子 shell 来执行，此时的重定向只影响执行命令的子 shell，不影响当前 shell。

如果要对当前 shell 进行重定向，可以使用 bash 的 `exec` 内置命令。查看 man bash 里面对 `exec` 命令的说明如下：
> Note that the exec builtin command can make redirections take effect in the current shell.

> **exec [-cl] [-a name] [command [arguments]]**  
If command is specified, it replaces the shell. No new process is created. The arguments become the arguments to command. If command is not specified, any redirections take effect in the current shell, and the return status is 0. If there is a redirection error, the return status is 1.

即，当 `exec` 没有指定要执行的命令时，可以直接在当前 shell 进行重定向。例如，把当前的 shell 标准输入重定向到文件，不再从键盘读取输入。

下面具体举例说明如何使用 `exec` 命令来进行重定向。

- 重定向当前 shell 的标准输出到文件（如果终端自身不支持保存log功能，可以使用这个方法来把命令输出都保存到文件）：
```bash
$ exec 1>output.txt
$ ls
$ cat output.txt
cat: output.txt: input file is output file
$ exec 1>/dev/stdin
$ cat output.txt
testfile
```
在这个例子中，`exec 1>output.txt` 命令把当前 shell 的标准输出重定向到 *output.txt* 文件，那么标准输出不再关联到终端。执行 `ls` 命令，终端上看不到任何输出，`ls` 命令的输出结果被写入到 *output.txt* 文件。

此时，无法在当前 shell 上输出 *output.txt* 文件的内容。执行 `cat output.txt` 命令，提示输入文件是输出文件，会形成循环，不会在终端上输出 *output.txt* 文件内容。

此时要查看 *output.txt* 文件的内容，可以在另外的终端上查看，或者取消重定向当前 shell 的标准输出到 *output.txt* 文件。`exec 1>/dev/stdin` 命令把当前 shell 的标准输出重定向到 */dev/stdin* 文件，会关联到终端。执行 `cat output.txt` 命令，就能输出 *output.txt* 文件内容到终端上。

**注意**：这里要执行 `exec 1>/dev/stdin` 命令把对应标准输入的 */dev/stdin* 文件关联到文件描述符 1，才能重新输出到终端上。执行 `exec 1>/dev/stdout` 命令并不能重定向标准输出到终端上。

在重定向中使用 */dev/stdout* 文件，会复制到文件描述符 1，而文件描述符 1 之前已经重定向到 *output.txt* 文件，所以 `exec 1>/dev/stdout` 命令还是让文件描述符 1 关联到 *output*.txt 文件，并不是关联到终端。

在重定向中使用 */dev/stdin* 文件，会复制到文件描述符 0，而文件描述符 0 没有重定向，关联到终端。所以 `exec 1>/dev/stdin` 命令会让文件描述符 1 关联到终端。

- 重定向当前 shell 的标准输入到文件：
```bash
$ cat input.txt
date
sleep 2
$ exec 0<input.txt
$ date
2019年 11月 28日 星期四 13:14:11 CST
```
可以看到，用 `cat input.txt` 命令打印 *input.txt* 文件内容，里面有两行，分别是 `date` 命令和 `sleep 2` 命令。这个 `sleep` 命令用于延迟终端退出，否则执行后面命令，终端会很快关闭，终端窗口一闪而过。

执行 `exec 0<input.txt` 命令，会把当前 shell 的标准输入重定向到 *input.txt* 文件，则 shell 会开始逐行读取该文件内容，并把每行内容当作命令来执行。所以后面看到执行了 `date` 命令，这个命令并不是通过键盘手动输入。

自动执行 `date` 命令后，会再执行 `sleep 2` 命令，等秒 2 秒，接着就会退出当前 shell。

这是因为 bash shell 遇到 EOF 就会退出。例如打开一个 shell，输入 CTRL-D，就会退出 shell。重定向标准输入到 *input.txt* 文件后，当前 shell 读取完该文件内容，就会遇到 EOF，所以会退出 shell。

# 重定向输入
查看重定向输入（Redirecting Input）的说明如下：
> Redirection of input causes the file whose name results from the expansion of word to be opened for reading on file descriptor n, or the standard input (file descriptor 0) if n is not specified.  
The general format for redirecting input is:  
```
    [n]<word
```

即，`[n]<word` 用读模式打开 *word* 文件，并关联到文件描述符 *n* 上。如果没有提供文件描述符 *n*，默认关联到文件描述符 0 上，也就是标准输入。重定向输入后，从文件描述符 *n* 读取内容，会读取到所关联的 *word* 文件内容。

例如，重定向标准输入后，*word* 文件关联到文件描述符 0，被执行的命令读取标准输入，也就是读取文件描述符 0，从而读取到 *word* 文件的内容，不再从键盘进行输入。

重定向输入的例子说明如下：
```bash
$ cat < input.txt
date
sleep 2
$ exec 3< input.txt
$ cat /dev/fd/3
date
sleep 2
$ read -u 3 line
$ echo $line
date
```
在 `cat < input.txt` 命令中，执行 `cat` 命令且没有提供文件名参数，那么 `cat` 命令默认读取标准输入。`< input.txt` 表示把 *input.txt* 文件关联到文件描述符 0，也就是关联到被执行命令的标准输入。`cat` 命令读取标准输入时，读取的就是 *input.txt* 文件的内容。这只影响被执行命令的标准输入，不影响当前 shell 的标准输入。

执行 `exec 3< input.txt` 命令把 *input.txt* 文件关联到文件描述符 3 的输入。之后，读取文件描述符 3，读取的就是 *input.txt* 文件的内容。用 `cat /dev/fd/3` 命令读取文件描述符 3，获取到的内容确实和 *input.txt* 文件内容一致。

`read -u 3 line` 命令使用 `-u` 选项指定从文件描述符 3 读取一行，保存到 *line* 变量。打印 *line* 变量值，读取到的内容就是 *input.txt* 文件的第一行。

# 重定向输出
查看重定向输出（Redirecting Output）的说明如下：
> Redirection of output causes the file whose name results from the expansion of word to be opened for writing on file descriptor n, or the standard output (file descriptor 1) if n is not specified. If the file does not exist it is created; if it does exist it is truncated to zero size.  
The general format for redirecting output is:  
```
    [n]>word
```

即，`[n]>word` 用写模式打开 *word* 文件，并关联到文件描述符 *n* 上。如果没有提供文件描述符 *n*，默认关联到文件描述符 1 上，也就是标准输出。重定向输出后，往文件描述符 *n* 写入内容，会写入到所关联的 *word* 文件。

如果 *word* 文件不存在，会创建该文件。如果 *word* 文件已经存在，则把它的文件大小截断成 0，会丢弃原有的内容。

重定向标准输出是重定向最常见的用法之一。重定向输出的例子说明如下：
```bash
$ echo "redirection output" > output.txt
$ cat output.txt
redirection output
$ exec 5> output.txt
$ cat input.txt > /dev/fd/5
$ cat output.txt
date
sleep 2
```
`echo "redirection output" > output.txt` 命令把 `echo` 命令的标准输出重定向到 *output.txt* 文件，那么 `echo` 命令的输出结果就是写入到该文件。

用 `cat output.txt` 命令查看 *output.txt* 文件内容，可以看到重定向标准输出写入的字符串。

`exec 5> output.txt` 命令把 *output.txt* 文件关联到文件描述符 5 的输出。之后，往文件描述符 5 写入内容，就是写入到 *output.txt* 文件。

`cat input.txt > /dev/fd/5` 命令把标准输出重定向到文件描述符 5，那么所输出的 *input.txt* 文件内容会被写入到文件描述符 5。

用 `cat output.txt` 命令输出 *output.txt* 文件内容，已经不再是 "redirection output" 字符串，而是跟 *input.txt* 文件内容一致。

# 追加重定向输出
查看追加重定向输出（Appending Redirected Output）的说明如下：
> Redirection of output in this fashion causes the file whose name results from the expansion of word to be opened for appending on file descriptor n, or the standard output (file descriptor 1) if n is not specified. If the file does not exist it is created.
The general format for appending output is:  
```
    [n]>>word
```

即，`[n]>>word` 命令用追加写入模式打开 *word* 文件，并关联到文件描述符 *n* 上。如果没有提供文件描述符 *n*，默认关联到文件描述符 1 上，也就是标准输出。重定向输出后，往文件描述符 *n* 写入内容，会追加写入到所关联的 *word* 文件。

如果 *word* 文件不存在，会创建该文件。如果 *word* 文件已经存在，会把内容追加写入到文件末尾，不会丢弃原有的内容。

追加重定向输出的例子说明如下：
```bash
$ cat output.txt
date
sleep 2
$ echo "append" >> output.txt
$ cat output.txt
date
sleep 2
append
```
先用 `cat output.txt` 命令查看 *output.txt* 文件的内容。然后使用 `echo "append" >> output.txt` 命令追加重定向标准输出到 *output.txt* 文件。

再次查看 *output.txt* 文件，原有的内容还在，并在文件末尾追加了写入的 "append" 字符串。

当重定向的输出文件不存在时，`>` 和 `>>` 都会新建该文件。当输出文件已经存在时，`>` 会清空该文件的内容，然后再写入新的内容（如果有的话）。而 `>>` 会将新写入的内容追加到该文件的末尾，文件原来的内容还会保留。

# 同时重定向标准输出和标准错误输出
查看同时重定向标准输出和标准错误输出（Redirecting Standard Output and Standard Error）的说明如下：
> This construct allows both the standard output (file descriptor 1) and the standard error output (file descriptor 2) to be redirected to the file whose name is the expansion of word.  
There are two formats for redirecting standard output and standard error:  
```
    &>word
```
and  
```
    >&word
```
> Of the two forms, the first is preferred. This is semantically equivalent to  
```
    >word 2>&1
```
> When using the second form, word may not expand to a number or -. If it does, other redirection operators apply (see Duplicating File Descriptors below) for compatibility reasons.

即，可以使用 `&>word`、或者 `>&word` 来同时重定向标准输出和标准错误输出。

建议采用 `&>word` 这个写法。在语义上，这个写法等同于 `>word 2>&1`。`2>&1` 这个写法表示复制文件描述符。后面会具体说明。

如果使用 `>&word` 这种形式来同时重定向标准输出和标准错误输出，那么 *word* 文件名不能是数字，也不能是连字符 -。因为这种写法是复制文件描述符，而复制文件描述符时，数字和 - 具有特殊含义，不会当成文件名处理。

当重定向标准输出到文件后，如果命令执行出错，错误信息会打印到标准错误输出，会在终端上看到这些打印。如果确实需要把标准错误输出也重定向到文件，就可以使用 `&>word` 来同时重定向标准输出和标准错误输出。这里不再举例。

# 同时追加重定向标准输出和标准错误输出
查看同时追加重定向标准输出和标准错误输出（Appending Standard Output and Standard Error）的说明如下：
> This construct allows both the standard output (file descriptor 1) and the standard error output (file descriptor 2) to the appended to the file whose name is the expansion of word.  
The format for appending standard output and standard error is:  
```
    &>>word
```
> This is semantically equivalent to  
```
    >>word 2>&1
```

即，可以使用 `&>>word` 来同时追加重定向标准输出和标准错误输出。这个命令在语义上，等同于 `>>word 2>&1`。

# Here Documents
前面说明的重定向输入需要提供文件名，会有一个单独的文件。编写 shell 脚本时，如果需要进行重定向输入，这个脚本就会依赖一个外部的文件，增加耦合。

我们可以使用 *Here Documents* 机制来重定向标准输入为指定的字符串，不需要提供外部文件名。查看 *Here Documents* 的说明如下：
> This type of redirection instructs the shell to read input from the current source until a line containing only delimiter (with no trailing blanks) is seen. All of the lines read up to that point are then used as the standard input for a command. The format of here-documents is:
```
    <<[-]word
        here-document
    delimiter
```
> No parameter expansion, command substitution, arithmetic expansion, or pathname expansion is performed on word. If any characters in word are quoted, the delimiter is the result of quote removal on word, and the lines in the here-document are not expanded. If word is unquoted, all lines of the here-document are subjected to parameter expansion, command substitution, and arithmetic expansion. In the latter case, the character sequence \\<newline\> is ignored, and \ must be used to quote the characters \, $, and \`.  
If the redirection operator is <<-, then all leading tab characters are stripped from input lines and the line containing delimiter. This allows here-documents within shell scripts to be indented in a natural fashion.

即，可以使用 here-documents 格式来重定向标准输入：
- *word* 指定一个字符串。如果字符串带有空格，需要用引号括起来。
- *here-document* 内容会被重定向到标准输入。当某一行内容完全等于 *word* 指定的字符串时（行首、行末的空白字符也会用来比较），则停止重定向。
- *delimiter* 对应 *word* 指定的字符串，会去掉 *word* 中的引号。所给的 *delimiter* 不会被重定向到标准输入。

这里的 *word* 字符串不会进行参数扩展、命令替换、算法括号、或路径名扩展，意味着不能用 `$var` 的形式来获取 *var* 变量值。如果 *word* 写为 `$var`，对应的 *delimiter* 字符串就是 *$var*。

当 *word* 字符串的任意字符被引号括起来时，对应的 *delimiter* 字符串不会包含这些引号。而且中间的  *here-document* 字符串不会进行扩展。例如，不能在 *here-document* 中用 `$var` 的形式来获取 *var* 变量值。

当 *word* 字符串中没有引号时，中间的 *here-document* 字符串可以进行参数扩展、命令替换、算法括号，不进行路径名扩展。

对 `<<word` 这个写法来说，中间 *here-document* 字符串的任意字符都会被保留，包括行首、行末的空白字符。而写为 `<<-word` 时，中间 *here-document* 字符串行首的 tab 字符会被去掉，行首的空格还是会保留。

下面举例说明各种情况的 here-documents 格式写法。

- 在 here-document 中不进行扩展

假设有一个 `testhere.sh` 脚本文件，内容如下：
```bash
#!/bin/bash

cat -A <<"The end"
This is a here-document.
    The end
The end  
$((3+7))
The end
```
该脚本执行 `cat -A` 命令，`-A` 选项会在输出的行末打印一个 `$` 字符，以便看到行末结尾。这里用 `<<"The end"` 指定 here-documents 类型的重定向输入，`cat` 命令会从 here-documents 获取标准输入，直到读取 "The end" 字符串为止。

在 `<<` 后面的 "The end" 字符串带有空格，要用引号括起来。如果不加引号，会执行报错。

在 `$((3+7))` 上一行的 "The end  " 字符串后面有两个空格。在测试的时候要注意在行末加上空格。

执行 `testhere.sh` 脚本，打印结果如下：
```bash
$ ./testhere.sh
This is a here-document.$
    The end$
The end  $
$((3+7))$
```
可以看到，here-documents 的第二行 "    The end"，在行首带有空格，这一行不完全匹配 "The end"，没有停止重定向。

第三行内容是 "The end  "，在行末有两个空格，也是不完全匹配 "The end"，没有停止重定向。

第四行内容是 "$((3+7))"，这是一个算术扩展表达式。但是这里的 *word* 参数值是 "The end"，带有引号，不会进行算术扩展，会原样输出 "$((3+7))" 字符串。

第五行内容是 "The end"，完全匹配 "The end"，停止重定向。

停止重定向后，`cat -A` 命令会打印从标准输入读取到的所有内容，并在行末打印 `$` 字符。

最后一行的 "The end" 字符串没有被重定向输入到 `cat` 命令。

- 在 here-document 中进行扩展

前面提到，如果 `<<word` 的 *word* 没有包含引号，则 *here-document* 中的内容可以进行参数扩展、命令替换、算术扩展，不进行路径名扩展。修改 `testhere.sh` 脚本为下面的内容，测试这种情况：
```bash
#!/bin/bash

number="1234567"
cat <<end
number = $number
$(date)
$((3+7))
test*
end
```
这里的停止重定向字符串是 *end*，没有加引号。里面的 *here-document* 用 `$number` 获取 *number* 变量值。用 `$(date)` 执行 `date` 命令并获取改命令的输出，也就是命令替换。用 `$((3+7))` 进行算术扩展。

执行修改后的 `testhere.sh` 脚本，打印结果如下：
```bash
$ ./testhere.sh
number = 1234567
2019年 11月 28日 星期四 16:38:36 CST
10
test*
```
可以看到，打印结果里面确实获取到了 *number* 变量值，打印了 `date` 命令的执行结果，并进行算术扩展。但是 `test*` 没有进行路径名扩展，没有扩展成当前目录下以 "test" 开头的文件名。

- word 参数不进行扩展

在 `<<word` 中，*word* 本身不进行参数扩展、命令替换、算法括号、或路径名扩展，所给的字符串会保持不变。无法通过获取变量值的方式来指定停止重定向的字符串。

修改 `testhere.sh` 脚本内容为下面的内容：
```bash
#!/bin/bash

number="12345"
cat <<$name
What is the name?
12345
$name
```
这里指定停止重定向的字符串为 `$name`，*name* 变量值是 "12345"。在 here-document 中提供了 "12345" 这一行，之后是 `$name` 这一行。

执行修改后的 `testhere.sh` 脚本，打印结果如下：
```bash
$ ./testhere.sh
What is the name?
12345
```
可以看到，输出结果里面包含了 "12345" 这一行，说明这一行没有停止重定向。`<<$name` 并不会获取 *name* 变量值来作为停止重定向的字符串，而是保持停止重定向的字符串为 `$name` 不变。

# Here Strings
前面说明的 here-documents 可以重定向多行到标准输入。如果只需要重定向一行，也可以使用 *Here Strings*。查看 *Here Strings* 的说明如下：
> A variant of here documents, the format is:  
```
    <<<word
```
> The word undergoes brace expansion, tilde expansion, parameter and variable expansion, command substitution, arithmetic expansion, and quote removal. Pathname expansion and word splitting are not performed. The result is supplied as a single string to the command on its standard input.

即，here-strings 会把所给的 *word* 重定向到命令的标准输入，*word* 可以进行扩展。

跟 here-documents 不同，here-strings 的 *word* 无论是否加引号，都会进行参数扩展、命令替换、算术扩展、大括号扩展、波浪号扩展，并移除引号。但是不进行路径名扩展和单词拆分。

如果 *word* 带有空格，需要用引号括起来，否则可能会报错。对 `<<<here strings` 这种写法来说，其实是 `<<<`、`here`、`strings` 三个参数，如果被执行命令不能处理这三个参数，就会报错。如果想要把 `here strings` 当成一个参数，需要用引号括起来，例如 `<<<"here strings"`。

具体举例说明如下：
```bash
$ number=1 2 3 4 5
$ grep 2 <<<$number
12345
$ grep t <<<test string
grep: string: No such file or directory
```
这里的 `<<<$number` 会获取 *number* 变量值来重定向到标准输入。`grep` 命令没有提供文件名参数时，默认读取标准输入，经过重定向，读取到 *number* 变量值。

在 `grep t <<<test string` 命令中，`test string` 中带有空格，没有用引号括起来，那么 `<<<test` 是 here-strings 类型的重定向输入，后面的 *string* 是另外的参数，会被 `grep` 命令当成文件名处理。当前目录下没有该文件，执行报错。

在 `<word`、`<<word`、`<<<word` 这三种形式中，*word* 的类型有如下差异：
- 在 `<word` 中，*word* 是文件名，读取文件内容作为重定向输入的来源。即使用引号把 *word* 括起来，也还是当成文件名，不会当成字符串处理。
- 在 `<<word` 中，*word* 是字符串，不会被当成文件名处理，也不会进行扩展。
- 在 `<<<word` 中，*word* 是字符串，不会被当成文件名处理，会进行扩展。具体扩展类型如前面说明。

# 复制文件描述符
查看复制文件描述符（Duplicating File Descriptors）的说明如下：
> The redirection operator  
```
    [n]<&word
```
> is used to duplicate input file descriptors. If word expands to one or more digits, the file descriptor
denoted by n is made to be a copy of that file descriptor. If the digits in word do not specify a file descriptor open for input, a redirection error occurs. If word evaluates to -, file descriptor n is closed. If n is not specified, the standard input (file descriptor 0) is used.  

> The operator  
```
    [n]>&word
```
> is used similarly to duplicate output file descriptors. If n is not specified, the standard output (file descriptor 1) is used. If the digits in word do not specify a file descriptor open for output, a redirection error occurs. If word evaluates to -, file descriptor n is closed. As a special case, if n is omitted, and word does not expand to one or more digits or -, the standard output and standard error are redirected as described previously.

即，`[n]<&word` 把文件描述符 *n* 复制到文件描述符 *word*。如果文件描述符 *word* 没有对应以写模式打开的文件，则重定向报错。如果 *word* 的值是连字符 -，则会关闭文件描述符 *n*。如果没有提供文件描述符 *n*，默认会使用文件描述符 0，也就是标准输入。

类似的，`[n]>&word` 把文件描述符 *n* 复制到文件描述符 *word*。如果文件描述符 *word* 没有对应以读模式打开的文件，则重定向报错。如果 *word* 的值是连字符 -，则会关闭文件描述符 *n*。如果没有提供文件描述符 *n*，默认会使用文件描述符 1，也就是标准输出。

有一种特别情况是，当 `[n]>&word` 中的 *word* 扩展结果不是数字、也不是连字符 - 时，*word* 会被当成文件名处理，也就是前面说明的“同时重定向标准输出和标准错误输出”这种场景。

这个复制文件描述符的行为类似于 Linux 的 dup() 系统调用函数 。这两个文件描述符会指向同一个文件表（file table），共享文件偏移指针，所以它们写入的内容是交错开的，不会发生覆盖的现象。

在编译大型项目代码时，就经常用到 `2>&1` 这个写法。例如可以使用下面命令全编译 Android 源码：
```bash
make -j16 2>&1 | tee build_android.log
```
这个命令使用 `2>&1`，把标准错误输入复制到标准输出，那么写入到标准错误输出的内容也会写入到标准输出，然后通过管道 `|` 把标准输出重定向给下一个命令。

当使用管道 `|`来重定向前一个命令的输出到后一个命令的输入时，只会重定向标准输出，不会重定向标准错误输出。如果想重定向标准错误输出，可以写为 `2>&1 |`，这种写法会先将标准错误输出重定向到标准输出上，然后再一起输出到管道上。

实际上，更简单的写法是 `|&`。查看 man bash 的 *Pipelines* 小节提到了这一点，具体描述如下：
> If |& is used, the standard error of command is connected to command2's standard input through the pipe; it is shorthand for 2>&1 |. This implicit redirection of the standard error is performed after any redirections specified by the command.

# 移动文件描述符
查看移动文件描述符（Moving File Descriptors）的说明如下：
> The redirection operator  
```
    [n]<&digit-
```
moves the file descriptor digit to file descriptor n, or the standard input (file descriptor 0) if n is not
specified. digit is closed after being duplicated to n.

> Similarly, the redirection operator  
```
    [n]>&digit-
```
moves the file descriptor digit to file descriptor n, or the standard output (file descriptor 1) if n is not specified.

即，`[n]<&digit-` 把文件描述符 *digit* 复制到文件描述符 *n*，然后关闭文件描述符 *digit*。后面的连字符 - 必须提供。如果没有提供文件描述符 *n*，默认使用文件描述符 0，也就是标准输入。

类似的，`[n]>&digit-` 把文件描述符  *digit* 复制到文件描述符 *n*，然后关闭文件描述符 *digit*。后面的连字符 - 必须提供。如果没有提供文件描述符 *n*，默认使用文件描述符 1，也就是标准输出。

这个移动文件描述符的行为和 Linux 的 dup2() 系统调用函数有所区别，dup2() 函数将老的文件描述符（后面称之为 *oldfd*）复制到新的文件描述符（后面称之为 *newfd*）。如果 *newfd* 之前是打开的，会先关闭 *newfd*，但是这个函数不会关闭 *oldfd*。而 `[n]<&digit-`、`[n]>&digit-` 会在复制文件描述符之后，关闭 *digit* 对应的文件描述符。

**注意**：在 `[n]<&digit-`、`[n]>&digit-` 中，如果省略了 *digit*，就变成 `[n]<&-`、`[n]>&-`。这是前面“复制文件描述符”的写法，会关闭文件描述符 *n*。

# 以读写模式打开文件描述符
前面说明的文件描述符都对应到一个已经打开的文件。例如，`n>word` 是把 *word* 文件关联到已经打开的文件描述符 *n* 上。可以使用下面的方式来打开一个新的文件描述符。

查看以读写模式打开文件描述符（Opening File Descriptors for Reading and Writing）的说明如下：
> The redirection operator  
```
    [n]<>word
```
causes the file whose name is the expansion of word to be opened for both reading and writing on file
descriptor n, or on file descriptor 0 if n is not specified. If the file does not exist, it is created.

即，`[n]<>word` 会以读写模式打开 *word* 文件，且打开后的文件描述符为 *n*。如果没有文件描述符 *n*，默认会打开到文件描述符 0 上。

如果 *word* 文件不存在，会创建该文件。如果 *word* 文件已经存在，且往文件描述符 *n* 写入内容，则会把清空 *word* 文件原有的内容，然后写入新的内容。

具体举例说明如下：
```bash
$ cat output.txt
date
sleep 2
$ echo "new string" 3<> output.txt > /dev/fd/3
$ cat output.txt
new string
```
这里先用 `cat output.txt` 命令查看 *output.txt* 文件内容，说明该文件存在，且自身内容不为空。

在 `echo "new string" 3<> output.txt > /dev/fd/3` 命令里面，`3<> output.txt` 以读写模式打开 *output.txt* 文件，并关联到文件描述符 3 上，`> /dev/fd/3` 表示把 `echo` 的输出结果重定向到 /dev/fd/3 文件，也就是重定向到文件描述符 3，那么会写入到 *output.txt* 文件。

之后再次用 `cat output.txt` 命令查看 *output.txt* 文件内容，可见文件原有内容已经丢失，变成 `echo` 命令输出的字符串。
