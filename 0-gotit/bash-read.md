# 记录 bash read 内置命令的相关笔记

# 使用 bash 的 read 命令模拟一个简易的 shell 效果，并实现一个小游戏
在 bash 里面可以使用 `read` 内置命令来读取用户输入，当在 `while` 循环中不断调用 `read` 命令，并打印一些提示字符，如 `$`、`#`、`>` 等，就可以不断接收用户输入，然后执行一些自定义的命令，看起来就像是一个简易的 shell。

下面主要是介绍 `read` 命令的常见用法，用来逐步实现一个简易的 shell 效果。

## read 命令介绍
在 bash 中，`read` 内置命令可以读取用户的一行输入，并对输入内容进行单词拆分，依次赋值给指定的变量。查看 help read 的说明如下：
> **read: read [-ers] [-a array] [-d delim] [-i text] [-n nchars] [-N nchars] [-p prompt] [-t timeout] [-u fd] [name ...]**  
Read a line from the standard input and split it into fields.

> Reads a single line from the standard input, or from file descriptor FD if the -u option is supplied. The line is split into fields as with word splitting, and the first word is assigned to the first NAME, the second word to the second NAME, and so on, with any leftover words assigned to the last NAME.  Only the characters found in $IFS are recognized as word delimiters.  
If no NAMEs are supplied, the line read is stored in the REPLY variable.

