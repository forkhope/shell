#!/bin/bash
# 该脚本用于在exdroid和lichee的各个目录之间快速cd.把各个路径和一些简单的
# 字母或数字对应起来,通过输入字母或数字来快速cd到那个路径,减少键盘输入.
# 例如执行 cdcode.sh b 会 cd 到 exdroid/framework/base 目录等.
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
DIRINFO="${HOME}/.myconf/dirinfo.txt"
# 保存 Android 目录下全局文件路径名的配置文件
LISTFILE="listfiles"

# 当一个路径简写以字符'+'开头时,表示进入该简写对应的目录下进行编译.
COMPILE_PREFIX="+"

# 指定编译 Android 时要 lunch 的分支名
BUILD_ENG="ococci-eng"
BUILD_USER="ococci-user"

# 当 search_files 变量等于1时,将会调用 godir() 函数进行全局查找.
# 一旦将这个变量设置为 1, 会在脚本执行期间一直生效.
declare search_files=0

# 该变量保存代码根目录的完整路径,后续作为要cd到的路径的一部分.
# !!注意!!: 不要在脚本开头为这个变量赋初值!每次 cd 时,都会执行这个脚本,但
# 不是每次 cd 都会设置代码根目录.在多次调用该脚本时,要保持该变量的值不变.
# declare project_root_dir=""

# 导入Android相关脚本的通用常量.
source android.sh
# 导入 cd_project_root() 函数的定义.
source procommon.sh
# 导入解析配置文件的脚本.要先定义 DIRINFO 变量的值,在 source 该脚本.
source parsecfg.sh "${DIRINFO}"
# 当 parsecfg.sh 解析配置文件失败时,则退出,不再往下执行.
if [ $? -ne 0 ]; then
    return 1
fi

cdcode_show_help()
{
printf "USAGE
        cdcode.sh [option] symbol
OPTIONS
        symbol: 要 cd 到的路径简写,支持的简写可以用-l或-v选项来查看.
                当一个路径简写以字符'+'开头时,表示进入该路径简写对应
                的目录下进行编译.
        option: 可选选项,描述如下:
            -h: 打印这个帮助信息.
            -f: 如果找不到所给的symbol,则进行全局文件搜索.
            -p: 打印当前所在的代码根目录
            -r: 设置代码切换的根目录,需要一个参数,来指定代码的根目录路径.
            -s: 进行source并lunch的操作,但是不进行编译.
            -n: 先编译lichee,再编译android.
            -m: 在Android根目录下,进行android全编译.
            -x: 在lichee根目录下,进行lichee全编译.
            -g: 编译android gms固件.
            -l: 查看脚本支持的路径简写及其对应的路径.
            -v: 以键值对的方式打印详细的配置文件信息.
            -i: 在配置文件中查找指定内容.需要一个参数来指定要查找的内容.
            -e: 使用vim打开脚本的配置文件,以供编辑.
            -a: 增加或修改一个路径简写和对应的路径到配置文件.需要一个参数, 
                用单引号括起来,以指定路径简写和路径.格式为: 路径简写|路径
                例如 -a 'p|exdroid/packages/apps/Phone',如果 p 简写还不存
                在新增它,否则修改它.注意:路径要求以exdroid/或者lichee/开头.
            -d: 从脚本配置文件中删除一个路径简写和对应的路径.需要一个
                参数,以指定路径简写,脚本将从配置文件中删除该路径简写
                对应的行. 例如 -d a, 将删除路径简写为 a 的行.
"
}

# 检查传入的路径是否以exdroid/或者lichee/开头,如果是,返回0,否则返回1.
# 这个函数主要是防止传入的路径不符合要求,目前不需要,先注释,要用时再打开.
# check_pathheader()
# {
#     local head path
# 
#     path="$1"
#     head="${path%%/*}"
#     # expr1 -a expr2 表示执行一个与运算,要求这两个表达式都为真
#     if [ "${head}" != "${EXDROID}" -a "${head}" != "${LICHEE}" ]; then
#         echo "出错,路径要求以exdroid/或者lichee/开头"
#         return 1
#     fi
#     return 0
# }

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
    # 检查所设置的代码根目录下是否包含 "exdroid" 目录.如果包含,则这个
    # 代码根目录符合要求,否则不符合要求,不为project_root_dir变量赋值.
    pwd_dir_check "${EXDROID}"
    if [ $? -eq 0 ]; then
        project_root_dir=$(pwd)
        EXDROID_ROOT_DIR=${project_root_dir}/${EXDROID}
        LICHEE_ROOT_DIR=${project_root_dir}/${LICHEE}
    fi
}

