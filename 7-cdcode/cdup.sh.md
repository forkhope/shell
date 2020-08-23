# 介绍一个快速 cd 到多层上级目录的 shell 脚本

在 Linux 中，当需要 cd 到多层的上级目录时，需要输入 `cd ../../../` 等等多个 “../”。

在输入比较快的时候，往往中间会多输入一个点号 ‘.’、或者少输入一个点号 ‘.’，需要往前删除，重新输入。

而在实际开发工作中，特别是进行 Android 系统开发工作时，源代码目录可能会有多级子目录。

当进入到目录结构非常深的子目录时，想要返回到特定的多层上级目录，需要手动输入多个 “../”，非常麻烦，也很容易输错。

为了简化输入，减少输入出错的情况，本篇文章介绍一个名为 `cdup.sh` 的 shell 脚本。

该脚本接收一个整数参数，指定要返回到几层的上级目录，可以非常方便地返回到多层上级目录，提高工作效率。

例如，执行 `source cdup.sh 5` 命令，等价于执行 `cd ../../../../../` 命令。

所给的数字 5 指定要返回到第 5 层上级目录。

后面会介绍如何设置命令别名来避免输入 `source cdup.sh` 这些字符，可以简化成 `up 5` 这样的输入即可。

由于 shell 脚本默认运行在子 shell 里面，而 `cd` 命令只能改变当前 shell 的工作目录。

所以在 shell 脚本里面执行 `cd` 命令不能改变父 shell 的工作目录。

为了让脚本执行结束后，还保持在 `cd` 后的目录，需要用 `source` 命令来执行 shell 脚本。

使用 `source` 命令执行 shell 脚本，会运行在当前 shell 下，而不是运行在子 shell 里面。

# 脚本代码
列出 `cdup.sh` 脚本的具体代码如下所示。

在这个代码中，对大部分关键代码都提供了详细的注释，方便阅读。

这篇文章的后面也会对一些关键点进行说明，有助理解。
```bash
#!/bin/bash
# 当要 cd 到多层的上级目录时,需要输入 cd ../../../ 等等多个 "../".
# 为了简化输入,当前脚本可以处理一个整数参数,指定返回到几层的上级目录.
# 例如 source cdup.sh 3 等价于 cd ../../../
# 为了让脚本执行结束后,还保持在 cd 后的目录,需要用 source 命令
# 来执行该脚本. 可以在 ~/.bashrc 文件中添加如下别名来方便执行:
#   alias up='source cdup.sh'
# 后续执行 up 3 命令,就等价于 cd ../../../
# 这里假设 cdup.sh 脚本放在 PATH 指定的寻址目录下.例如 /usr/bin 目录.
# 如果 cdup.sh 脚本没有放在默认的寻址目录下,请指定完整的绝对路径.

cdup_show_help()
{
printf "USAGE
    source cdup.sh number
OPTIONS
    number: 指定要返回到几层的上级目录.
    例如 source cdup.sh 3 等价于 cd ../../../
NOTE
    可以使用 alias up='source cdup.sh' 设置 up 别名来方便执行.
"
}

if [ $# -ne 1 ]; then
    cdup_show_help
    # 当前脚本预期通过 source 命令来调用,不能执行 exit 命令,
    # 否则会退出调用该脚本的 shell.下面通过 return 命令来返回.
    return 1
fi

UPDIR_PATH="../"

# 根据传入的数字参数,计算要返回到几层上级目录,并将结果写到标准输出
count_updirs()
{
    # 所给的第一个参数指定要返回到几层上级目录
    local count=$1

    local updirs=""
    while ((--count >= 0)); do
        # 没有使用算术扩展时, bash 的 += 运算符默认会拼接字符串.
        # 下面语句会拼接多个 "../",得到类似于 "../../../" 的效果.
        updirs+=${UPDIR_PATH}
    done
    echo ${updirs}
}

target_dir="$(count_updirs $1)"
# 使用 \cd 来指定不使用 alias 别名,执行原始的 cd 命令.
\cd "${target_dir}"

return
```

# 代码关键点说明

## 建议设置命令别名来执行当前脚本
如前面说明，需要使用 `source` 命令来执行 `cdup.sh` 脚本，以便执行该脚本之后，可以保持在 `cd` 后的目录下。

即，执行的时候，需要写为 `source cdup.sh`。

这样需要输入比较多的字符，而且也容易忘记提供 `source` 命令。

为了方便输入，在脚本注释中，建议设置命令别名来执行当前脚本。

例如，在 `~/.bashrc` 文件中添加下面语句来设置命令别名:
```bash
alias up='source cdup.sh'
```
添加这个语句后，在当前终端中，需要执行 `source ~/.bashrc` 命令，这个别名才会生效。

也可以重新打开终端，在新打开的终端中，这个别名默认就会生效。

在别名生效之后，就可以使用 *up* 命令来执行 `cdup.sh` 脚本。

例如，`up 3` 命令等价于 `source cdup.sh 3` 命令。

这里假设 `cdup.sh` 脚本放在 PATH 全局变量指定的寻址目录里面，通过文件名就可以执行，不需要指定文件的路径。

