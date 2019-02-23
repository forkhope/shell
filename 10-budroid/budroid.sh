#!/bin/bash
# 该脚本用于在exdroid上快速编译一个或多个目标,传入要编译的目标简写,
# 脚本会根据这些简写从配置文件里面找到目标所在目录,并cd进去进行编译.

# 由于在脚本中执行source build/envsetup.sh后,并不能导出ANDROID_BUILD_TOP
# 变量到SHELL里面,还是需要用source命令来执行该脚本才行.所以,该脚本里面不
# 能使用exit语句,否则SHELL也会跟着退出.可以在~/.bashrc中添加如下语句:
# alias bue='source ~/bin/budroid.sh', 以方便用source命令执行该脚本.
EXDROID="exdroid"
LICHEE="lichee"

# 脚本保存路径简写及其对应路径的配置文件
BUEXDROIDINFO="${HOME}/.myconf/budirinfo.txt"

# 指定编译时要 lunch 的分支名
BUILD_ENG="ococci-eng"
BUILD_USER="ococci-user"

show_help()
{
printf "USAGE
        $(basename $0) [option] symbol
OPTIONS
        symbol: 要 cd 到的路径简写,支持的简写可以用-l选项来查看.
                每次执行脚本,只能提供一个symbol,只能cd到一个路径.
        option: 可选选项,描述如下:
            -h: 打印这个帮助信息,并退出.
            -l: 查看脚本支持的路径简写及其对应的路径.
            -p: 打印当前所在的Android代码根目录
            -r: 进行source并lunch的操作,但是不进行编译.
            -n: 先编译lichee,再编译android.
            -m: 在Android根目录下,进行android全编译
            -g: 编译android gms固件.
            -e: 使用vim打开脚本的配置文件,以供编辑.
            -a: 增加或修改一个路径简写和对应的路径到配置文件.需要一个参数, 
                用单引号括起来,以指定路径简写和路径.格式为: 路径简写|路径
                例如 -a 'p|packages/apps/Phone',如果 p 简写还不存在新增它,
                否则修改它.注意:路径是从Android根目录下的子目录开始的.
            -d: 从脚本配置文件中删除一个路径简写和对应的路径.需要一个
                参数,以指定路径简写,脚本将从配置文件中删除该路径简写
                对应的行. 例如 -d a, 将删除路径简写为 a 的行.
"
}

# 打印脚本支持的路径简写及其对应的路径.
show_dirinfo()
{
    echo "脚本支持的路径简写及其对应的路径为:"
    cat ${BUEXDROIDINFO}
}

# 从传入的项中提取出路径简写,并把该路径简写写到标准输出
get_symbol_of_entry()
{
    local entry=$1
    echo ${entry%%|*}
}

