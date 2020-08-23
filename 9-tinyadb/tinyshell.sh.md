# 介绍一个可以通过命令简写执行对应命令的 shell 脚本

本篇文章介绍一个可以通过命令简写执行对应命令的 shell 脚本。

假设这个 shell 脚本的名称为 `tinyshell.sh`。

在 Linux 下进行项目开发，经常会用到一些调试开发命令。

这些命令可能比较长，需要输入多个字符。

例如，Android 系统抓取全部 log 并包含 log 时间的命令是 *adb logcat -b all -v threadtime*。

抓取 log 是调试开发非常常见的操作，这个命令又很长，输入起来不方便。

为了简化输入，可以配置一些命令简写来对应比较长命令。

例如，配置 *ala* 对应 *adb logcat -b all -v threadtime*。

把 *als* 作为参数传递给当前的 `tinyshell.sh` 脚本，会执行该命令简写对应的命令。

这样只需要输入比较少的字符，就能执行比较长的命令。

实际上，这个功能类似于 bash 的 `alias` 别名，只是将这些别名统一放到该脚本来处理。

可以把 `tinyshell.sh` 脚本作为学习 shell 脚本的参考例子，独立维护更新，根据需要扩充更多的功能。

# 配置命令简写
如之前说明，可以用 *ala* 表示 *adb logcat -b all -v threadtime* 这个命令。

这个 *ala* 称之为 “命令简写”。

命令简写使用一些简单的字符来表示特定的命令。

可以在命令简写后面动态提供命令的参数。

为了方便动态添加、删除、查询命令简写，可以把这些命令简写保存在一个配置文件里面。

在执行 `tinyshell.sh` 脚本时，会读取配置文件内容，获取到各个配置项的值。

配置项的基本格式是：命令简写|命令内容

每个配置项占据一行。每一行默认以第一个竖线 ‘|’ 隔开命令简写和命令内容。

一个参考的配置文件内容如下所示：
```
ll|ls --color=auto -l
ala|adb logcat -b all -v threadtime
gl|git log
gp|git pull --stat --no-tags $(git remote) $(git rev-parse --abbrev-ref HEAD)
```

这里配置的命令内容可以是系统支持的任意命令。  

解析配置文件时，需要用到之前文章介绍的 `parsecfg.sh` 脚本。

要获取 `parsecfg.sh` 脚本的代码，可以查看之前的文章。

后面会提供具体测试的例子，可供参考。

# 脚本代码
列出 `tinyshell.sh` 脚本的具体代码如下所示。

在这个代码中，对大部分关键代码都提供了详细的注释，方便阅读。

这篇文章的后面也会对一些关键点进行说明，有助理解。

