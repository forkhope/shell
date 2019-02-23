#!/bin/bash -i
# 使用 bash 的 -i 选项,让该脚本在交互模式下运行.
# 这是一个adb命令辅助脚本.可以输入一些常用adb命令的缩写来执行对应的adb命令.
# 例如提供 d 这个参数,脚本会执行 adb shell dmesg 命令.减少输入量.
# 其实就是类似于 Bash 的 alias 别名,只是将这些别名统一放到该脚本来处理.

# adb辅助命令的配置文件.
ADB_HELPER="${HOME}/.myconf/adbinfo.txt"

# 将 adb 命令定义为常量.
ADB="adb"
ADB_SH="${ADB} shell"

# 伪解释器的提示字符串.
PROMPT=':)'

# 伪解释器内置命令关联数组.数组元素是内置命令名,元素对应的值是处理函数名.
declare -A PSEUDO_BUILTIN=( \
    [adb]="handle_builtin_adb" \
    [args]="handle_builtin_args" \
    [e]="handle_builtin_exit" \
    [exit]="handle_builtin_exit" \
    [png]="handle_builtin_png" \
    [reset]="handle_builtin_reset" \
    [list]="handle_builtin_list" \
)

# 下面使用 basename 命令来提取出脚本的文件名,去掉目录路径部分.
tinyadb_show_help()
{
printf "USAGE
        $(basename $0) [option] [argument1 [argument2 [... argummentn]]]
OPTIONS
        option: 可选选项,描述如下:
            -h: 打印这个帮助信息.
            -s: 启动一个交互式的伪解释器,解释用户输入的内容.
            -l: 查看脚本支持的命令简写及其对应的命令.
            -v: 以键值对的方式打印详细的配置文件信息.
            -i: 在配置文件中查找指定内容.需要一个参数来指定要查找的内容.
            -e: 使用vim打开脚本的配置文件,以供编辑.
            -a: 增加或修改一个命令简写和对应的命令到配置文件.需要一个参数,
                用单引号括起来,以指定命令简写和命令.格式为: 路径简写|路径.
                例如-a 's|service list',如果s简写不存在则新增它,否则修改它.
            -d: 从脚本配置文件中删除一个命令简写和对应的命令.需要一个参数,
                以指定命令简写,脚本将从配置文件中删除该命令简写对应的行.
                例如 -d s, 将删除命令简写为 s 的行.
        argument1 argument2 ... argummentn: 所要处理的内容,有以下几种情况:
            伪解释器内置命令: 由伪解释器对该命令进行特殊处理.
            命令选项: 该脚本支持的命令选项.
            命令简写: 在adb shell中执行该命令简写对应的命令.
            命令本身: 使用adb shell来执行这个命令本身.
"
}

# 伪解释器的 SIGINT 信号处理函数.目前什么都不做.即输入Ctrl-C后,不能终止伪
# 解释器,类似于交互式的Bash.但是输入Ctrl-C可以终止伪解释器所启动的子shell.
handle_sigint()
{
    # 如果函数内什么都不写,执行时会报错:
    #   syntax error near unexpected token `}'
    # 所以下面执行Bash的 ':' 内置命令.这个命令除了进行参数扩展和重定向
    # 之外,不做其他任何操作,退出状态码总是0.
    # :
    # 后来发现,输入Ctrl-C后,终端上显示"^C",不会自动换行,需要输入回车,
    # 才会换行,并重新输出提示字符串.而在交互式Bash中,输入"^C"后,就会自动
    # 回车,并输出提示字符串.所以下面进行修改,模仿这个行为.
    # 下面执行 echo 命令,先输出一个回车,再输出提示字符串,提醒用户输入.
    #   "-e" 选项让 echo 命令能够解释转义字符,如 \n 等.
    #   "-n" 选项让 echo 命令不输出行末的回车.只输出提示字符串,不输出回车.
    echo -en "\n${PROMPT}"
}

# 处理伪解释器内置命令: adb. 该命令用于进入adb shell.
handle_builtin_adb()
{
    ${ADB_SH}
}

# 处理伪解释器内置命令: args. 该命令可用于查看命令的所有参数,以便调试.
handle_builtin_args()
{
    local -i index=1

    for arg in "$@"; do
        echo "argument-${index} = ${arg}"
        index+=1
    done
}

# 处理伪解释器内置命令: exit, e. 执行这两个命令会退出整个脚本.
handle_builtin_exit()
{
    exit
}

