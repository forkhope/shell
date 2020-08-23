# 介绍一个可以在不同目录之间直接来回快速 cd 的 shell 脚本

本篇文章介绍一个可以在不同目录之间直接来回快速 cd 的 shell 脚本。

假设这个 shell 脚本的名称为 `quickcd.sh`。

在 Linux 下进行项目开发，特别是进行 Android 系统开发工作，经常需要使用 `cd` 命令切换 shell 的工作目录。

想象这样一个使用场景：
- 当前 shell 位于源码根目录的 *frameworks/base/packages/SystemUI/src/com/android/systemui/* 目录下。
- 接下来要进入源码根目录的 *packages/apps/Settings/src/com/android/settings/* 目录，使用 git 查看某个文件的修改记录。
- 那么需要先数一下 *frameworks/base/packages/SystemUI/src/com/android/systemui/* 这个路径有多少个目录。
- 数完发现有 8 个目录，执行 `cd ../../../../../../../../` 命令退回到源码根目录。在输入多个 `../` 时，特别麻烦，很容易出错。
- 然后执行 `cd packages/apps/Settings/src/com/android/settings/` 命令进入指定目录。期间要不停按 Tab 键补全目录名称。

可以看到，整个过程需要输入很多字符，非常麻烦。

实际上，在记录当前源码根目录的绝对路径之后，可以使用一些简单字符来对应一些常用的目录路径。

例如，用 *sui* 对应 *frameworks/base/packages/SystemUI/src/com/android/systemui/* 目录。

用 *ps* 对应 *packages/apps/Settings/src/com/android/settings/* 目录。

可以把这些简写字符传递给这里介绍的 `quickcd.sh` 脚本，就可以快速 cd 到对应的目录。

例如，执行 `source quickcd.sh ps` 命令，`quickcd.sh` 获取到 *ps* 对应 *packages/apps/Settings/src/com/android/settings/* 目录。

然后自动在这个目录前面加上当前源码根目录的绝对路径，就可以使用 `cd` 命令直接进入到对应的目录。

这样只需要输入很少的字符，并省去了执行 `cd ../../../` 这个步骤。

后面会介绍如何设置命令别名来避免输入 `source quickcd.sh` 这些字符，进一步减少输入，更加方便。

# 配置目录路径简写
如之前说明，可以用 *sui* 表示 *frameworks/base/packages/SystemUI/src/com/android/systemui/* 目录。

这个 *sui* 称之为 “路径简写”。

路径简写使用一些简单字符来表示特定的目录路径。

为了方便动态添加、删除、查询路径简写，可以把这些路径简写保存在一个配置文件里面。

在执行 `quickcd.sh` 脚本时，会读取配置文件内容，获取到各个配置项的值。

配置项的基本格式是：路径简写|目录路径

一个参考的配置文件内容如下所示：
```
b|frameworks/base
sui|frameworks/base/packages/SystemUI/src/com/android/systemui
ps|packages/apps/Settings/src/com/android/settings
```

这些配置的目录路径都是 Android 源码根目录下的相对路径。

在实际执行 `cd` 命令的时候，会自动上它们所在的 Android 源码根目录的绝对路径。

这个绝对路径是在运行时通过命令选项所指定。只需要指定一次，会一直生效。

解析配置文件时，需要用到之前文章介绍的 `parsecfg.sh` 脚本。

要获取 `parsecfg.sh` 脚本的代码，可以查看之前的文章。

当然，这个脚本并不只限于用在 Android 源码目录上。

`quickcd.sh` 脚本支持指定任意的顶层目录路径。

例如，可以指定 Linux 的 HOME 目录，配置 HOME 底下各个目录的路径，就可以进行切换。

后面会提供具体测试的例子，可供参考。

# 脚本代码
列出 `quickcd.sh` 脚本的具体代码如下所示。

在这个代码中，对大部分关键代码都提供了详细的注释，方便阅读。

这篇文章的后面也会对一些关键点进行说明，有助理解。
```bash
#!/bin/bash
# 该脚本用于在所指定顶层目录底下的各个目录之间直接来回快速 cd.
# 把各个目录路径和一些简单的字符对应起来,通过解析预先配置的文本文件,获取
# 路径简写和对应要 cd 到的目录路径. 基本配置格式为: 路径简写|目录路径
# 例如配置 "b|frameworks/base",则 b 是路径简写, frameworks/base 是对应的
# 路径.在顶层目录底下的任意一个目录里面,都可以执行 source quickcd.sh b
# 命令来直接 cd 到 framework/base 目录下,不需要先退回到顶层目录再执行 cd.
# 为了让脚本执行结束后,还保持在 cd 后的目录,需要用 source 命令来执行
# 当前脚本. 可以在 ~/.bashrc 文件中添加如下语句来设置命令别名:
#   alias c='source quickcd.sh'
# 后续执行 c 命令,就相当于执行 source quickcd.sh 命令.
# 这里假设 quickcd.sh 脚本放在 PATH 指定的寻址目录下.例如 /usr/bin 目录.
# 如果 quickcd.sh 脚本没有放在默认的寻址目录下,请指定完整的绝对路径.

# 下面变量指定默认解析的配置文件名.该文件配置了路径简写、以及对应的路径.
# 这个 dirinfo.txt 文件需要预先配置好,放到 HOME 目录的 .liconfig 目录下.
DEFAULT_DIRINFO="${HOME}/.liconfig/dirinfo.txt"

# PARSECFG_filepath 是 parsecfg.sh 脚本里面的变量. 如果这个变量为空,
# 说明还没有打开过配置文件,进入下面的分支打开默认的配置文件.由于当前的
# quickcd.sh 脚本和 parsecfg.sh 脚本都是通过 source 命令来调用.只要
# source 过一次,导出到调用者 shell 的全局变量和函数会一直有效.所以只有
# PARSECFG_filepath 变量为空才 source parsecfg.sh,避免多次打开配置文件.
if [ -z "$PARSECFG_filepath" ]; then
    # 导入解析配置文件的脚本,以便调用该脚本的函数来解析配置文件.
    source parsecfg.sh
    # 调用 parsecfg.sh 里面的 open_config_file() 函数解析配置文件.
    open_config_file "$DEFAULT_DIRINFO"
    # 当 parsecfg.sh 脚本解析配置文件失败时,则退出,不再往下执行.
    if [ $? -ne 0 ]; then
        return 1
    fi
fi

# 由于不同源代码的目录结构可能不同,当在不同的源代码目录中使用
# 当前脚本来切换时,需要指定不同的配置文件.下面函数就用于打开
# 用户指定的配置文件名. 所给的第一个参数指定配置文件名.
# 有一个特殊的文件名是 "default",表示要打开脚本默认的配置文件.
open_user_config_file()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME filepath"
        return 1
    fi

    local filepath
    if [ "$1" == "default" ]; then
        filepath="$DEFAULT_DIRINFO"
    else
        filepath="$1"
    fi

    # 调用 parsecfg.sh 的 open_config_file 函数打开配置文件
    open_config_file "$filepath"
    # 当 return 后面不带参数时,默认返回上一个命令的状态码.
    return
}

# 下面的 DIRECTCD_TOP_DIR 变量用于保存设置的顶层目录路径.
# 当设置顶层目录为 code/ 时,后续实际 cd 的所有目录路径前面都会加上 code/.
# 这个设置是为了方便在指定的某个顶层目录(例如源码根目录)底下进行快速 cd.
# 例如,在一个大型项目代码中,这些代码都放在同一个顶层目录下,我们只需要配置
# 顶层目录下的子目录路径即可.实际切换目录时,会自动加上顶层目录,再进行 cd.
# NOTE: 不要在脚本开头为这个变量赋初值.每次 cd 时,都会执行这个脚本.但不是
#   每次 cd 都要设置顶层目录路径.在多次调用该脚本时,要保持该变量的值不变.
# DIRECTCD_TOP_DIR=""

quickcd_show_help()
{
printf "USAGE
    source quickcd.sh [option] [symbol]
OPTIONS
    option: 可选的选项参数,描述如下:
        -h: 打印当前帮助信息.
        -f: 指定要解析的配置文件名.后面跟着一个参数,指定具体的文件路径.
            如果所给文件名是 'default',表示要打开脚本默认的配置文件.
        -p: 打印当前设置的顶层目录和所解析的配置文件名.
        -s: 设置并cd到所给的顶层目录.后面跟着一个参数,指定具体的顶层目录.
        -r: 清空当前设置的顶层目录.
        -l: 查看脚本支持的路径简写及其对应的路径.
        -v: 以键值对的方式打印详细的配置文件信息.
        -i: 在配置文件中查找指定内容.需要一个参数来指定要查找的内容.
        -e: 使用 vim 打开脚本的配置文件,以供编辑.
        -a: 增加或修改一个路径简写和对应的路径到配置文件.后面跟着一个参数,
            用单引号括起来,以指定路径简写和路径. 格式为: 路径简写|路径
            例如: -a 'b|frameworks/base'.如果 b 简写还不存在,会新增
            这个配置项. 如果已经存在,会修改 b 简写对应的路径为新的路径.
        -d: 从脚本配置文件中删除一个路径简写和对应的路径.后面跟着一个
            参数,指定路径简写.脚本将从配置文件中删除该路径简写对应的行.
            例如 -d b, 将删除路径简写为 b 的行.
    symbol: 可选参数,指定要 cd 到的路径简写.支持的简写可以用-l或-v选项来查看.

    当不提供任何参数且已经设置过顶层目录时,该脚本会 cd 到顶层目录下.
NOTE
    可以使用 alias c='source quickcd.sh' 设置 c 别名来方便执行.
"
}

# 打印当前设置的顶层目录到标准输出.
show_top_dir()
{
    echo "当前设置的顶层目录路径是: ${DIRECTCD_TOP_DIR}"
    echo "当前解析的配置文件是: ${PARSECFG_filepath}"
}

# 该函数设置顶层目录路径. 所给的第一个参数指定顶层目录路径.
# 这个顶层目录路径可以是相对路径,或者绝对路径.
setup_top_dir()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME top_dir"
        return 1
    fi

    # 进入到所给的顶层目录路径底下,并检查 cd 命令是否执行成功.
    \cd "$1"
    if [ $? -eq 0 ]; then
        # 所给的顶层目录可以是相对路径.但是代码要获取该顶层目录的
        # 绝对路径,以便后续通过绝对路径寻址,不受工作目录的影响.
        DIRECTCD_TOP_DIR="$(pwd)"
    else
        echo "出错: 无法进入所给的顶层目录.请检查所给路径是否正确."
        return 2
    fi
}

# 重置 DIRECTCD_TOP_DIR 变量值为空.取消设置顶层目录路径.
# 由于这个脚本预期通过 source 命令调用.只要设置过顶层目录,在
# 当前 shell 中,DIRECTCD_TOP_DIR 变量就一直有值.在调试脚本代码时,
# 如果想要再次测试没有设置顶层目录的情况,只能重新打开终端,比较麻烦.
# 提供 -r 选项调用下面 reset_top_dir() 函数来重置所设置的顶层目录.
# 会一起设置 PARSECFG_filepath 变量值为空,以便重新解析配置文件.
reset_top_dir()
{
    DIRECTCD_TOP_DIR=""
    PARSECFG_filepath=""
}

# 如果当前路径不位于顶层目录底下,打印一些提示信息,以便用户关注到这一点.
# 例如,顶层目录是 code/dev/. 而当前所在的shell工作目录是 code/test/,
# 可能预期执行该脚本时会 cd 到 code/test/ 目录下的子目录,但实际会 cd
# 到 code/dev/ 目录下的子目录,这可能会修改到不预取目录的代码文件.
# 为了避免这个问题,这个函数打印一些提示信息,作为提醒.
check_top_dir()
{
    # 查看man bash的"Compound Commands"小节说明, =~ 判断左边字符串是否包含
    # 右边字符串.如果左边字符串包含右边的字符串,其返回状态码是0,否则返回1.
    if [[ ! $(pwd) =~ "${DIRECTCD_TOP_DIR}" ]]; then
        # 如果当前的工作目录不包含所给的顶层目录,说明没有位于顶层目录底下.
        echo -e 当前路径'\e[31m' $(pwd) '\e[0m'位于设置的顶层目录之外.
        echo -e 将会跳转到顶层目录'\e[32m' ${DIRECTCD_TOP_DIR} '\e[0m'底下的目录!
    fi
}

# 处理所给的路径简写,看配置文件中是否保存这个路径简写.
# 如果包含,就 cd 到该简写对应的目录底下.
# 所给的第一个参数指定路径简写.
handle_symbol()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME symbol"
        return 1
    fi
    local key="$1"

    # 调用 parsecfg.sh 的 get_value_by_key 函数获取所给的
    # 路径简写在配置文件中对应的目录路径.
    local dir_value=$(get_value_by_key "${key}")
    if test -n "${dir_value}"; then
        # 如果获取到路径简写对应的目录路径,则在该目录路径前面
        # 自动加上顶层目录路径,组成完整的绝对路径,然后进行 cd.
        \cd "${DIRECTCD_TOP_DIR}/${dir_value}"
        return
    fi

    echo "出错: 找不到路径简写 '${key}' 对应的行"
    return 2
}

# 经过验证发现,用source命令来执行该脚本后,OPTIND的值不会被重置为1,导致
# 再次用source命令执行脚本时,getopts解析不到参数,所以手动重置OPTIND为1.
OPTIND=1
while getopts "hf:ps:rlvi:ea:d:" opt; do
    # 调用parsecfg.sh脚本处理选项的函数来处理 "lvi:ea:d:" 这几个选项.
    # 如果处理成功,就直接继续读取下一个选项,不再往下处理.
    # handle_config_option()函数要求传入的选项以'-'开头,而getopts命令
    # 返回的选项不带有'-',所以下面在 ${opt} 前面加上一个 '-'.
    handle_config_option "-${opt}" "${OPTARG}"
    if [ $? -ne 127 ]; then
        continue
    fi

    case "$opt" in
        h) quickcd_show_help ;;
        f) open_user_config_file "$OPTARG" || return ;;
        p) show_top_dir ;;
        s) setup_top_dir "$OPTARG" || return ;;
        r) reset_top_dir ;;
        ?) echo "出错: 异常选项,请使用 -h 选项查看脚本的帮助说明." ;;
    esac
done

# $# 大于0,说明提供了命令参数. $# 等于OPTIND减去1,说明传入的参数都
# 是命令选项. 此时,直接结束执行,不需要执行后面解析symbol参数的语句.
# 下面的 -a 表示两个表达式都为真时才为真.表达式之间不要加小括号.
# Shell里面的小括号有特殊含义,跟C语言的小括号有些区别,加上会有问题.
if [ $# -gt 0 -a $# -eq $((OPTIND-1)) ]; then
    return 0
fi

# 下面判断 DIRECTCD_TOP_DIR 变量值是否为空.
# 如果为空,说明还没有设置顶层目录. 此时不再往下处理,直接报错返回.
if [ -z "${DIRECTCD_TOP_DIR}" ]; then
    echo -e "\e[31m还没有设置顶层目录,请使用-h选项查看脚本帮助说明.\e[0m"
    return 2
fi

# 检查当前路径是否位于顶层目录下.如果不是,打印一些提示信息.
check_top_dir

if [ $# -eq 0 ]; then
    # 执行该脚本不带参数时,默认 cd 到顶层目录下.
    \cd "${DIRECTCD_TOP_DIR}"
    # 由于不带参数,不需要往下处理,在 cd 之后直接返回.
    return 0
fi

# 移动脚本的参数,去掉前面输入的选项,只剩下表示路径简写的参数.
shift $((OPTIND-1))
# 循环遍历所有剩余的参数,可以处理传入多个参数的情况.
# 例如执行 source quickcd.sh -s topdir a 命令,可以先设置顶层目录,
# 然后 cd 到 a 简写对应的目录下. 这种情况要注意提供的参数顺序.
# 如果写为 source quickcd.sh a -s topdir 命令,会在解析 a 简写时
# 发现还没有设置顶层目录而报错.
for arg in "$@"; do
    handle_symbol "$arg"
done

return
```

# 代码关键点说明

## 建议设置命令别名来执行当前脚本
如脚本代码开头注释所示，需要使用 `source` 命令来执行 `quickcd.sh` 脚本，以便执行该脚本之后，可以保持在 `cd` 后的目录下。

即，执行的时候，需要写为 `source quickcd.sh`。

这样需要输入比较多的字符，而且也容易忘记提供 `source` 命令。

为了方便输入，在脚本注释中，建议设置命令别名来执行当前脚本。

例如，在 `~/.bashrc` 文件中添加下面语句来设置命令别名:
```bash
alias c='source quickcd.sh'
```
添加这个语句后，在当前终端中，需要执行 `source ~/.bashrc` 命令，这个别名才会生效。

也可以重新打开终端，在新打开的终端中，这个别名默认就会生效。

在别名生效之后，就可以使用 *c* 命令来执行 `quickcd.sh` 脚本。

例如，`c ps` 命令等价于 `source quickcd.sh ps` 命令。

这里假设 `quickcd.sh` 脚本放在 PATH 全局变量指定的寻址目录里面，通过文件名就可以执行，不需要指定文件的路径。

如果该脚本没有放在默认的寻址目录里面，需要提供文件的绝对路径。

这个脚本所调用的 `parsecfg.sh` 脚本也需要放在 PATH 全局变量指定的寻址目录里面。

否则需要修改 `quickcd.sh` 脚本代码，在 `source` 的时候提供 `parsecfg.sh` 脚本文件的绝对路径。

下面举例执行 `quickcd.sh` 脚本时，统一使用 *c* 这个命令别名。

# 使用默认配置文件的测试例子
`quickcd.sh` 脚本默认解析的配置文件是 HOME 目录下的 `.liconfig/dirinfo.txt` 文件。

可以配置为最常使用的路径简写。

假设这个文件的内容如下：
```
b|frameworks/base
sui|frameworks/base/packages/SystemUI/src/com/android/systemui
ps|packages/apps/Settings/src/com/android/settings
```

在 Android 源码中使用 `quickcd.sh` 脚本的例子如下：
```bash
$ c -s android
[android]$ c -p
当前设置的顶层目录路径是: /home/android
当前解析的配置文件是: /home/.liconfig/dirinfo.txt
[android]$ c -v
key='sui'       value='frameworks/base/packages/SystemUI/src/com/android/systemui'
key='b'         value='frameworks/base'
key='ps'        value='packages/apps/Settings/src/com/android/settings'
[android]$ c b
[android/frameworks/base]$ c sui
[android/frameworks/base/packages/SystemUI/src/com/android/systemui]$ c ps
[android/packages/apps/Settings/src/com/android/settings]$
```

执行 `c -s android` 命令设置顶层目录为当前目录下的 *android* 目录。

`-s` 选项用于设置顶层目录路径，具体使用说明可以查看脚本打印的帮助信息。

用 `c -p` 命令查看所设置的顶层目录绝对路径和解析的配置文件路径。

用 `c -v` 命令显示键值对形式的配置项信息，能够查看配置的各个路径简写和对应的目录路径。

执行 `c b` 命令跳转到 b 路径简写对应的目录，具体的目录是 *frameworks/base*。

`quickcd.sh` 脚本会用顶层目录的绝对路径 */home/android* 加上 *frameworks/base*，得到 */home/android/frameworks/base* 路径，然后用 `cd` 命令跳转到这个路径。