```bash
#!/bin/bash -i
# 使用 bash 的 -i 选项,让该脚本在交互模式下运行.
# 实现一个小型的 shell. 支持内置命令、命令简写. 如果提供这两种命令之外
# 的其他命令,会尝试在 bash 中直接执行所给命令,可以执行系统支持的命令.
# 命令简写指的是一些简单的字符,会对应一串实际要执行的命令.只要输入命令
# 简写就可以执行对应的命令,减少需要输入的字符.命令简写在配置文件中配置.

# 下面变量指定默认解析的配置文件名.该文件配置了命令简写、以及对应的命令.
# 这个 tinyshellcmds.txt 文件需要预先配置好,放到指定路径的目录底下.
# 直接修改这个配置文件,就可以动态添加或删除命令简写.不需要修改脚本代码.
SHORT_COMMANDS="${HOME}/.liconfig/tinyshellcmds.txt"

# PARSECFG_filepath 是 parsecfg.sh 脚本里面的变量. 如果这个变量为空,
# 说明还没有打开过配置文件,进入下面的分支打开默认的配置文件.
if [ -z "$PARSECFG_filepath" ]; then
    # 导入解析配置文件的脚本,以便调用该脚本的函数来解析配置文件.
    source parsecfg.sh
    # 调用 parsecfg.sh 里面的 open_config_file() 函数解析配置文件.
    # 如果配置文件不存在,会返回 1,经过'!'操作符取反为 0,会退出执行.
    if ! open_config_file "$SHORT_COMMANDS"; then
        exit 2
    fi
fi

# 下面变量指定 tiny shell 的提示字符串.
PROMPT="TinySh>>> "

# 下面使用 basename 命令来提取出脚本的文件名,去掉目录路径部分.
show_help()
{
printf "USAGE
    $(basename $0) [option] [shortcmd [argument1 ... [argumentn]]]
OPTIONS
    option: 可选的选项参数. 支持的选项参数描述如下:
        -h: 打印这个帮助信息.
        -l: 打印配置文件本身的内容,会列出配置的命令简写和对应的命令.
        -v: 以键值对的方式列出命令简写和对应的命令.
        -i: 在配置文件中查找指定内容.后面跟着一个参数,指定要查找的内容.
        -e: 使用 vim 打开脚本的配置文件,以供编辑.
        -a: 新增或修改一个命令简写和对应的命令.后面跟着一个参数,用
            单引号括起来,以指定命令简写和命令. 格式为: 命令简写|命令.
            例如 -a 'p|git pull',如果p简写不存在则新增它,否则修改它.
        -d: 从脚本配置文件中删除一个命令简写和对应的命令.后面跟着一个
            参数,指定要删除的命令简写.例如 -d s,会删除命令简写为 s 的行.
    shortcmd: 可选选项.
        指定要直接执行的命令简写. 提供命令简写参数,不会进入 tiny shell.
    argument1 ... argumentn: 可选选项.
        指定该命令简写的参数. 命令简写对应一个命令,支持动态提供参数.
NOTE
    如果没有提供任何参数,默认会进入 tiny shell 解释器. 在 tiny shell 中
    接收用户输入并执行对应的命令.直到读取到EOF、或者执行quit命令才会退出.
"
}

# tiny shell 的内置命令数组. 这是一个关联数组. 数组元素的
# 键名是内置命令名. 数组元素的键值是响应内置命令的函数名.
declare -A BUILTIN_COMMAND=( \
    [help]="builtin_command_help" \
    [quit]="builtin_command_quit" \
    [debug]="builtin_command_debug" \
)

# bash 的 help 命令默认会打印内置命令列表. 这里仿照这个行为,
# 让 help 内置命令打印内置命令列表、以及配置文件包含的命令简写.
builtin_command_help()
{
printf "下面列出 Tiny Shell 支持的内置命令列表和配置的命令简写列表.
输入内置命令名或命令简写,会执行对应的命令.
也可以输入系统自身支持的命令,会在 bash 中执行所给命令.

内置命令列表:
    debug: 所给第一个参数指定打开、或关闭调试功能. 其参数说明如下:
        on:  打开调试功能,会执行 bash 的 set -x 命令
        off: 关闭调试功能,会执行 bash 的 set +x 命令
    help: 打印当前帮助信息.
    quit: 退出当前 Tiny Shell.

命令简写列表:
"
    # 调用 parsecfg.sh 的 handle_config_option -v 打印命令简写列表
    handle_config_option -v
}

# quit 内置命令. 执行该命令会退出整个脚本,从而退出当前 tiny shell.
builtin_command_quit()
{
    exit
}

# debug 内置命令. 所给第一个参数指定打开、或关闭调试功能.
# debug on:  打开调试功能,会执行 bash 的 set -x 命令
# debug off: 关闭调试功能,会执行 bash 的 set +x 命令
builtin_command_debug()
{
    if [ $# -ne 1 ]; then
        echo "Usage: debug on/off"
        return 1
    fi

    if [ "$1" == "on" ]; then
        set -x
    elif [ "$1" == "off" ]; then
        set +x
    else
        echo -e "Unknown argument: $1\nUsage: debug on/off"
    fi
    return
}

# 处理 tiny shell 内置命令.对于内置命令,会调用对应函数进行处理.
# 该函数的返回值表示所给命令名是否内置命令.
# 返回 0, 表示是内置命令. 返回 1, 表示不是内置命令.
execute_builtin_command()
{
    # 在传递过来的参数中,第一个参数是命令名,剩余的参数是该命令的参数.
    local cmdname="$1"
    # 从 BUILTIN_COMMAND 数组中获取所给命令对应的处理函数.
    # 如果所给命令不是内置命令,会获取为空.
    local cmdfunc="${BUILTIN_COMMAND["${cmdname}"]}"

    if [ -n "${cmdfunc}" ]; then
        # 将位置参数左移一位,移除命令名,剩下的就是该命令的参数.
        shift 1
        ${cmdfunc} "$@"
        # 无论执行内置命令是否报错,都会返回 0,表示该命令是内置命令.
        return 0
    else
        return 1
    fi
}

# 处理 tiny shell 的命令简写.在所解析的配置文件中包含了支持的命令简写.
# 该函数的返回值表示所给命令名是否命令简写.
# 返回 0, 表示是命令简写. 返回 1, 表示不是命令简写.
execute_short_command()
{
    # 判断所给的参数是否对应配置文件中的某个键名.如果是,将取出键值.
    local key="$1"
    # 从配置文件中获取所给命令简写对应要执行的命令
    local cmd_value=$(get_value_by_key "${key}")
    if test -n "${cmd_value}"; then
        # 将位置参数左移一位,移除命令简写,剩下的就是命令的参数.
        shift 1
        # 下面要用 "$*" 来把所有参数组合成一个参数,再跟命令内容一起传入
        # bach -c,确保 bash -c 把命令内容和所有参数都当成要执行的命令
        bash -c "$cmd_value $*"
        # 打印命令简写,以及该简写对应的命令,以便查看具体执行了什么命令.
        # 先执行命令,再打印命令内容. 由于有些命令的输出很多,先打印命令
        # 内容的话,需要拉动终端滚动条,才能找到打印的命令内容,不便于查看.
        echo -e "\e[33m命令简写: ${key}. 命令: ${cmd_value} $*\e[0m"
        return 0
    else
        # 如果获取到的键值为空,表示所给键名不是有效的命令简写,返回 1
        return 1
    fi
}

# 处理所给的内容.这个内容可能是内置命令,命令简写,或者命令本身.
handle_input_command()
{
    # 所给参数是要执行的命令名、以及命令参数. 如果命令名是配置的
    # 命令简写,会把该命令简写替换成对应的命令,再进行对应的命令.
    local inputcmd="$@"

    # if 语句可以直接判断命令返回值是否为 0,并不是只能搭配 [ 命令使用.
    # 注意: 由于有的 tiny shell 内置命令接收参数,下面的 ${cmd_line}
    # 不能用双引号括起来,否则多个参数会被当成一个参数.
    if execute_builtin_command ${inputcmd}; then
        # 先调用 execute_builtin_command 函数处理内置命令.如果所给
        # 命令是内置命令,则调用对应的函数进行处理,且不再往下执行.
        return 0
    elif execute_short_command ${inputcmd}; then
        # 调用 execute_short_command 函数处理命令简写.
        return 0
    else
        # 对于 tiny shell 不能执行的命令,尝试用 bash -c 在 bash 中执行.
        bash -c "${inputcmd}"
        # 当 return 命令不加具体状态码时,它会返回上一条执行命令的状态码.
        return
    fi
}

# SIGINT 信号的处理函数.目前不做特殊处理,只是想在输入CTRL-C后,不会终止
# 当前 tiny shell. 输入 CTRL-C 还是可以终止 tiny shell 启动的子 shell.
sigint_handler()
{
    # 当输入 CTRL-C 后,终端只显示"^C",但是不会自动换行,需要输入回车才会
    # 换行,并重新输出提示字符串. 而在交互式Bash中,输入"^C"后,就会自动回
    # 车,并输出提示字符串.这里模仿这个行为,先输出一个回车,再输出提示符.
    printf "\n${PROMPT}"
}

# 启动 tiny shell 解释器. 从标准输入不停读取、并执行所给命令.直到
# 使用 CTRL-D 输入 EOF 为止, 或者输入 quit 命令退出当前解释器.
start_tinyshell()
{
    # 执行 python 命令,默认会打印 python 版本号和一句帮助提示.
    # 这里仿照这个行为,打印 tiny shel 版本号和一句帮助提示.
    echo -e "Tiny shell 1.0.0\nType 'help' for more information."

    # 捕获SIGINT信号,以便输入 CTRL-C 后,不会退出当前的 tiny shell.
    # 注意: 由于子shell会继承父shell所忽略的信号,所以不能将 SIGINT 信号
    # 设成忽略,而是要指定一个处理函数. 当前 shell 所捕获的信号不会被
    # 子 shell 继承. 所以子 shell 还是可以被 CTRL-C 终止. 即,指定信号处理
    # 函数后,当前 tiny shell 不会被CTRL-C终止.但是当前 tiny shell 执行的
    # 命令会运行在子 shell 下,可以用 CTRL-C 终止运行在子 shell 下的命令.
    # 查看 man bash 对子 shell 的信号继承关系说明如下:
    # traps caught by the shell are reset to the values inherited from
    # the shell's parent, and traps ignored by the shell are ignored
    trap "sigint_handler" SIGINT

    # 如果不使用 -e 选项,输入上光标键, read 会读取到 "^[[A";输入下光标键,
    # read 会读取到 "^[[B".而使用 -e 选项后,输入上下光标键,不会读取到乱码,
    # 但是在子shell中,也不会返回历史命令.因为shell脚本是在非交互模式下执行.
    # 可以使用 bash 的 -i 选项让脚本在交互模式下运行,例如: "#/bin/bash -i"
    while read -ep "${PROMPT}" input; do
        # 传递参数给函数时,参数要用双引号括起来,避免参数带有空格时,会拆分
        # 成多个参数. 当输入CTRL-C时, tiny shell 捕获了这个信号,不会退出
        # 当前的 tiny shell.但是read命令会被中断,此时读取到的 input 为空.
        # 不需要对空行做处理,所以下面先判断 input 变量值是否为空.
        if [ -n "${input}" ]; then
            handle_input_command "${input}"
            # 执行 history -s 命令把所给的参数添加到当前历史记录中.后续
            # 通过上下光标键获取历史命令,就可以获取到新添加的命令.这个只
            # 影响当前 tiny shell 的历史记录,不会写入外部shell的历史记录.
            history -s "${input}"
        fi
    done

    # 输出一个换行.当用户输入CTRL-D结束执行后,需要换行显示原先的终端提示符.
    echo
}

# 循环调用 getopts 命令处理选项参数.
while getopts "hlvi:ea:d:" opt; do
    # 调用parsecfg.sh脚本处理选项的函数来处理 "lvi:ea:d:" 这几个选项.
    # 如果处理成功,就直接继续读取下一个选项,不再往下处理.
    # handle_config_option()函数要求传入的选项以'-'开头,而getopts命令
    # 返回的选项不带有'-',所以下面在 ${opt} 前面加上一个 '-'.
    handle_config_option "-${opt}" "${OPTARG}"
    if [ $? -ne 127 ]; then
        continue
    fi

    case "$opt" in
        h) show_help ;;
        ?) echo "出错: 异常选项,请使用 -h 选项查看脚本的帮助说明." ;;
    esac
done

# $# 大于0,说明提供了命令参数. $# 等于OPTIND减去1,说明传入的参数都
# 是以 '-' 开头的选项参数. 此时,直接结束执行,不需要再往下处理.
# 下面的 -a 表示两个表达式都为真时才为真.表达式之间不要加小括号.
# Shell里面的小括号有特殊含义,跟C语言的小括号有些区别,加上会有问题.
if [ $# -gt 0 -a $# -eq $((OPTIND-1)) ]; then
    exit 0
fi

if [ $# -eq 0 ]; then
    # 当不带任何参数时,默认启用 tiny shell.
    start_tinyshell
else
    # 左移所给的命令参数,去掉已处理过的选项参数,只剩下非选项参数.
    shift $((OPTIND-1))
    # 执行脚本时,如果提供了非选项参数,那么第一个参数认为是命令简写,
    # 需要执行该命令简写对应的命令. 第一个参数之后的所有参数认为是
    # 命令的参数. 即,可以在命令简写之后提供参数来动态指定一些操作.
    execute_short_command "$@"
fi

exit
```