# 处理伪解释器命令: png. 该命令获取机器的当前屏幕截图,并保存到本地目录.
handle_builtin_png()
{
    local png_file="/sdcard/screen.png"
    ${ADB_SH} screencap "${png_file}" && adb pull "${png_file}"
}

# 处理伪解释器命令: reset. 该命令用于重置当前终端,清除所有屏幕输出.
handle_builtin_reset()
{
    reset
}

# 判断所给命令是否伪解释器内置命令,如果是,则进行特殊处理,返回0.否则,返回 1.
handle_pseudo_builtin()
{
    local cmdname cmdfunc

    # 在传递过来的参数中,第一个参数是命令名,剩余的参数是该命令的选项.
    cmdname="$1"

    cmdfunc="${PSEUDO_BUILTIN["${cmdname}"]}"
    if [ -n "${cmdfunc}" ]; then
        # 将位置参数左移一位,移除命令名,剩下的就是该命令的选项.
        shift 1
        ${cmdfunc} "$@"
        return 0
    fi

    return 1
}

# 列举伪解释器的内置命令.
handle_builtin_list()
{
    declare -p PSEUDO_BUILTIN
}

# 对传入的选项进行处理.该函数最多接收两个参数.
#     第一个参数: 选项名. 第二个参数: 选项的参数.
# 这个函数的返回值具有如下的取值:
# (1) 0 -- 表示传入一个合法选项(第一个参数以'-'开头),且该选项被正确处理.
# (2) 1 -- 表示传入一个非法选项(第一个参数以'-'开头),该选项没有被处理.
# (3) n -- 传入合法选项且其处理函数执行出错,返回最后一个执行命令的状态码.
# (4) 127 -- 表示传入的不是选项,即第一个参数不以'-'开头.
handle_option()
{
    if [ $# -gt 2 ]; then
        echo "Usage: ${FUNCNAME} option [argument]"
        return 1
    fi
    local option argument

    option="$1"
    argument="$2"

    # 调用parsecfg.sh脚本处理选项的函数来处理配置文件相关的选项.
    # 如果该选项被handle_config_option()识别并处理,就直接返回,不管处理
    # 成功还是失败,都不再往下处理.该函数返回127表示该选项没有被处理.
    handle_config_option "${option}" "${argument}"
    if [ $? -ne 127 ]; then
        return
    fi

    case ${option} in
        -h) tinyadb_show_help ;;
        -s) setup_interpreter ;;
        # 使用 -* 来匹配所有以 '-' 开头的字符串,如 -a, --help 等.
        -*) tinyadb_show_help && return 1 ;;
        # 上面的 -* 会过滤所有以'-'开头的字符串,执行到这个分支时,将
        # 匹配所有不以 '-' 开头的字符串,即传入的第一个参数不是选项.
        *) return 127 ;;
    esac

    # 当return语句不加上具体状态码时,它会返回上一条执行命令的状态码.
    return
}

# 处理所给的内容.这个内容可能是内置命令,命令选项,命令简写,或者命令本身.
handle_input()
{
    local key value cmd_line

    # 默认要执行的命令行是所提供的参数.如果该参数对应配置文件中的某个
    # 键名,则将要执行的命令行替换为该键名对应的键值.
    cmd_line="$@"

    # 判断所提供的命令是否为伪解释器内置命令.如果是,则进行特殊处理.
    # 如果处理成功,则退出该函数,不再往下执行.
    # 注意: 由于有的伪解释器内置命令接收参数,下面的${cmd_line}不能用
    # 双引号括起来,否则多个参数会被当成一个参数.
    handle_pseudo_builtin ${cmd_line}
    if [ $? -eq 0 ]; then
        return 0
    fi

    # 判断所提供的内容是否是命令选项.如果是,则当成命令选项处理.
    # 下面的 ${cmd_line} 不能用双引号括起来.
    handle_option ${cmd_line}
    # 当 handle_option() 函数返回 127 时,表示${cmd_line}不以'-'开头,不是
    # 一个选项,将会继续往下处理.如果${cmd_line}以'-'开头且不是合法选项时,
    # handle_option() 函数返回 1.此时不再继续往下处理,直接返回.
    if [ $? -ne 127 ]; then
        return
    fi

    # 判断所给的参数是否对应配置文件中的某个键名.如果是,将取出键值.
    key="$1"
    value="$(get_value_by_key "${key}")"
    if [ $? -eq 0 ]; then
        cmd_line="${value}"
    fi

    # 当Android设备没有连接上时,执行adb命令会提示:"error: device not found"
    # adb wait-for-device命令可避免这种情况: block until device is online.
    ${ADB} wait-for-device

    # 由于 adb shell 是外部命令,Bash会在子shell中执行它.此时,该子shell不会
    # 继承其父shell所捕获的陷阱,其父shell所捕获的陷阱会被重置为该父shell的
    # 父进程的值.由于交互式Bash默认捕获SIGINT并终止前台进程,此时,子shell也
    # 会捕获SIGINT并终止前台进程.例如执行 adb shell logcat 命令时,这个命令
    # 会一直打印log信息,当输入Ctrl-C时,才终止打印.为了只终止这个打印,而不
    # 终止伪解释器,伪解释器的进程捕获了SIGINT.
    # 这里将 ${cmd_line} 用双引号括起来,避免 cmd_line 中的一些特殊符号提前
    # 被扩展.例如执行 ls /dev/ttyS* 命令时,由于linux下存在这几个文件,如果
    # 不加双引号的话, /dev/ttyS* 会按照linux系统下的文件名进行文件名扩展,
    # 再传递给adb shell.而原本的意思就是要传递 /dev/ttyS* 到adb shell,所以
    # 使用双引号来避免这种文件名扩展.由于扩展后的 /dev/ttyS* 不带双引号,
    # adb shell还是能对它进行文件名扩展.
    ${ADB_SH} "${cmd_line}"

    # 打印刚才执行的命令名.之所以先执行,再打印.是因为有些命令的输出很多,先
    # 打印命令名的话,需要拉动终端滚动条,才能找到打印出来的命令名,不方便.
    echo -e "\033[33m${cmd_line}\033[0m"
}

