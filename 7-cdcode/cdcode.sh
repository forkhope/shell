#!/bin/bash
# 该脚本用于在Android源码下面的各个目录之间快速cd.把各个路径和一些简单的
# 字母或数字对应起来,通过输入字母或数字来快速cd到那个路径,减少键盘输入.
# 例如执行 cdcode.sh b 会 cd 到 framework/base 目录,或者配置的其他目录下,
# 另外,当一个路径简写以字符'+'开头时,表示进入该简写对应的目录下进行编译.

# 注意,在脚本内执行cd命令,当脚本退出时,不会保持在cd后的路径,而是恢复
# 原先的路径,该脚本需要保持在cd后的路径,此时需要用source命令来执行该
# 脚本,让脚本就在当前shell中执行,从而也能改变shell的工作目录.但此时,
# 脚本里面就不能执行exit语句,否则shell也会退出,而是要改成用return语句.
# 用了return语句后,如果不用source命令来执行该脚本,而是直接执行该脚本,
# 会提示return: can only `return' from a function or sourced script.
# 为了方便使用source命令来执行该脚本,可以在~/.bashrc中添加如下的语句:
# alias c='source ~/bin/cdcode.sh' # 注意单引号必不可少,也可改成双引号

# 脚本保存的路径简写及其对应路径的配置文件
DIRINFO="${HOME}/.liconfig/dirinfo.txt"

# 当一个路径简写以字符'+'开头时,表示进入该简写对应的目录下进行编译.
COMPILE_PREFIX="+"
# 指定编译 Android 时默认要 lunch 的分支名
# 将DEFAULT_LAUNCH_COMBO修改成要编译的project名称
DEFAULT_LAUNCH_COMBO="xxxxx-userdebug"

# 该变量保存代码根目录的完整路径,后续作为要cd到的路径的一部分.
# !!注意!!: 不要在脚本开头为这个变量赋初值!每次 cd 时,都会执行这个脚本,但
# 不是每次 cd 都会设置代码根目录.在多次调用该脚本时,要保持该变量的值不变.
# declare project_root_dir=""

# 导入Android相关的常量和函数
source android.sh
# 导入解析配置文件的脚本.要先定义 DIRINFO 变量的值,再 source 该脚本.
source parsecfg.sh "${DIRINFO}"
# 当 parsecfg.sh 解析配置文件失败时,则退出,不再往下执行.
if [ $? -ne 0 ]; then
    return 1
fi

cdcode_show_help()
{
printf "USAGE
        cdcode.sh [option] [symbol]
OPTIONS
        option: 可选选项,描述如下:
            -h: 打印这个帮助信息.
            -f: 在Android源码下查找指定的文件,需要一个参数来提供文件名.
            -p: 打印当前所在的代码根目录
            -r: 设置代码切换的根目录,需要一个参数,来指定代码的根目录路径.
            -s: 进行source并lunch的操作,但是不进行编译.
            -m: 在Android根目录下,进行android全编译.
            -l: 查看脚本支持的路径简写及其对应的路径.
            -v: 以键值对的方式打印详细的配置文件信息.
            -i: 在配置文件中查找指定内容.需要一个参数来指定要查找的内容.
            -e: 使用vim打开脚本的配置文件,以供编辑.
            -a: 增加或修改一个路径简写和对应的路径到配置文件.需要一个参数, 
                用单引号括起来,以指定路径简写和路径.格式为: 路径简写|路径
                例如: -a 'p|packages/apps/Phone',如果 p 简写还不存在会新增
                这个配置项,否则修改 p 简写对应的路径为新的路径.
            -d: 从脚本配置文件中删除一个路径简写和对应的路径.需要一个
                参数,以指定路径简写,脚本将从配置文件中删除该路径简写
                对应的行. 例如 -d a, 将删除路径简写为 a 的行.
        symbol: 可选选项,指定要 cd 到的路径简写,有效的简写可以用-l或-v选项来查看.
                当一个路径简写以字符'+'开头时,表示进入该路径简写对应
                的目录下进行编译.
        当不带任何参数且已经设置过代码根目录时,该脚本会cd到代码根目录下.
"
}

show_project_root()
{
    echo "当前所在代码根目录是: ${project_root_dir}"
}