# 代码关键点说明

## 使用 trap 命令捕获信号
在 bash 中，可以使用 `trap` 命令捕获信号，并指定信号处理函数。

捕获信号后，可以避免收到某个信号终止脚本执行。

当前 `tinyshell.sh` 脚本使用 `trap` 命令捕获 SIGINT 信号。

也就是 CTRL-C 键所发送的信号，避免按 CTRL-C 键会退出当前 tiny shell。

要注意的是，不能设置成忽略 SIGINT 信号。

在 bash 中，父 shell 所忽略的信号，也会被子 shell 所忽略。

除了内置命令之外，当前 tiny shell 所执行的命令运行在子 shell 下。

如果设置成忽略 SIGINT 信号，那么子 shell 也会忽略这个信号。

那么就不能用 CTRL-C 来终止子 shell 命令的执行。

例如，Android 系统的 `adb logcat` 命令会不停打印 log，需要按 CTRL-C 来终止。

此时，在 tiny shell 里面按 CTRL-C 就不能终止 `adb logcat` 的执行。

父 shell 所捕获的信号，子 shell 不会继承父 shell 所捕获的信号。

子 shell 会继承父 shell 的父进程的信号状态。

父 shell 的父进程一般是外部 bash shell 进程。

而 bash shell 进程默认捕获SIGINT并终止前台进程。