setup_interpreter()
{
    echo -e '\033[36mSetup a pseudo tinyadb shell\033[0m'

    # 捕获SIGINT信号.让输入Ctrl-C后,不能终止伪解释器.
    # 注意: 由于子shell会继承父shell所忽略的信号,所以伪解释器不能将SIGINT
    # 设成忽略,而是要设置一个处理函数.
    trap "handle_sigint" SIGINT

    # 如果不使用 -e 选项,输入上光标键, read 会读取到 "^[[A";输入下光标键,
    # read 会读取到 "^[[B".而使用 -e 选项后,输入上下光标键,不会读取到乱码,
    # 但是在子shell中,也不会返回历史命令.因为shell脚本是在非交互模式下执行.
    # 可以使用 bash 的 -i 选项让脚本在交互模式下运行,例如: "#/bin/bash -i"
    # 这个做法还有一个遗留问题,下面执行的命令不会被添加到历史命令中,即虽然
    # 可以使用上下光标键查找历史命令,但找不到这个脚本所执行的命令.使用 set
    # 命令开启 emacs, histexpand, history 选项也不起作用.目前无法解决.
    while read -ep "${PROMPT}" input; do
        # 传递参数给函数时,参数要用双引号括起来,避免参数中
        # 带有空格,从而被拆分成多个参数.
        # 当输入Ctrl-C后,由于伪解释器捕获了这个信号,read命令被中断,此时读取
        # 到的 input 是空,不需要对空行做处理.所以下面先判断input是否为空.
        if [ -n "${input}" ]; then
            handle_input "${input}"
        fi
    done

    # 输出一个换行,这样当用户输入Ctrl-D结束输入时,可以换行.强迫症而已
    echo; exit
}

# 解析 adb辅助命令 的配置文件.
# 如果执行 parsecfg.sh 解释配置文件失败,则退出,不再往下处理.
source parsecfg.sh "${ADB_HELPER}"
if [ $? -ne 0 ]; then
    exit 1
fi

# 当不带任何参数时,默认启用伪解释器.
if [ $# -eq 0 ]; then
    setup_interpreter
    exit
fi

# 解析脚本选项. getopts 在解析选项时,要求选项以'-'开头,但是解析出来的选项
# 不包含'-',而 handle_option() 函数在处理选项时,也要求选项以'-'开头,所以下
# 面在 getops 返回的选项值前面加上'-',以符合 handle_option() 函数的要求.
while getopts "hslvi:ea:d:" opt; do
    handle_option "-${opt}" "${OPTARG}"
done

# 如果传入的参数都是选项,则结束执行,否则会继续往下解析剩余的参数.
if [ $# -eq $((OPTIND-1)) ]; then
    exit 0
fi

# 移动脚本的参数,移除前面被处理的选项,只剩下待执行的命令参数.
shift $((OPTIND-1))
for arg in "$@"; do
    handle_input "$arg"
done