# 如果之间的project_root_dir变量是/home/work/john/7-sw-a31s-4.4,而当前位于
# /home/work/john/6-sw-a31s-4.4-sdk4.6/目录下,那么需要更新代码根目录为当前
# 目录.一般而言,在当前目录下执行该脚本,是希望在当前目录下cd,如果不更新代码
# 根目录,则在目录6-sw-a31s-4.4-sdk4.6下执行该脚本,可能会cd到7-sw-a31s-4.4
# 目录下.此时,如果没有察觉到这一点,所做的改动就没有发生在预期的目录下.
# 如果当前目录路径中不包含lichee或者exdroid目录,则认为当前没有位于lichee或
# 者exdroid代码之下,将不会更新代码根目录,默认使用当前的代码根目录路径.
update_project_root()
{
    local dirpath current_root

    # 由于这个脚本会在"exdroid"和"lichee"目录之间相互切换,例如当前路径为
    #   "/home/work/john/1-cs-a31s-4.2-x10-g3/lichee/linux-3.3/drivers"
    # 这个路径不包含"exdroid",则后面的 ${dirpath%/exdroid*} 就匹配失败,
    # 无法提取出正确的代码根目录.所以这里将当前路径中的"lichee"替换为
    # "exdroid",以便能匹配成功.如果路径中不包含"lichee",则不进行替换,不会
    # 造成影响.注意一下 pwd 和 PWD 的区别, pwd是shell命令,而 PWD是shell变
    # 量,Bash的字符串操作要以shell变量作为参数,所以用PWD,不能用小写的pwd.
    dirpath=${PWD/${LICHEE}/${EXDROID}}

    # 判断替换后的目录路径中是否包含"exdroid",如果不包含,不更新代码根目录.
    # 如果grep查找成功,会打印查找结果.为了不想显示查找结果,所以将它重定向.
    echo ${dirpath} | grep ${EXDROID} > /dev/null
    if [ $? -ne 0 ]; then
        return $?
    fi

    # 使用字符串匹配从当前路径中提取位于出"/exdroid"之前的内容.假设路径是
    #   "/home/work/john/6-sw-a31s-4.4-sdk4.6/exdroid/frameworks/base"
    # 则 "/exdroid*" 匹配上面的 "/exdroid/frameworks/base",除去该匹配外,
    # 剩余的内容是"/home/work/john/6-sw-a31s-4.4-sdk4.6",下面的字符串匹配
    # 得到的内容就是这个值,可以用于和 project_root_dir 变量的值进行比较.
    # current_root=${dirpath%/${EXDROID}*}
    #
    # 按照上面的语句会提取出"/exdroid"之前的内容,实际执行时遇过这样的情况:
    # 有一个路径名是: /home/work/john/2-sw-a31s-4.4-mt915/sys-lichee
    # 经过上面的替换后是: /home/work/john/2-sw-a31s-4.4-mt915/sys-exdroid
    # 用 grep 命令来查找路径名是否带有"exdroid",此时是匹配的,又试图提取出
    # "/exdroid"之前内容时,则提取不到. "sys-exdroid" 匹配 "/*exdroid*" 这
    # 个模式,不匹配 "/exdroid*" 模式,所以下面将模式改成 "/*exdroid*".
    current_root=${dirpath%/*${EXDROID}*}
    if [ "${project_root_dir}" != "${current_root}" ]; then
        echo "将代码根目录从 ${project_root_dir} 更新到 ${current_root}"
        setup_project_root "${current_root}"
    fi
}

# 强制在"exdroid"目录下 source 和 lunch,不判断是否已经source过.
source_and_lunch()
{
    # 如果 project_root_dir 变量为空,则还没有设置代码根目录,报错返回
    if [ -z "${project_root_dir}" ]; then
        echo "要先执行 $(basename $0) -r project_root_dir 设置代码根目录!"
        return 1
    fi

    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME build_variant"
        return 1
    fi

    # 指定要 cd 到的绝对路径,以便从Android代码的子目录跳转到"exdroid"目录
    \cd "${EXDROID_ROOT_DIR}"

    source build/envsetup.sh
    # 在Android的"build/envsetup.sh"脚本中,有一个print_lunch_menu()函数可以
    # 打印所有lunch分支,格式类似于"1. aosp_arm-eng".其中,1 是lunch分支编号,
    # "aosp_arm-eng"是lunch分支名. lunch命令可以接收lunch分支名或者lunch分
    # 支编号来指定要lunch的分支.下面用grep查找特定的分支,并用awk提取出分支
    # 名,将分支名作为参数传给 lunch 命令,从而自动lunch需要的分支.
    lunch $(print_lunch_menu | grep "${1}" | awk '{print $2}')
}

compile_lichee()
{
    \cd ${LICHEE_ROOT_DIR} && bulichee.sh
    if [ $? -ne 0 ]; then
        echo -e '\033[31m编译 lichee 出错!\033[0m'
        return 1
    fi
}

compile_android()
{
    source_and_lunch "${BUILD_ENG}" && \
        extract-bsp && make -j8 && pack && pack -d
    if [ $? -ne 0 ]; then
        echo -e '\033[31m编译 Android 出错!\033[0m'
        return 1
    fi
}

compile_gms()
{
    source_and_lunch "${BUILD_USER}" && extract-bsp && make -j8
    if [ $? -ne 0 ]; then
        get_uboot && make -j8 dist && pack -s && pack -d -s
    else
        echo -e '\033[31m编译GMS固件出错!\033[0m'
        return 1
    fi
}

compile_all()
{
    compile_lichee && compile_android
    if [ $? -ne 0 ]; then
        return 1
    fi
}

# 保存Android源码各个目录和文件的名字到${LISTFILE}文件里面,然后可以在该
# 文件中查找指定的文件名,如果只找到一个就直接 cd 到该文件所在的目录.如果
# 找到多个匹配项,就弹出列表给用户选择,选择之后再 cd 过去.
godir() {
    if [[ -z "$1" ]]; then
        echo "Usage: godir <regex>"
        return
    fi
    local T="${project_root_dir}/${EXDROID}"
    if [[ ! -f $T/${LISTFILE} ]]; then
        echo -n "Creating index..."
        \cd $T
        find . \( -path "*test*" -o -path "*git*" -o -path "./out" \
            -o -path "./cts" -o -path "./gdk" -o -path "./ndk" \
            -o -path "./pdk" -o -path "./sdk" -o -path "./abi" \
            -o -path "./art" -o -path "./.repo" -o -path "*docs" \
            -o -path "*tools" -o -path "./libnativehelper" \
            -o -path "./dalvik" -o -path "./prebuilt" \
            -o -path "libcore" -o -path "./development" \) -prune \
            -o -type f > ${LISTFILE}
            # -o -regex '.*\.\(c\|xml\|cpp\|h\|java\|rc\|mk\|fex\)'
        echo " Done"
    fi
    local lines
    lines=($(\grep "$1" $T/${LISTFILE}|sed -e 's/\/[^/]*$//'|sort|uniq))
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
    local key alif to_do dir_value

    key="$1"
    # 获取路径简写的首字母.如果首字母是'+',则进到该简写对应的目录下进行编译
    # 注意: 要先source之后,才能执行mm命令.为了避免多次source,不会在每次mm之
    # 前都执行一次source,所以要求先source,再执行这个编译命令,否则编译报错.
    alif="${key:0:1}"
    if [ "${alif}" == "${COMPILE_PREFIX}" ]; then
        to_do="mm"
        # 此时,需要去掉'+'这个首字母,该字母不属于路径简写的一部分.
        key=${key:1}
    fi

    dir_value=$(get_value_by_key "${key}")
    if [ $? -eq 0 ]; then
        \cd ${project_root_dir}/${dir_value}
        ${to_do}
        return 0
    fi

    echo "找不到路径简写 '${key}' 对应的行"
    if [ ${search_files} -eq 1 ]; then
        echo "尝试进行全局文件搜索 ..."
        godir ${key}
    fi
}

if [ $# -eq 0 ]; then
    cdcode_show_help
    return 1
fi

# 经过验证发现,用source命令来执行该脚本后,OPTIND的值不会被重置为1,导致
# 再次用source命令执行脚本时,getopts解析不到参数,所以手动重置OPTIND为1.
OPTIND=1
while getopts "hfpr:snmxglvi:ea:d:" opt; do
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
        f) search_files=1 ;;
        p) show_project_root ;;
        r) setup_project_root "$OPTARG" ;;
        s) source_and_lunch "${BUILD_ENG}" ;;
        n) compile_all ;;
        m) compile_android ;;
        x) compile_lichee ;;
        g) compile_gms ;;
        ?) cdcode_show_help ;;
    esac
done

# 如果传入的参数都是选项,就结束执行,否则会继续往下解析剩余的symbol参数.
if [ $# -eq $((OPTIND-1)) ]; then
    return 0
fi

# 尝试更新当前代码根目录,具体信息如该函数的注释所示.
update_project_root

# 移动脚本的参数,去掉前面输入的选项,只剩下表示路径简写的参数.
shift $((OPTIND-1))
for arg in "$@"; do
    handle_symbol "$arg"
done