即，虽然当前 tiny shell 捕获了 SIGINT 信号，但是子 shell 并没有捕获该信号。

可以在 tiny shell 使用 CTRL-C 来终止子 shell 命令的执行。

## 使用 history -s 命令添加历史记录
在 tiny shell 执行命令后，默认不能用上下光标键查找到 tiny shell 自身执行的历史命令。

为了可以查找到 tiny shell 自身执行的历史命令，使用 `history -s` 命令添加命令到当前 shell 的历史记录。

这个命令只会影响当前 shell 的历史记录。

退出当前 shell 后，在外部 shell 还是看不到 tiny shell 所执行的命令。

由于这个 tiny shell 主要是为了执行命令简写。

这些命令简写只有 tiny shell 自身支持，不需要添加到 bash shell 的历史记录。

如果想要命令历史信息添加到外部 shell 的历史记录，可以在退出 `tinyshell.sh` 脚本之前，执行 `history -w ~/.bash_history` 命令把历史记录写入到 bash 自身的历史记录文件。

# 测试例子
把 `tinyshell.sh` 脚本放到 PATH 变量指定的可寻址目录下。

查看 `tinyshell.sh` 脚本代码，可知要解析的配置文件名是 tinyshellcmds.txt。

把前面贴出的命令简写配置信息写入 tinyshellcmds.txt 文件。

