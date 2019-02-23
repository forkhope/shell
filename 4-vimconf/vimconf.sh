#!/bin/bash
# 该脚本用于生成vim的tags文件,cscope相关文件,lookupfile的查找文件,通过
# 不同的选项来指定要生成的文件.各个选项如vimconf_show_help()函数所述.

CSCOPEFILES="cscope.files"
LOOKUPFILES="filenametags"

vimconf_show_help()
{
printf "USAGE
        $(basename $0) option
OPTIONS
        option: 要执行的操作,支持的选项如下:
        (1) -t: 生成 tags 文件.
        (2) -c: 生成 cscope 相关文件
        (3) -l: 生成 lookupfile 插件的查找文件
        (4) -a: 生成所有文件,tags文件,cscope相关文件,lookupfile查找文件等
        (5) -r: 删除所有生成的文件
"
}

# cscope 默认只解析C文件(.c和.h), lex文件(.l)和yacc文件(.y),如果希望cscope
# 解析c++, java文件, 或者其他类型的文件,需要把这些文件的名字和路径保存在
# 一个名为 cscope.files 的文件中,当cscope发现在当前目录下存在cscope.files
# 时,就会为cscope.files中列出的所有文件生成索引数据库,新生成的数据库将覆盖
# 原有的数据库,而不是将新生成的数据库追加到原有的数据库中.
setup_cscope()
{
    # 由于cscope相关文件和lookupfile的查找文件都需要用find命令来查找特定
    # 后缀的文件名,为了避免重复查找,将会用lookupfile的查找文件来生成
    # cscope.files文件,所以当lookupfile查找文件不存在时,先生成它.
    if [ ! -e "${LOOKUPFILES}" ]; then
        setup_lookup
    fi
    
    echo -e "\033[31mNOW ${FUNCNAME} !!!\033[0m"

    # 首先要删掉lookupfile查找文件的第一行,cscope.files不需要这一行.
    # 使用sed命令删掉带有空格的行,因为cscope命令遇到有空格的行会报错
    cat "${LOOKUPFILES}" | sed '1d' | sed '/ /d' \
        | awk -F '\t' '{print $2}' > "${CSCOPEFILES}"

    # 下面描述所使用的cscope选项的含义:
    # -R: 使用该选项来递归遍历工程文件夹.
    # -b: 只生成索引文件,不进入cscope界面.
    # -k: 生成索引文件时,不搜索 /usr/include目录.
    # -q: 生成cscope.in.out和cscope.po.out文件，加快cscope的索引速度
    # -i: 如果保存文件列表的文件名不是cscope.files时,需要用该选项告诉
    #     cscope到哪里去找源文件列表.所以,加上-i cscope.files是多余的.
    cscope -Rbkq
}

# lookupfile在查找文件时,需要使用tag文件.它可以使用ctags命令生成的tags
# 文件,不过效率很低,下面专门为它生成一个包含项目中特定类型文件名的tag文件
setup_lookup()
{
    echo -e "\033[31mNOW ${FUNCNAME} !!!\033[0m"

    echo -e "\!_TAG_FILE_SORTED\t2\t/2=foldcase/" > "${LOOKUPFILES}"
    # 注意,下面的find命令中, "\(" 和  "-path" 之间一定要有空格,否则报错
    find . \( -path "*test*" -o -path "*git*" -o -path "./out" \
        -o -path "./cts" -o -path "./gdk" -o -path "./ndk" \
        -o -path "./pdk" -o -path "./sdk" -o -path "./abi" \
        -o -path "./prebuilts" -o -path "./.repo" \
        -o -path "*docs" -o -path "./development" \) -prune \
        -o -regex '.*\.\(c\|xml\|cpp\|h\|java\|rc\|mk\|fex\)' -type f \
        -printf "%f\t%p\t1\n" >> "${LOOKUPFILES}"
}

# 在当前目录下创建ctags文件. 下面描述ctags的一些选项:
# --languages="c,c++,java": 可以用该选项来只生成特定语言的标签.所支持的
# 语言列表可以用 ctags --list-languages 来查看.
# --exclude=dir: 在生成标签时,忽略dir指定的目录,目录名称可以使用通配符.
# 但是不支持一个选项添加多个忽略目录,如果要忽略多个目录,只能一个个写,像
# --exclude=a --exclude=b. 经过验证,目录名称前面不要加"./",否则不能忽略.
setup_tags()
{
    echo -e "\033[31mNOW ${FUNCNAME} !!!\033[0m"

    # vim的echofunc插件能够在状态栏下提示函数原型,但是它需要tags文件支持,
    # 并且在创建tags文件时要加选项 "--fields=+lS".注意,是字符l,不是数字1.
    # 下面用--exclude指定要忽略的目录,所要忽略的目录和lookupfile差不多.
    # Android4.0下,编译工具位于目录prebuilt目录下,而Android4.2下,编译工具
    # 位于目录prebuilts目录下,所以下面排除的是prebuilt*这个目录.
    ctags --languages="c,java,c++" --exclude=*test* --exclude=out \
        --exclude=cts --exclude=*docs* --exclude=*git* --exclude=gdk \
        --exclude=ndk --exclude=pdk --exclude=sdk --exclude=abi \
        --exclude=prebuilt* --exclude=tools --exclude=.repo \
        --exclude=development -R --fields=+lS ./
}

# 生成所有文件,tags文件,cscope相关,lookupfile的查找文件等
setup_all()
{
    # 注意,如上所述,为了避免多次执行find命令,这里使用lookupfile的查找文件
    # 来生成cscope.files文件,所以要先生成lookupfile的查找文件,再去生成
    # cscope.files文件.如果在生成cscope.files文件时,不存在lookupfile的查
    # 找文件, setup_cscope() 函数会先生成该查找文件.
    setup_lookup
    setup_cscope
    setup_tags
}

# 删除所有生成的文件
clear_files()
{
    rm -vf cscope* ncscope.* tags "${LOOKUPFILES}"
}

if [ $# -eq 0 ]; then
    vimconf_show_help
    exit 1
fi

# 使用getopts命令解析命令行选项,该命令要求选项必须以'-'开头,否则报错
# 注意,当getopts报错时,while语句判断为假,将不会执行里面的case语句.
while getopts "acltr" arg; do
    case ${arg} in
        a) setup_all ;;
        c) setup_cscope ;;
        l) setup_lookup ;;
        t) setup_tags ;;
        r) clear_files ;;
        ?) vimconf_show_help ;;
    esac
done

# 上面的 getopts 命令只能处理以 '-' 开头的选项,当所提供的参数不以 '-' 开
# 头时,不会被处理.例如,执行 vimconf.sh foo bar 时,上面的 while 循环不会报
# 错.为了检查这种情况,在处理完以 '-' 开头的选项之外,下面判断剩下的参数个
# 数是否为0,如果不是0,表示提供了多余的参数,将会打印帮助信息.
if [ $(($OPTIND - 1)) -ne $# ]; then
    echo "不支持的参数,请查看脚本的使用说明"
    vimconf_show_help
    exit 1
fi

exit
