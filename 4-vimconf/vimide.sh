#!/bin/bash
# 该脚本生成vim IDE插件的相关数据文件,例如 ctags, cscope, lookupfile, gtags 等.
# 由于 gtags 同时包含了类似 ctags/cscope/lookupfile 的功能,目前只配置 gtags.
#
# 已知问题(1): 目前gtags不支持用"Ctrl-]"来跳转到变量定义处(计划支持).当要跳转到
#   变量定义时,文件自身定义的变量可以用vim自身的gD命令来跳转,文件外的变量没有好
#   方法来跳转(除非用集成ctags来解析).可以先用cs find s命令查找这个变量所有被引
#   用的地方,再找到定义它的地方,跳转过去.
# 已知问题(2): 这个脚本不生成lookupfile插件的查找文件,预期通过cs find f命令来查
#   找文件并跳转.但是这个命令只支持c、c++、java语言后缀的文件,会找不到xml、rc文
#   件. 如果要查找的文件类型不支持,可以先用grep命令查找gtags.files文件,找到文件
#   的完整路径名,复制路径名,再用vim的e命令打开这个文件.建议用"!grep"命令来查找,
#   直接在vim中执行grep命令,它会跳转到所查找的文件里面,不预期有这样的跳转.

# gtags.files 文件指定 gtags 要解析的文件列表
GTAGS_FILES_NAME="gtags.files"
# 下面配置 gtags 命令生成的所有数据文件,以便后续统一删除
GTAGS_ALL_FILES="GPATH GRTAGS GTAGS ${GTAGS_FILES_NAME}"
# 定义Android源码根目录下frameworks目录的名称,用于判断是否
# 位于Android源码根目录下,以便针对Android源码文件进行过滤.
ANDROID_FRAMEWORKS="frameworks"

show_help()
{
printf "USAGE
        $(basename $0) option
OPTIONS
        option: 要执行的操作,支持的选项如下:
        -a: 生成所有数据文件.目前只使用gtags工具.
        -g: 生成 gtags 相关文件.
        -u: 增量更新已有的数据文件,gtags支持该功能.
        -c: 删除所有生成的数据文件.
        -h: 打印脚本的帮忙信息.
"
}

# 生成 gtags 相关文件.
setup_gtagsfiles()
{
    echo -e "\033[32mNOW ${FUNCNAME} !!!\033[0m"

    # 注意,下面的find命令中, "\(" 和  "-path" 之间一定要有空格,否则报错
    if [ -d "$ANDROID_FRAMEWORKS" ]; then
        # 如果存在 frameworks 目录,目前认为在Android源码根目录下,
        # 只查找特定子目录下的文件,其他目录认为是暂时不需要关注的代码.
        find ./bionic ./build ./device ./external \
            ./frameworks ./hardware ./kernel \
            ./packages ./system ./vendor \
            \( -path "*test*" -o -path "*tools" -o -path "*docs" \
            -o -path "*git*" -o -path "*svn" \) -prune \
            -o -regex '.+\.\(c\|h\|cpp\|cc\|hpp\|java\|rc\|xml\)$' \
            -type f -print > "${GTAGS_FILES_NAME}"
    else
        # 不在Android源码根目录下,在当前目录下查找.
        # 目前只查找 c、c++、java 的代码文件.
        find . \( -path "*test*" -o -path "*git*" -o -path "*svn" \) -prune \
            -o -regex '.+\.\(c\|h\|cpp\|cc\|hpp\|java\)$' \
            -type f -print > "${GTAGS_FILES_NAME}"
    fi

    # 生成 gtags.files 文件后,执行 gtags 命令解析这个文件里面的源码文件.
    gtags --skip-unreadable --skip-symlink
}

# 生成所有数据文件
setup_all()
{
    setup_gtagsfiles
}

# 增量更新已有的数据文件,gtags支持该功能.
update_tags()
{
    # global -u选项说明是: Update tag files incrementally.
    # 加上 -v 选项以便查看具体更新了什么内容.
    # 注意: global -u 是增量更新已有的数据文件,它不能自动添加新文件并更新.
    # 如果新增一个文件,可以用 gtags --single-update file 命令来单独更新.
    global -uv
}

# 删除所有生成的文件
clear_files()
{
    # 下面的 ${GTAGS_ALL_FILES} 前后不要加双引号,否则会被当成一个单独的文件.
    # GTAGS_ALL_FILES 定义的是多个文件,预期这些文件都被删除.
    rm -vf ${GTAGS_ALL_FILES}
}

# 使用getopts命令解析命令行选项,该命令要求选项必须以'-'开头,否则报错
# 注意,当getopts报错时,while语句判断为假,将不会执行里面的case语句.
while getopts "aguch" arg; do
    case ${arg} in
        a) setup_all ;;
        g) setup_gtagsfiles ;;
        u) update_tags ;;
        c) clear_files ;;
        h | ?) show_help ;;
    esac
done

# 上面的 getopts 命令只能处理以 '-' 开头的选项,当所提供的参数不以 '-' 开
# 头时,不会被处理.例如,执行 vimide.sh foo bar 时,上面的 while 循环不会报
# 错.为了检查这种情况,在处理完以 '-' 开头的选项之外,下面判断剩下的参数个
# 数是否为0,如果不是0,表示提供了多余的参数,提示报错信息.没有参数时也报错.
if [ $# -eq 0 -o $(($OPTIND - 1)) -ne $# ]; then
    echo "出错: 提供了无效参数,请使用 -h 选项查看脚本的使用说明."
    exit 1
fi

exit