setup_project_root()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME root_dir"
        return 1
    fi

    \cd "$1"
    # 检查所设置的代码根目录下是否包含 "frameworks" 目录.如果包含,则这个
    # 代码根目录符合要求,否则不符合要求,不为project_root_dir变量赋值.
    # 下面的pwd_check_sub_dir()函数和FRAMEWORK常量来自android.sh脚本.
    pwd_check_sub_dir "${FRAMEWORKS}"
    if [ $? -eq 0 ]; then
        project_root_dir="$(pwd)"
    fi
}

# 如果当前路径不位于代码根目录底下,打印一些提示信息,以便用户关注到这一点.
# 例如,代码根目录是 code/android,而当前用户所在路径是 test/android,可能
# 预期执行该脚本时会 cd 到 test/android/ 目录下的子目录,但实际会 cd 到
# code/android/ 目录下的子目录,就可能会修改到不预取目录的代码文件. 为了
# 避免这个问题,所以要打印提示信息.
# NOTE: 原本预期是可以自动更新代码根目录到当前路径下,但是目前无法通过路径
# 名来判断当前路径是否包含Android源码.如果是假设Android源码放在android目录
# 下,这会引入目录名的限制,目前不采用这种方法.
check_project_root()
{
    if [[ ! $(pwd) =~ "${project_root_dir}" ]]; then
        echo -e 当前路径'\033[31m' $(pwd) '\033[0m'位于设置的代码根目录之外,
        echo -e 将会跳转到'\033[32m' 代码根目录${project_root_dir} '\033[0m'底下的子目录!
    fi
}

source_and_lunch()
{
    # 如果 project_root_dir 变量为空,则还没有设置代码根目录,报错返回
    if [ -z "${project_root_dir}" ]; then
        echo "要先执行 $(basename $0) -r project_root_dir 设置代码根目录!"
        return 1
    fi

    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME launch_combo"
        return 1
    fi

    \cd "${project_root_dir}"
    source build/envsetup.sh
    # 在Android的"build/envsetup.sh"脚本中,有一个print_lunch_menu()函数可以
    # 打印所有lunch分支,格式类似于"1. aosp_arm-eng".其中,1 是lunch分支编号,
    # "aosp_arm-eng"是lunch分支名. lunch命令可以接收lunch分支名或者lunch分
    # 支编号来指定要lunch的分支.下面用grep查找特定的分支,并用awk提取出分支
    # 名,将分支名作为参数传给 lunch 命令,从而自动lunch需要的分支.
    lunch $(print_lunch_menu | grep "${1}" | awk '{print $2}')
}

compile_android()
{
    source_and_lunch "${DEFAULT_LAUNCH_COMBO}" && \
        make -j16 2>&1 | tee build_android.log
    if [ $? -ne 0 ]; then
        echo -e '\033[31m编译 Android 出错!\033[0m'
        return 1
    fi
}