> Exit Status:  
The return code is zero, unless end-of-file is encountered, read times out (in which case it's greater than 128), a variable assignment error occurs, or an invalid file descriptor is supplied as the argument to -u.

即，`read` 命令从标准输入读取到一行，每行内容以换行符结尾，但是读取到的内容不包含行末的换行符。

对于读取到的内容，会按照 bash 的 `IFS` 全局变量保存的分割字符把输入行拆分成多个单词，把这些词依次赋值给提供的变量，如果所给的变量个数少于分割后的单词数，最后一个变量被赋值为剩余的所有单词。举例说明如下：
```bash
$ read first second third last
1 2 3 4 5 678
$ echo $first, $second, $third, $last
1, 2, 3, 4 5 678
$ read input_line
This is a test input line.
$ echo $input_line
This is a test input line.
```
可以看到，默认基于空格来拆分单词，所给的第一个 *first* 变量被赋值为拆分后的第一个单词，第二个 *second* 变量被赋值为拆分后的第二个单词，第三个 *third* 变量被赋值为拆分后的第三个单词，最后一个 *last* 变量被赋值为第三个单词后的所有单词。

显然，只提供一个变量时，整个输入行都会赋值给这个变量，打印的 *input_line* 变量值可以看到这一点。

## 使用 -p 选项指定提示字符串
执行 `read` 命令时，默认不打印提示字符串，如果想要引导用户输入特定的内容，可以使用 `-p` 选项来指定提示字符串。查看 help read 对该选项的说明如下：
> **-p prompt**  
output the string PROMPT without a trailing newline before attempting to read

即，在 `-p` 选项后面跟着一个 *prompt* 字符串，在读取用户输入之前，会先打印这个 *prompt* 字符串，以作提示。这个提示字符串后面不会换行，会跟用户的输入在同一行。具体举例说明如下：
```bash
$ read -p "Please input your mood today: " mood
Please input your mood today: happy
$ echo $mood
happy
```
在执行所给的 `read` 命令时，会先打印 “Please input your mood today: ”字符串，没有换行，等待用户输入。上面的 “happy” 是输入的字符串，会被赋值给指定 *mood* 变量。

**当使用 `while` 循环不断调用 `read` 命令，且用 -p 选项指定 `$` 字符时，看起来就像是一个简易的 shell，可以根据用户输入做一些处理，也可以指定其他字符，如 `>`、`#` 等**。

假设有一个 `tinyshell.sh` 脚本，内容如下：
```bash
#!/bin/bash

while read -p "tinyshell> " input; do
    if [ "$input" == "l" ]; then
        ls
    elif [ "$input" == "quit" ]; then
        break
    else
        echo "Unknown input: $input"
    fi
done
```
该脚本在 `while` 循环中不断调用 `read` 命令，使用 `-p` 选项设置提示字符串为 “tinyshell> ”，DOS 命令行的提示字符就是 `>`。具体执行结果如下：
```bash
$ ./tinyshell.sh
tinyshell> l
tinyshell.sh
tinyshell> d
Unknown input: d
tinyshell> quit
$
```
在执行时，先打印出 “tinyshell> ” 提示字符串，等待用户输入。

这里输入 *l* 字符，脚本会执行 `ls` 命令。

输入 *quit* 字符串，会退出 while 循环，终止执行。

输入其他内容则提示 “Unknown input: ”。

在实际工作中，对这个例子进行扩展，就能模拟一个简易的 shell 效果，可以输入自定义的命令简写，来执行一长串的命令，非常方便

例如进行 Android 系统开发，经常用到 adb shell 的各种命令，有些命令带有很多参数，比较难输入，仿照这个例子，可以只输入一个字符、或者几个字符，然后执行对应的 adb shell 命令，减少很多输入。

## 使用 -e 选项在交互式 shell 中获取到历史命令
前面提到在 `while` 循环中不断执行 `read -p` 命令，可以模拟一个简易的 shell 效果。

实际使用时遇到一个问题，那就是输入上光标键，会打印 `^[[A`，输入下光标键，会打印 `^[[B`，不能像 bash 那样通过上下光标键显示执行过的历史命令。

具体执行结果如下：
```bash
$ ./tinyshell.sh
tinyshell> ^[[A^[[B
```
这里打印的 `^[[A` 是输入上光标键所显示，`^[[B` 是输入下光标键所显示。

如果想要在执行 `read` 命令时，可以通过上下光标键来显示历史命令，需要加上 `-e` 选项，且在交互式 shell 中运行。查看 help read 对 `-e` 选项说明如下：
> **-e**  
use Readline to obtain the line in an interactive shell

即，在交互式 shell 中，`read -e` 会使用 *readline* 库来获取输入，*readline* 库支持很多强大的功能，上下光标键能够显示历史命令，就是因为默认把上下光标键绑定到 *readline* 库获取上下历史命令的函数，可以执行下面的命令来进行确认：
```bash
$ bind -p | grep -E "previous\-history|next\-history"
"\C-n": next-history
"\eOB": next-history
"\e[B": next-history
"\C-p": previous-history
"\eOA": previous-history
"\e[A": previous-history
```
这里的 "\e[A" 就是对应上光标键，绑定到 *previous-history* 功能，也就是显示上一个历史命令。"\e[B" 对应下光标键，绑定到 *next_history* 功能，也就是显示下一个历史命令。

上面的 "\C-p" 对应 CTRL-p，也就是同时按下 CTRL 键和 p 键，可以看到它也对应上一个历史命令。"\C-n" 对应 CTRL-n，对应下一个历史命令。

一般来说，直接在 bash shell 中执行 `read` 命令，就处于交互式 shell（interactive shell）之下。举例如下：
```bash
$ read
^[[A^[[B
$ read -e
read -e
```
这个例子先是直接执行 `read` 命令，然后输入上光标键，会打印 `^[[A`，然后输入下光标键，又打印 `^[[B`。

之后，执行 `read -e` 命令，输入上光标键，会自动填充上一个历史命令，也就是正在执行的 “read -e” 命令。

**注意**：这个 `-e` 选项只在交互式 shell 中才会生效。一般来说，shell 脚本是在非交互式 shell 中执行，当在 shell 脚本中使用 `read -e` 时，输入上下光标键，不会再打印 `^[[A`、`^[[B`，也不会显示历史命令，而是什么都没有打印。

这跟 `read -p` 的效果有所不同，`read -p` 可以在输入上下光标键时，打印出 `^[[A`、`^[[B`。

## 让 shell 脚本运行在交互模式下
我们可以使用下面几个方法来让 shell 脚本在交互模式下执行。

### 通过 bash -i 选项指定运行在交互模式下
在 bash 中，可以使用 bash 的 `-i` 选项来让 shell 脚本在交互模式下运行。查看 man bash 对 `-i` 选项说明如下：
> **-i**  
If the -i option is present, the shell is interactive.

即，在 shell 脚本开头，把脚本的解释器写为 `#/bin/bash -i`，执行这个 shell 脚本时，就会运行在交互模式下。把前面的 `tinyshell.sh` 脚本修改成下面的内容来进行验证：
```bash
#!/bin/bash -i

while read -ep "tinyshell> " input; do
    if [ "$input" == "l" ]; then
        ls
    elif [ "$input" == "quit" ]; then
        break
    else
        echo "Unknown input: $input"
   fi
done
```
相比于之前的脚本，这次的改动点是：
- 把之前的 `#!/bin/bash` 改成 `#!/bin/bash -i`，添加 `-i` 选项指定运行在交互模式下。
- 把 `read -p` 改成 `read -ep`，添加 `-e` 选项指定在交互模式下用 *readline* 库读取用户输入。

执行修改后的脚本，结果如下：
```bash
$ ./tinyshell.sh
tinyshell> #!/bin/bash -i
Unknown input: #!/bin/bash -i
tinyshell>
```
上面的在 “tinyshell>” 之后显示的 “#!/bin/bash -i” 是输入两次上光标键后显示出来的历史命令，第一个输入光标键会显示脚本里面的整个 while 循环语句。

**注意**：这个脚本在 Linux Debian 系统、 Linux Ubuntu 系统本地测试都能生效，可以通过上下光标键显示出历史命令。但是在 Windows 下通过 ssh 远程登录到 Ubuntu 系统，在远程 Ununtu 系统下执行这个脚本不生效，即使把脚本开头的解释器写为 `#!/bin/bash -i`，`read -e` 命令也无法通过上下光标键读取到历史命令，输入上下光标键，什么都没有打印出来。在 Mac OSX 系统下测试也不生效。这几种情况都是在 login shell 下运行，查看 *readline* 库的配置文件也没有看到异常，目前原因不明。可以改成用 `source` 命令执行脚本来避免这个异常。具体如后面说明所示。

### 通过 source 命令执行 shell 脚本
通过 bash 的 `source` 内置命令执行 shell 脚本时，这个脚本运行在当前 bash shell 下，而不是启动一个子 shell 来执行脚本。由于当前 bash shell 是交互式，运行在该 bash shell 下的脚本也是交互式。

此时，脚本开头的解释器不需要加 `-i` 选项，但 `read` 命令还是要加 `-e` 选项来指定用 *readline* 库读取输入。修改 `tinyshell.sh` 脚本内容如下：
```bash
#!/bin/bash

while read -ep "tinyshell> " input; do
    if [ "$input" == "l" ]; then
        ls
    elif [ "$input" == "quit" ]; then
        break
    else
        bash -c "${input}"
    fi
done
```
这个脚本的改动点是：
- 脚本开头的解释器写为 `#!/bin/bash`，不需要加 `-i` 选项。
- `read` 命令加了 `-e` 选项。
- 对于不识别的输入，使用 `bash -c` 来执行所输入的内容，这样就可以执行外部的命令。

使用 `source` 命令执行这个脚本的结果如下：
```bash
$ source tinyshell.sh
tinyshell> l
tinyshell.sh
tinyshell> echo "This is a tinyshell."
This is a tinyshell.
tinyshell> source tinyshell.sh
tinyshell> quit
tinyshell> quit
$
```
在执行的时候，先是手动输入 *l* 字符，该脚本会相应执行 `ls` 命令。

然后手动输入 *echo "This is a tinyshell."*，该脚本使用 `bash -c` 来执行这个命令，打印出 *This is a tinyshell.*。

接着输入上光标键，出现上一个历史命令，显示当前正在执行的 `source tinyshell.sh` 命令，回车之后会再次执行这个脚本，可以看到，需要手动输入两次 *quit*，才退出这两次执行。

上面提到，在 Windows 下通过 ssh 远程登录到 Ubuntu 系统，在远程 Ununtu 系统下，使用 bash 的 `-i` 选项来执行脚本，`read -e` 也不能通过上下光标键来获取历史命令。此时，通过 `source` 命令执行脚本，`read -e` 命令能通过上下光标键来获取历史命令。

即，通过 bash 的 `-i` 选项来执行脚本，可能会受到子 shell 环境配置的影响，导致 `read -e` 命令不能通过上下光标键来获取历史。

而通过 `source` 命令来执行脚本，直接运行在当前 bash shell 下，可以避免子 shell 环境配置的影响，兼容性较强。

**注意**：通过 `source` 命令执行脚本时，脚本内不能执行 `exit` 命令，否则不但会退出脚本执行，还会退出所在的 bash shell。

### 把脚本自身执行的命令添加到当前历史记录
在前面的脚本代码中，无论是通过 bash 的 `-i` 选项来执行脚本，还是通过 `source` 命令来执行脚本，这两种方式有一个共同的问题：虽然可以使用上下光标键查找历史命令，但找不到脚本自身所执行的命令。

例如输入 *l* 字符，`tinyshell.sh` 脚本执行了 `ls` 命令，通过上光标键还是只能查找到执行脚本之前的历史命令，查找不到输入的 *l* 字符，也找不到脚本所执行的 `ls` 命令，就像是这个脚本的命令没有加入到历史记录。

如果想在执行脚本时，可以使用上下光标键查找到脚本自身执行的命令，可以使用 `history -s` 命令。  
在上面 while 循环的末尾添加下面的语句，新增的代码前面用 `+` 来标识：
```bash
    else
        bash -c "${input}"
    fi
+   history -s "${input}"
done
```
添加 `history -s "${input}"` 语句后，就能通过上下光标键找到 *input* 变量指定的命令。  
例如输入 *l* 字符，`tinyshell.sh` 脚本执行了 `ls` 命令。  
而 *input* 变量保存的是 *l* 字符，能够通过上下光标键找到 *l* 命令，找不到 `ls` 命令。

查看 man bash 对 `history` 内置命令的 `-s` 选项说明如下：
> history -s arg [arg ...]  
> **-s**: Store the args in the history list as a single entry.

即，`history -s` 命令把所给的参数添加到当前历史记录中。  
后续通过上下光标键获取历史命令，就可以获取到新添加的命令。

## 从文件中逐行读取命令并执行
既然是模拟一个简易的 shell 效果，当然要具有执行脚本文件的能力。我们可以通过重定向用 `read` 命令逐行读取文件内容，然后执行每一行的命令。一段示例代码如下：
```bash
while read line; do
    echo $line
done < filename
```
这段代码会逐行读取 *fliename* 这个文件的内容，读取到最后一行 (EOF) 就会退出 while 循环。

参考这段代码，对 `tinyshell.sh` 脚本修改如下：
```bash
#!/bin/bash -i

if [ $# -ne 0 ]; then
    filename="$1"
else
    filename="/dev/stdin"
fi

while read -ep "tinyshell> " input; do
    if [ "$input" == "l" ]; then
        ls
    elif [ "$input" == "quit" ]; then
        break
    else
        bash -c "$input"
    fi
done < "$filename"
```
这个脚本使用 `$#` 获取到传入脚本的参数个数，如果不等于 0，那么用 `$1` 获取到第一个参数值，赋值给 *filename* 变量，这个参数值用于指定要执行的脚本文件名。

如果没有提供任何参数，那么将 *filename* 赋值为 `/dev/stdin`，对应标准输入。

注意不能将 *filename* 赋值为空字符串，否则重定向会提示文件找不到。重定向空字符串并不表示获取标准输入。

为了避免所给文件名带有空格导致异常，要用双引号把 `$filename` 括起来。

这里采用 bash 的 `-i` 选项来执行该脚本，所以要在 Linux 本地系统进行测试。如果想要用 `source` 命令来执行，需要做一些修改，包括调整 `$#`、`$1` 的使用。这里不再提供使用 `source` 命令来执行的例子。

执行修改后的脚本，结果如下：
```bash
$ ./tinyshell.sh
tinyshell> l
shfile  tinyshell.sh
tinyshell> quit
$ cat shfile
l
echo "This is in a test file."
whoami
$ ./tinyshell.sh shfile
shfile  tinyshell.sh
This is in a test file.
shy
```
这个例子先执行 `./tinyshell.sh` 命令，不带参数时，脚本指定从 `/dev/stdin` 获取输入，可以正常获取到标准输入。

输入的是 *l* 字符，脚本执行 `ls` 命令，列出当前目录下的文件，可以看到有一个 *shfile* 文件。

这个 *shfile* 文件就是要被执行的脚本文件，用 `cat shfile` 命令列出它的内容，只有三行，每一行都是要执行的命令。

然后执行 `./tinyshell.sh shfile` 命令，从打印结果来看，确实逐行读取到 *shfile* 文件的内容，并执行每一行的命令。

Bash 的 `whoami` 命令会打印当前登录的用户名，这里打印出来是 *shy*。

即，使用修改后的 `./tinyshell.sh` 来模拟 shell 效果，具有执行脚本文件的能力，虽然功能还很弱，但基本框架已经搭好，后续可以根据实际需求进行扩展完善。

**注意**：使用上面的 “while read” 循环来逐行读取文件内容，有一个隐晦的异常：如果所给文件的最后一行不是以换行符结尾时，那么这个 “while read” 循环会处理不到最后一行。具体原因说明如下。

如果文件的最后一行以换行符结尾，那么 `read` 命令遇到换行符，会暂停获取输入，并把之前读取到的内容赋值给指定的变量，命令自身的返回值是 0，`while` 命令对这个值进行评估，0 对应 true，执行循环里面的语句，处理最后一行的内容。

然后再次执行 `read` 命令，遇到文件结尾 (EOF)，`read` 命令返回非 0 值，对应 false，退出 while 循环。这是正常的流程。

如果文件的最后一行不是以换行符结尾，`read` 读取完这一行内容，遇到了 EOF，会把读取到的内容赋值给指定的变量，命令自身返回值是非 0 值（使用 `$?` 获取这个返回值，遇到 EOF 应该是返回 1），`while` 命令对这个非 0 值进行评估，就会退出 while 循环，没有执行循环里面的语句。

即，这种情况下，虽然 `read` 命令还是会把最后一行内容赋值给指定变量，但是退出了 while 循环，没有执行循环里面的语句，没有机会处理这一行的内容，除非在 while 循环外面再处理一次，但会造成代码冗余。

下面修改 *shfile* 文件的内容，最后一行不以换行符结尾，然后执行 `./tinyshell.sh shfile` 命令，结果如下：
```bash
$ echo -ne "l\nwhoami" > shfile
$ ./tinyshell.sh shfile
shfile  tinyshell.sh
$ cat shfile
l
whoami$
```
这里使用 `echo` 命令的 `-n` 选项指定不在行末追加换行符，那么写入文件的最后一行不以换行符结尾。

可以看到，执行 `./tinyshell.sh shfile` 命令，只处理了第一行的 *l* 字符，第二行的 *whoami* 没有被执行。

用 `cat shfile` 命令查看该文件内容，*whoami* 跟命令行提示符打印在同一行，确实不以换行符结尾。

为了避免这个问题，可以在脚本中添加判断，如果所给文件的最后一行不以换行符结尾，则追加一个换行符到文件末尾。

要添加的代码如下，新增的代码前面用 `+` 来标识：
```bash
if [ $# -ne 0 ]; then
    filename="$1"
+    if test -n "$(tail "$filename" -c 1)"; then
+        echo >> "$filename"
+    fi
else
    filename="/dev/stdin"
fi
```
新增的代码用 `tail "$filename" -c 1` 命令获取到 *filename* 文件的最后一个字符，`"$(tail "$filename" -c 1)"` 语句经过命令扩展后返回这个字符。

如果这个字符是换行符，由于 bash 在扩展后会自动丢弃字符串的最后一个换行符，获取到的内容为空，`test -n` 返回为 false，不做处理。

如果最后一个字符不是换行符，那么内容不为空，`test -n` 返回为 true，就会执行 `echo >> "$filename"` 命令追加一个换行符到文件末尾，`echo` 不带参数时，默认输出一个换行符， `>>` 表示追加内容到文件末尾。

添加这几个语句后，再执行 `./tinyshell.sh shfile` 命令，就能处理到最后一行的 *whoami*，如下所示：
```bash
$ ./tinyshell.sh shfile
shfile  tinyshell.sh
shy
$ cat shfile
l
whoami
$
```
可以看到，执行之后，*shfile* 文件的最后一行 *whoami* 后面被追加了一个换行符，输出该文件内容，命令行提示符会换行打印。

通常来说，在 Windows 下复制内容到新建文件，然后保存这个文件，文件的最后一行可能就不以换行符结尾。

## 使用 -s 选项指定不回显用户输入
在 bash 下，输入密码时，一般不会回显用户输入，而是什么都不显示。  
我们可以使用 `read` 命令的 `-s` 选项模拟这个效果。

查看 help read 对 `-s` 选项的说明如下：
> **-s**  
do not echo input coming from a terminal

具体举例如下：
```bash
$ read -s -p "Your input will not echo: " input
Your input will not echo: $ echo $input
sure?
```
这个例子指定了 `-s` 选项，不回显输入内容到终端，用 `-p` 指定了提示字符串，输入内容会被保存到 *input* 变量。  
在输入的时候，界面上不会显示任何字符。

回车之后，命令行提示符直接显示在同一行，由于没有回显换行符，所以没有换行。

打印 *input* 变量的值，可以看到手动输入的内容是 “sure?”。

如果需要在模拟的简易 shell 中输入密码，可以添加类似下面的代码，让输入密码时不回显，新增的代码前面用 `+` 来标识：
```bash
    elif [ "$input" == "quit" ]; then
        break
+    elif [ "$input" == "root" ]; then
+        read -s -p "Please input your password: " pwd
+        # handle password with $pwd
+        echo
+        echo "Your are root now."
    else
        bash -c "${input}"
    fi
```
这里添加了对 *root* 字符串的处理，先执行 `read -s -p "Please input your password: " pwd` 命令，提示让用户输入密码，输入的内容不会回显，会保存在 *pwd* 变量中，可以根据实际需要进行处理。

新增的第一个 `echo` 命令用于从 "Please input your password: " 字符串后面换行，否则会直接输出到同一行上。

第二个 `echo` 命令只是打印一个提示语，可以根据实际需求改成对应的提示。

## 使用 -n 选项指定读取多少个字符
执行 `read` 命令读取标准输入，会不停读取输入内容，直到遇到换行符为止。

如果我们预期最多只读取几个字符，可以使用 `-n` 选项来指定。查看 help read 对 `-n` 选项说明如下：
> **-n nchars**  
return after reading NCHARS characters rather than waiting for a newline, but honor a delimiter if fewer than NCHARS characters are read before the delimiter

即，`read -n nchars` 指定最多只读取 *nchars* 个字符，输入 *nchars* 个字符后，即使还没有遇到换行符，`read` 也会停止读取输入，返回读取到的内容。

如果在输入 *nchar* 个字符之前，就遇到换行符，也会停止读取输入。

使用 `-n` 选项并不表示一定要读取到 *nchars* 个字符，另外一个 `-N` 选项表示一定要读取到 *nchars* 个字符，  
这里对 `-N` 选项不做说明。

下面会在模拟的简易 shell 中实现一个小游戏，增加一点趣味性。  
这个小游戏使用 `read -n 1 ` 来指定每次只读取一个字符，以便输入字符就立刻停止读取，不需要再按回车。

具体实现代码如下，这也是 `tinyshell.sh` 脚本最终版的代码：
```bash
#!/bin/bash -i

if [ $# -ne 0 ]; then
    filename="$1"
    if test -n "$(tail "$filename" -c 1)"; then
        echo >> "$filename"
    fi
else
    filename="/dev/stdin"
fi

function game()
{
    local count=0
    local T="T->"

    echo -e "NOW, ATTACK! $T"
    while read -s -n 1 char; do
        case $char in
            "h") ((--count)) ;;
            "l") ((++count)) ;;
            "q") break ;;
        esac

        for ((i = 0; i < count; ++i)); do
            echo -n "    "
        done
        echo -ne "$T      \r"
    done
    echo
}

while read -ep "tinyshell> " input; do
    if [ "$input" == "l" ]; then
        ls
    elif [ "$input" == "quit" ]; then
        break
    elif [ "$input" == "root" ]; then
        read -s -p "Please input your password: " pwd
        # handle with $pwd
        echo
        echo "Your are root now."
    elif [ "$input" == "game" ]; then
        game
    else
        bash -c "${input}"
    fi
    history -s "${input}"
done < "$filename"
```
主要改动是增加对 *game* 字符串的处理，输入这个字符串，会执行自定义的 `game` 函数。  
该函数打印 `T->` 字符串，像是一把剑（也许吧），然后用 `read -s -n 1 char` 命令指定每次只读取一个字符，且不回显。

如果输入 *l* 字符，则把 `T->` 字符串的显示位置往右移。  
输入 *h* 字符，则把 `T->` 字符串的显示位置往左移。  
看起来是一个左右移动的效果。  
输入 *q* 字符，退出该游戏。

具体执行结果如下：
```bash
$ ./tinyshell.sh
tinyshell> game
NOW, ATTACK! T->
        T->
tinyshell>
```
由于没有回显输入字符，且始终在同一行显示 `T->` 字符串，所以这个打印结果体现不出 `T->` 字符串的移动，可以实际执行这个脚本，多次输入 *l* 、*h* 字符，就能看到具体效果，最后输入 *q* 字符退出游戏。

## 总结
至此，我们已经使用 `read` 命令来获取用户输入，模拟了一个简易的 shell 效果，可以执行脚本文件，可以通过上下光标键获取到 bash 的历史命令，支持输入密码不回显，还实现了一个小游戏。

总结 `read` 命令的使用关键点如下：
- 使用 -p 选项来打印提示字符，模拟 shell 的命令行提示符
- 使用 -e 选项在交互式 shell 中用 *readline* 库读取输入，可以避免输入上下光标键显示乱码
- 使用 -s 选项指定不回显输入内容，可用于输入密码、输入游戏控制按键等情况
- 使用 -n 1 选项指定只读取一个字符，输入字符立刻结束读取，可以在游戏中快速响应按键，不用按下回车才能响应
- 使用 “while read” 循环来重定向读取文件，可以逐行读取文件内容，执行相应命令，就像是执行脚本文件
