#!/bin/bash

# 导入Android相关脚本的通用常量.
source android.sh

COMMAND_CONFIG="${HOME}/.myconf/compilecmd.txt"
COMPILE_LICHEE_FILE="compile_lichee.sh"

bulichee_show_help()
{
printf "USAGE
        $(basename $0) [product]
OPTIONS
        该脚本用于编译lichee目录.当不带参数时,默认执行lichee目录下的
        ${COMPILE_LICHEE_FILE}脚本来进行编译.当这个脚本不存在时,需要提供
        一个 product 参数来指定需要编译的全志平台,从而生成对应该平台的
        lichee编译命令.目前支持的 product 参数如下:
            $(echo $(awk -F ':' '{print $1}' ${COMMAND_CONFIG}))
        如果传入的参数个数大于0,表示要生成lichee的编译脚本.如果参数个数等
        于1,将会执行所生成的脚本来编译lichee,如果参数个数大于1,则只生成脚
        本,不编译.
"
}

# 该函数接收一个参数,并使用该参数来找到对应的全志平台编译命令,将该编译命令
# 写入到 lichee 目录下的编译脚本中,后续会执行生成的脚本文件来编译lichee.
create_compile_file()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME product_name"
        return 1
    fi

    if [ ! -f "${COMMAND_CONFIG}" ]; then
        echo "$(basename $0): the ${COMMAND_CONFIG} doesn't exist."
        exit 1
    fi

    product="${1}"
    match=$(grep "${product}" ${COMMAND_CONFIG})
    target=$(echo ${match} | awk -F ':' '{print $1}')

    if [ "${target}" != "${product}" ]; then
        echo "ERROR: can't find ${product} in the config file"
        bulichee_show_help
        exit 1
    fi

    compile_command=$(echo ${match} | awk -F ':' '{print $2}')
    # 使用Here-document的语法来生成编译lichee的脚本文件
    (cat << EOF) > ./${COMPILE_LICHEE_FILE}
#!/bin/bash
echo -e "\033[33mCOMPILE THE LICHEE WITH: ${compile_command}\033[0m"
${compile_command}
EOF
    # 为生成的脚本文件添加可执行权限
    chmod +x ${COMPILE_LICHEE_FILE}
}

# 判断当前是否位于 lichee 目录下
current_dir=$(basename $(pwd))
if [ "${current_dir}" != "${LICHEE}" ]; then
    echo -e '\033[31m请先cd到lichee目录下,再编译!!!\033[0m'
    exit 1
fi

# 如果传入的参数个数大于0,表示要生成lichee的编译脚本.如果参数个数等于1,将
# 会执行所生成的脚本来编译lichee,如果参数个数大于1,则只生成脚本,不编译.
if [ $# -ne 0 ]; then
    create_compile_file "$1"

    # 如果传入的参数大于 1 时,只生成编译脚本,不会进行后面的编译操作
    if [ $# -gt 1 ]; then
        exit 0
    fi
fi

# 如果没有一个可执行的lichee编译脚本,就报错,要求提供参数来生成该脚本
if [ ! -x ${COMPILE_LICHEE_FILE} ]; then
    echo "编译脚本${COMPILE_LICHEE_FILE}不存在或没有可执行权限."
    bulichee_show_help
    exit 1
fi

# 执行当前 lichee 目录下的编译脚本
./${COMPILE_LICHEE_FILE}