如果该脚本没有放在默认的寻址目录里面，需要提供文件的绝对路径。

## 在 cd 命令前面加反斜线指定不使用别名
在 bash 中，支持设置命令别名。

如果某个命令别名被设置成 *cd* 字符串，那么执行 *cd* 命令，会执行该别名指定的命令。

即，不会执行原本切换工作目录的 `cd` 命令。

为了避免这个问题，可以使用 `\cd` 来指定不使用别名，会执行 `cd` 命令自身。

在 `cdup.sh` 脚本中使用了 `\cd` 这个写法，以确保可以切换工作目录。

查看 man bash 对 alias 别名的说明，没有明确提到在命令前面加反斜线可以不使用别名。

这是基于反斜线转义字符的作用、以及别名的处理逻辑所引申出来的特殊用法。

对 `\cd` 这种写法可以不使用命令别名的相关说明具体解读如下。

查看 man bash 对反斜线 `\` 的说明如下：
> A non-quoted backslash (\\) is the escape character.
>
> It preserves the literal value of the next character that follows, with the exception of \<newline\>.

即，当反斜线 `\` 没有被任何引号括起来时，它可以保持跟在后面的下一个字符为自身不变。

且，经过 bash 处理之后，会去掉 `\` 字符，只保留下一个字符自身。

例如，在 bash 中，没有加任何引号的情况下，`\c` 会得到字符 c。

具体举例说明如下：
```bash
$ echo \c
c
$ echo \cd
cd
```
可以看到，`echo \c` 命令打印的是字符 c，而不是 "\c" 字符串。

`echo \cd` 命令打印的是 "cd" 字符串。

实际上，这是 `\c` 得到字符 c 之后，字符 c 再跟字符 d 组合成 "cd" 字符串。

查看 man bash 对 alias 别名的说明如下：
> The first word of each simple command, if unquoted, is checked to see if it has an alias.
>
> If so, that word is replaced by the text of the alias.

即，bash 会获取命令第一个没有被引号括起来的字符，基于这个字符来检查是不是一个别名。

如果是，就把这个命令别名替换成指定的命令。

在 bash 中，无法把命令别名的第一个字符设成反斜线。

具体举例如下：
```bash
$ alias \testcd='cd ../../'
$ alias | grep cd
alias testcd='cd ../../'
```
这里先执行 `alias \testcd='cd ../../'` 命令设置别名。

从输入的参数来看，所设置的别名看起来是 `\testcd`。

但是用 `alias` 命令打印出所有命令别名，并用 `grep` 过滤出包含 `cd` 的行。

可以看到，实际设置的别名是 *testcd*。

这个别名的第一个字符并不是反斜线。

如前面说明，bash 会去掉没有用引号括起来的反斜线。

查看 GNU bash 的在线帮助链接 <https://www.gnu.org/software/bash/manual/bash.html>，有如下说明：
> 3.1.1 Shell Operation
>
>> 2.Breaks the input into words and operators, obeying the quoting rules described in Quoting. These tokens are separated by metacharacters. Alias expansion is performed by this step.
>>
>> 4.Performs the various shell expansions, breaking the expanded tokens into lists of filenames and commands and arguments.
>
> 3.5.9 Quote Removal
>
>> After the preceding expansions, all unquoted occurrences of the characters ‘\’, ‘'’, and ‘"’ that did not result from one of the above expansions are removed.

即，bash 在 *Quote Removal* 阶段会移除反斜线 `\` 字符。

而 *Quote Removal* 是在 shell 扩展之后进行。

判断别名是在 shell 扩展之前进行。

所以，bash 在判断别名时，还会看到反斜线 `\` 字符。

也就是说，执行 `\cd` 命令时，在判断别名阶段，会看到这个命令的第一个字符是 `\`。

如前面说明，无法把命令别名的第一个字符设成反斜线。

那么找不到 `\cd` 对应的别名，不会进行别名替换。

经过 *Quote Removal* 阶段后，去掉了反斜线，只剩下 `cd` 命令。

此时已经过了判断别名阶段，所以执行的是 `cd` 命令自身，不会执行名为 *cd* 的命令别名。

即，严格来说，在命令前面加反斜线，并不是不使用别名。

而是会找不到以反斜线开头的别名，所以没有进行别名扩展。

通俗来说，可以简单理解为，在命令前面加反斜线指定不使用别名。

# 执行当前脚本的例子
使用前面说明的 `up` 命令别名来执行 `source cdup.sh` 命令，具体执行结果如下：
```bash
[frameworks/base/services/core/java/com/android/server]$ cd ../../../../../
[frameworks/base/services]$ cd -
frameworks/base/services/core/java/com/android/server
[frameworks/base/services/core/java/com/android/server]$ up 5
[frameworks/base/services]$
```
在这个例子中，方括号中间显示的目录路径就是当前 shell 的工作目录。

可以看到，`cd ../../../../../` 命令退回到第 5 层上级目录。

然后执行 `cd -` 命令返回到原来的子目录下。

再执行 `up 5` 命令，也是退回到第 5 层上级目录。

`up 5` 命令的效果跟 `cd ../../../../../` 命令相同，但是输入非常简单，也不容易出错。