把这个文件放到 HOME 目录的 .liconfig 目录下。

之后，就可以开始执行 `tinyshell.sh` 脚本。

当前的 `tinyshell.sh` 脚本可以执行内置命令、命令简写对应的命令、系统自身支持的命令。

当不提供任何命令参数时，会进入 tiny shell。

在 tiny shell 中，会不停接收用户输入并执行对应命令。

直到读取到 EOF 、或者执行 quit 命令才会退出 tiny shell。

## 处理选项参数和直接处理命令简写的例子

下面是不进入 tiny shell，只处理选项参数和命令简写的例子：
```
$ tinyshell.sh -v
key='gl'        value='git log'
key='gp'        value='git pull --stat --no-tags $(git remote) $(git rev-parse --abbrev-ref HEAD)'
key='ll'        value='ls --color=auto -l'
key='ala'       value='adb logcat -b all -v threadtime'
$ tinyshell.sh ll
-rwxrwxr-x 1 xxx xxx 964 11月 14 17:37 tinyshell.sh
命令简写: ll. 命令: ls --color=auto -l
```

这里先执行 `tinyshell.sh -v` 命令，用键值对的形式列出支持的命令简写。

此时，只处理所给的选项参数，不会进入 tiny shell 里面。

`tinyshell.sh ll` 命令，提供了一个 *ll* 参数（两个小写字母 l）。

这个参数会被当成命令简写，然后执行该命令简写对应的命令。

执行结束后，不会进入 tiny shell 里面。

基于刚才列出的命令简写，可知 *ll* 对应 *ls --color=auto -l* 命令。

实际执行的也是这个命令。

## 进入 tiny shell 循环处理命令的例子

当不提供任何命令参数时，会进入 tiny shell 里面，循环处理命令。

具体例子如下所示：
```
$ tinyshell.sh
Tiny shell 1.0.0
Type 'help' for more information.
TinySh>>> help
下面列出 Tiny Shell 支持的内置命令列表和配置的命令简写列表.
输入内置命令名或命令简写,会执行对应的命令.
也可以输入系统自身支持的命令,会在 bash 中执行所给命令.

内置命令列表:
    debug: 所给第一个参数指定打开、或关闭调试功能. 其参数说明如下:
        on:  打开调试功能,会执行 bash 的 set -x 命令
        off: 关闭调试功能,会执行 bash 的 set +x 命令
    help: 打印当前帮助信息.
    quit: 退出当前 Tiny Shell.

命令简写列表:
key='gl'        value='git log'
key='gp'        value='git pull --stat --no-tags $(git remote) $(git rev-parse --abbrev-ref HEAD)'
key='ll'        value='ls --color=auto -l'
key='ala'       value='adb logcat -b all -v threadtime'
TinySh>>> date
2019年 12月 31日 星期二 17:46:41 CST
TinySh>>> ll -C
tinyshell.sh
命令简写: ll. 命令: ls --color=auto -l -C
```

当执行 `tinyshell.sh` 命令会进入 tiny shell 时，会打印一个 “TinySh>>>” 提示符。

在 tiny shell 中执行 *help* 命令可以查看支持的内置命令和命令简写。

在 tiny shell 中执行 *date* 命令打印当前的日期和时间。

当前的 tiny shell 自身不支持 *date* 命令。

这里执行了系统自身的 *date* 命令。

最后执行 *ll -C* 命令。

这里的 *ll* 是命令简写。后面的 *-C* 是对应命令的参数。

具体执行的命令是 *ls --color=auto -l -C*。

`ls` 命令的 -C 选项会多列显示文件名，覆盖了 -l 选项的效果。

由于 -l 选项的效果被覆盖，输出结果没有打印文件的详细信息，只列出文件名。

可以看到，在命令简写之后，可以再提供其他的命令参数。

即，可以只配置比较长的命令前缀部分，一些简单的参数可以动态提供。

不需要在配置文件中添加很多内容相似、只有细微差异的配置项。