# 从传入的项中提取出路径,并把该路径写到标准输出
get_path_of_entry()
{
    local entry=$1
    echo ${entry#*|}
}

# 该函数在BUEXDROIDINFO文件中查找传入的路径简写,如果找到,返回0,并将所找到
# 的行写到标准输出,调用者可以获取该标准输出来获取查找到的行.找不到会返回非0
search_dirinfo_by_symbol()
{
    local short match ret
    short=$1
    match=$(grep "^${short}|" < ${BUEXDROIDINFO})
    ret=$?
    echo ${match}
    return ${ret}
}

# 该函数在配置文件中查找整个项.如果找到,返回0,否则返回非0. 它里面调用
# search_dirinfo_by_symbol()函数,这个函数会将找到的项写到标准输出,在
# 本函数里面不要读取该标准输出,这样,这个标准输出会被本函数继承,就像
# 是这个标准输出是由本函数输出一样,照样可以使用v=$(search_dirinfo_by_entry)
# 来读取到这个标准输出. 目前这个函数没有被调用,先注释,有需要再打开
# search_dirinfo_by_entry()
# {
#     # 获取传入的项,并根据传入的项匹配出路径简写
#     s_entry=$1
#     s_symbol=$(get_symbol_of_entry ${s_entry})
# 
#     # 在配置文件中查找传入的路径简写,如果找到,就删除已经存在的项
#     search_dirinfo_by_symbol ${s_symbol}
#     return $?    
# }

# 根据传入的路径简写删除配置文件中对应该路径简写的行
delete_entry()
{
    local symbol=$1
    # 这里要在${symbol}的前面加上^,要求${symbol}必须在行首
    sed -i "/^${symbol}|/d" ${BUEXDROIDINFO}
}

# 该函数用于编辑脚本配置文件中的一项,传入一个参数,该参数就是完整的一项.
# 如 "p|exdroid/packages/apps/Phone",当p这个路径简写还没有包含在配置文件
# 中时,将把该项追加到配置文件末尾.如果 p 这个路径简写已经存在于配置文件中,
# 则删除已经存在的项,再把新的项追加到配置文件末尾.
add_dirinfo_entry()
{
    if [ "$#" != "1" ]; then
        echo "Usage: $FUNCNAME dirinfo_entry"
        return 1
    fi
    local dirinfo_entry edit_symbol match_entry
    dirinfo_entry=$1

    edit_symbol=$(get_symbol_of_entry ${dirinfo_entry})
    # 注意,不要在下面两个语句之间添加任何语句,否则后面的$?获取到的
    # 将不是下面这条语句的执行结果.特别是不要添加echo调试语句.
    match_entry=$(search_dirinfo_by_symbol ${edit_symbol})
    if [ "$?" == "0" ]; then
        echo "更新 ${match_entry} 路径项为: ${dirinfo_entry}"
        delete_entry ${edit_symbol}
    fi

    # 追加新的项到配置文件末尾
    echo ${dirinfo_entry} >> ${BUEXDROIDINFO}
}

# 根据传入的路径简写,删除它在配置文件中对应的行
delete_dirinfo_entry()
{
    if [ "$#" != "1" ]; then
        echo "Usage: $FUNCNAME symbol"
        return 1
    fi
    local symbol match

    symbol=$1

    # 这里获取search_dirinfo_by_symbol()函数的标准输出,没有什么用,
    # 只是search_dirinfo_by_symbol中执行echo输入匹配的行,由于不想
    # 打印该匹配行到标准输出,所以读取它,让它不会打印出来.
    match=$(search_dirinfo_by_symbol ${symbol})
    if [ "$?" == "0" ]; then
        delete_entry ${symbol}
    else
        echo "出错,找不到路径简写 ${symbol} 对应的行"
    fi
}

edit_dirinfo_file()
{
    vim ${BUEXDROIDINFO}
}

show_exdroid_root()
{
    echo "当前source的Android根目录是: ${EXDROID_ROOT_DIR}"
}

source_and_lunch()
{
    # 检查当前已经已经位于"exdroid"目录下,如果没有位于,则弹出选择列表,选择
    # 要 cd 到目录.如果已经位于,则不需要 cd,而是直接就source和lunch
    # 下面这个判断语句判断当前目录的上一级目录是否有一个"exdroid"子目录,如
    # 果有,就认为已经位于"exdroid"目录下.这个判断实际上会有问题.如果当前位
    # 于"lichee"目录下,则该目录的上一级目录确实有一个"exdroid"目录,但当前
    # 并不在exdroid目录下.所以改成用dirname命令获取当前路径的最后一个文件
    # 名,并判断该文件名是否等于"exdroid",如果等于,才是位于"exdroid"目录下.
    # local check_root=$(ls .. | grep ${EXDROID})
    local check_root=$(basename $(pwd))
    if [ "${check_root}" != "${EXDROID}" ]; then
        source procommon.sh foo bar
        cd_project_root "${HOME}" "${EXDROID}"
        cd ${EXDROID}
    fi

    source build/envsetup.sh
    # 在Android源码中,执行上面的"source build/envsetup.sh"语句后,会导出一个
    # print_lunch_menu()函数用于打印各个lunch分支,之后可以用grep命令来查找
    # 特定的分支名,从而自动lunch需要的分支.目前,特定的分支名会包含"ococci".
    lunch $(print_lunch_menu | grep "${1}" | awk '{print $2}')
}

# 该函数接收一个参数,用于指定编译时的 lunch 分支名
check_exdroid_root_dir()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME build_variant"
        return 1
    fi
    local resource build_top current_top

    resource=0
    # 在编译Android时,需要执行source和lunch命令,执行之后,会导出一些环境
    # 变量,其中ANDROID_BUILD_TOP变量保存当前Android代码的根目录路径,如
    # ANDROID_BUILD_TOP=/home/work/john/8-sw-a13-4.2/exdroid
    # 所以,当ANDROID_BUILD_TOP变量为空时,就需要执行source和lunch命令
    if [ "${ANDROID_BUILD_TOP}" == "" ]; then
        echo "还没有 source 和 lunch 过, 尝试执行这两个操作"
        resource=1
    else
        # 如果ANDROID_BUILD_TOP变量不为空,说明已经source过,下面判断当前
        # 的Android目录是否和source过的Android目录为同一个目录.例如,
        # source的是8-sw-a13-4.2目录,而当前是位于3-cs-a13-4.2目录,那么就
        # 需要重新在当前Android目录下source和lunch.
        # 下面从ANDROID_BUILD_TOP变量保存的路径名中提取出第5个字段,认为
        # 该字段是Android目录所在的父目录名.这个是根据实际的目录结构来的,
        # 不具有移植性.在"/home/work/john/8-sw-a13-4.2/exdroid"中,执行
        # awk -F '/'后, $1 是"", 表示/home前面的那部分,而这部分正好是空.
        # $2是home,$3是work,以此类推,$5就是8-sw-a13-4.2
        build_top=$(echo ${ANDROID_BUILD_TOP} | awk -F '/' '{print $5}')
        # 下面获取当前Android目录所在的父目录名,如果当前工作目录不包含
        # 4个'/',则执行awk -F '/'之后,$5会是空,也可以用于做判断.
        current_top=$(pwd | awk -F '/' '{print $5}')
        if [ "${build_top}" != "${current_top}" ]; then
            echo "当前的exdroid目录不是之前source过的目录,重新source"
            resource=1
        fi
    fi
    if [ ${resource} -eq 1 ]; then
        source_and_lunch "${1}"
    fi
    # 保存ANDROID_BUILD_TOP变量的值到EXDROID_ROOT_DIR中
    EXDROID_ROOT_DIR=${ANDROID_BUILD_TOP}
    LICHEE_ROOT_DIR=${EXDROID_ROOT_DIR}/../${LICHEE}
}