# 保存Android源码各个目录和文件的名字到一个文本文件里面,然后可以在该
# 文件中查找指定的文件名,如果只找到一个就直接 cd 到该文件所在的目录.如果
# 找到多个匹配项,就弹出列表给用户选择,选择之后再 cd 过去.
# 这个函数复制自Android源码的build/make/envsetup.sh文件,进行了一些修改.
godir() {
    if [[ -z "$1" ]]; then
        echo "Usage: godir <regex>"
        return
    fi
    local T="${project_root_dir}/"
    local FILELIST="filelists"
    if [[ ! -f $T/${FILELIST} ]]; then
        echo -n "Creating index..."
        \cd $T
        find ./bionic ./build ./device ./external \
            ./frameworks ./hardware ./kernel \
            ./packages ./system ./vendor \
            \( -path "*test*" -o -path "*tools" -o -path "*docs" \
            -o -path "*git*" -o -path "*svn" \) -prune \
            -o -print -o -type f \
            | grep "\.[a-z]" | grep -v -E "\.html|\.txt" > $FILELIST
            # -o -regex '.*\.\(c\|xml\|cpp\|h\|java\|rc\|mk\|fex\)'
        echo " Done"
    fi
    local lines
    lines=($(\grep "$1" $T/${FILELIST}|sed -e 's/\/[^/]*$//'|sort|uniq))
    if [[ ${#lines[@]} = 0 ]]; then
        echo "Not found"
        return
    fi
    local pathname
    local choice
    if [[ ${#lines[@]} > 1 ]]; then
        while [[ -z "$pathname" ]]; do
            local index=1
            local line
            for line in ${lines[@]}; do
                printf "%6s %s\n" "[$index]" $line
                index=$(($index + 1))
            done
            echo
            echo -n "Select one: "
            unset choice
            read choice
            if [[ $choice -gt ${#lines[@]} || $choice -lt 1 ]]; then
                echo "Invalid choice"
                continue
            fi
            pathname=${lines[$(($choice-1))]}
        done
    else
        pathname=${lines[0]}
    fi
    echo -e "\033[33mFind it. Let's Go !!!\033[0m"
    \cd $T/$pathname
}

handle_symbol()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME symbol"
        return 1
    fi
    local key prefix mm_cmd dir_value

    key="$1"
    # 获取路径简写的首字母.如果首字母是'+',则进到该简写对应的目录下进行编译
    # 注意: 要先source之后,才能执行mm命令.为了避免多次source,不会在每次mm之
    # 前都执行一次source,所以要求先source,再执行这个编译命令,否则编译报错.
    prefix="${key:0:1}"
    if [ "${prefix}" == "${COMPILE_PREFIX}" ]; then
        mm_cmd="mm"
        # 此时,需要去掉'+'这个首字母,该字母不属于路径简写的一部分.
        key=${key:1}
    fi

    dir_value=$(get_value_by_key "${key}")
    if [ $? -eq 0 ]; then
        \cd ${project_root_dir}/${dir_value}
        if [ -n "${mm_cmd}" ]; then
            ${mm_cmd}
        fi
        return 0
    fi

    echo "找不到路径简写 '${key}' 对应的行"
    return 1
}

if [ $# -eq 0 ]; then
    if [ -z "${project_root_dir}" ]; then
        # 如果 project_root_dir 变量为空,则还没有设置代码根目录,打印帮忙信息
        echo "NOTE: 还没有设置代码根目录,请参考脚本说明设置代码根目录."
        cdcode_show_help
    else
        # 如果 project_root_dir 变量不为空,这不带参数时,默认cd到代码根目录下
        \cd "${project_root_dir}"
    fi
    # 由于不带参数,不需要往下处理,直接return
    return 0
fi

# 经过验证发现,用source命令来执行该脚本后,OPTIND的值不会被重置为1,导致
# 再次用source命令执行脚本时,getopts解析不到参数,所以手动重置OPTIND为1.
OPTIND=1
while getopts "hf:pr:smlvi:ea:d:" opt; do
    # 调用parsecfg.sh脚本处理选项的函数来处理配置文件相关的选项.
    # 如果处理成功,就直接继续读取下一个选项,不再往下处理.
    # handle_config_option()函数要求传入的选项以'-'开头,而getopts命令
    # 返回的选项不带有'-',所以下面在 ${opt} 前面加上一个 '-'.
    handle_config_option "-${opt}" "${OPTARG}"
    if [ $? -ne 127 ]; then
        continue
    fi

    case $opt in
        h) cdcode_show_help ;;
        f) godir "$OPTARG" ;;
        p) show_project_root ;;
        r) setup_project_root "$OPTARG" ;;
        s) source_and_lunch "${DEFAULT_LAUNCH_COMBO}" ;;
        m) compile_android ;;
        ?) cdcode_show_help ;;
    esac
done

# 如果传入的参数都是选项,就结束执行,否则会继续往下解析剩余的symbol参数.
if [ $# -eq $((OPTIND-1)) ]; then
    return 0
fi

# 检测当前路径是否位于代码根目录下,如果不是,打印一些提示信息.
check_project_root

# 移动脚本的参数,去掉前面输入的选项,只剩下表示路径简写的参数.
shift $((OPTIND-1))
# 循环遍历所有剩余的参数,可以处理传入多个参数的情况.
# 例如执行 cdcode.sh -r rootdir a 命令,可以先设置代码根目录,
# 并cd到a简写对应的目录下.执行cdcode.sh -r rootdir -s +a 命令
# 就会设置代码根目录,并进行source,然后到a简写对应的目录下编译.
# 这种情况要注意提供的参数顺序,如果写为cdcode.sh a -r rootdir,
# 会在解析a简写时发现还没有设置代码根目录导致报错.
for arg in "$@"; do
    handle_symbol "$arg"
done