在上面方括号中间显示的目录路径就是当前 shell 的工作目录，不包含 HOME 目录前面的路径。

执行 `c sui` 命令跳转到 sui 路径简写对应的目录。

执行 `c ps` 命令跳转到 ps 路径简写对应的目录。

可以看到，使用 `quickcd.sh` 脚本可以直接在跨度非常大的目录之间跳转，非常方便。

# 使用 -f 选项指定配置文件的测试例子
由于不同顶层目录底下的目录结构可能不同，当在不同结构的目录下中使用当前脚本进行切换时，可以指定不同的配置文件。

`quickcd.sh` 脚本使用 -f 选项来指定配置文件的路径。

假设在当前目录下有一个 *sample/update/* 目录和一个 *sample/updatesh/* 目录。

且在 *sample/updatesh/* 目录下有一个 *userdirinfo.txt* 文件，该文件内容如下：
```
u|sample/update
sh|sample/updatesh
```

在当前目录下使用 `quickcd.sh` 脚本的例子如下：
```bash
$ c -f sample/updatesh/userdirinfo.txt
$ c -s .
$ c -v
key='sh'        value='sample/updatesh'
key='u'         value='sample/update'
$ c sh
[sample/updatesh]$ c u
[sample/update]$
```

执行 `c -f sample/updatesh/userdirinfo.txt` 命令指定新的配置文件。

执行 `c -s .` 设置顶层目录为当前目录。

用 `c -v` 命令查看配置的路径简写和对应的目录。

执行 `c u` 命令跳转到 u 路径简写对应的 *sample/update/* 目录。

执行 `c sh` 命令跳转到 sh 路径简写对应的 *sample/updatesh/* 目录。

可以看到，`quickcd.sh` 脚本是一个通用的脚本，适用于各种目录结构，并不只限于 Android 源码目录。