compile_all()
{
    check_exdroid_root_dir "${BUILD_ENG}"
    \cd ${LICHEE_ROOT_DIR}

    bulichee.sh && \cd ${EXDROID_ROOT_DIR} && extract-bsp \
        && make -j8 && pack && pack -d
    if [ $? -ne 0 ]; then
        echo -e '\033[31m编译出错!\033[0m'
    fi
}

compile_android()
{
    check_exdroid_root_dir "${BUILD_ENG}"
    cd ${EXDROID_ROOT_DIR} && extract-bsp && make -j8 && pack && pack -d
    if [ $? -ne 0 ]; then
        echo -e '\033[31m编译 Android 出错!\033[0m'
    fi
}

compile_gms()
{
    check_exdroid_root_dir "${BUILD_USER}"
    cd ${EXDROID_ROOT_DIR} && extract-bsp && make -j8
    if [ $? -ne 0 ]; then
        get_uboot && make -j8 dist
        pack -s
        pack -d -s
    else
        echo -e '\033[31m编译GMS固件出错!\033[0m'
    fi
}

parse_symbol_cd_mm()
{
    if [ "$#" != "1" ]; then
        echo "Usage: $FUNCNAME symbol"
        return 1
    fi
    local symbol match dirpath

    symbol=$1
    match=$(search_dirinfo_by_symbol ${symbol})
    if [ "$?" == "0" ]; then
        dirpath=$(get_path_of_entry ${match})
        cd ${EXDROID_ROOT_DIR}/${dirpath}
        mm
    else
        echo "出错,找不到路径简写 ${symbol} 对应的行"
    fi
}

if [ ! -f "${BUEXDROIDINFO}" ]; then
    echo "ERROR: the ${BUEXDROIDINFO} doesn't exist"
    return 1
fi

if [ "$#" == "0" ]; then
    show_help
    return 1
fi

# 经过验证发现,用source命令来执行该脚本后,OPTIND的值不会被重置为1,导致
# 再次用source命令执行脚本时,getopts解析不到参数,所以手动重置OPTIND为1.
OPTIND=1
while getopts "hlprnmgea:d:" opt; do
    case $opt in
        h) show_help ;;
        l) show_dirinfo ;;
        p) show_exdroid_root ;;
        r) source_and_lunch "${BUILD_ENG}" ;;
        n) compile_all ;;
        m) compile_android ;;
        g) compile_gms ;;
        e) edit_dirinfo_file ;;
        a) add_dirinfo_entry $OPTARG ;;
        d) delete_dirinfo_entry $OPTARG ;;
        ?) show_help ;;
    esac
done

# 如果传入的参数都是选项,就结束执行,否则会继续往下解析剩余的symbol参数
if [ "$#" == "$((OPTIND-1))" ]; then
    return 0
fi

check_exdroid_root_dir "${BUILD_ENG}"

# 移动脚本的参数,去掉前面输入的选项,只剩下表示路径简写的参数
shift $((OPTIND-1))
for arg in "$@"; do
    parse_symbol_cd_mm $arg
done

return 0
