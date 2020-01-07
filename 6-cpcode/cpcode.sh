#!/bin/bash
# 在整理代码修改前后时,需要拷贝代码到after和before目录下,方便对比.
# 该脚本用于自动拷贝Android源码的代码文件.它会在Android源码根目录下
# 新建一个"0-代码修改"的目录,根据操作选项(-a或-b),在"0-代码修改"
# 目录里面新建一个after或者before子目录,然后读取要拷贝的文件信息,
# 把里面指定的文件按照对应的目录结构拷贝到after或者before目录下.
set -e

# 要拷贝的文件信息的具体的格式为:
# project git_root_dir1/
# foo     file_path1
# project git_root_dir2/
# foo     file_path1
# 里面的内容分为多段,每段以project作为标识,project后面跟着git仓库的
# 根目录,要求以'/'结尾.在遇到下一个project开头的行之前,当前project
# 往下的行都属于该段,上面写有foo的部分是占位符,内容不限,但一定要有.
# 第二列是git仓库下的文件路径.参考例子如show_help()函数所示.
show_help()
{
printf "USAGE
    cpcode.sh a|b [filename]
OPTIONS
    该脚本要在Android源码根目录下执行,可以接收2个参数,且至少提供一个参数:
    a|b: 指定本地代码的目录,字母'a'表示代码被拷贝到本地的after目录,
         字母'b'表示代码被拷贝本地的before目录.这两个字母只能提供一个.
    filename: 文件名,该文件里面保存了要拷贝的文件信息.参考例子如下:
         project frameworks/opt/telephony/
         -m  src/java/com/android/internal/telephony/PhoneProxy.java
         project hardware/ril/
         -m   include/telephony/ril.h
         这些文件信息可以通过repo status或者git log --name-status命令得到.
         !!注意!!: 该文件要放在Android源码的根目录下.如果没有提供
         文件名参数,默认使用的文件名是: gitlog-files.txt.
"
}

if [ $# -lt 1 ]; then
    echo "出错: 该脚本的参数个数至少要有一个,请查看脚本的帮助信息"
    show_help
    exit 1
fi

FRAMEWORKS="frameworks"
# 预期在Android源码根目录下执行这个脚本,后续基于project路径和
# git log的文件路径拼装出要拷贝的完整文件路径后才能基于完整路径
# 来拷贝目标文件.
if [ ! -d "${FRAMEWORKS}" ]; then
    echo "出错: 当前目录 $(pwd) 下没有包含 ${FRAMEWORKS} 目录"
    echo "      请在Android源码根目录下执行该脚本"
    exit 2
fi

AFTER="after"
BEFORE="before"
# 下面的变量指定本地代码的类型,是修改前的,还是修改后的.
if [ "$1" == "a" ]; then
    LOCAL_CODE_TYPE="${AFTER}"
elif [ "$1" == "b" ]; then
    LOCAL_CODE_TYPE="${BEFORE}"
else
    echo "出错: 第一个参数有误,请查看脚本帮助信息"
    show_help
    exit 1
fi

COPY_TARGET_ROOT="0-代码修改"
# 下面变量指定目标拷贝目录,从Android源码拷贝出来的代码就放在这个目录下
COPY_TARGET_DIR="${COPY_TARGET_ROOT}/${LOCAL_CODE_TYPE}"

# 如果没有提供第二个参数,则使用默认的git log信息文件名.如果提供了
# 第二个参数,则使用该参数所提供的文件名.
if [ $# -eq 2 ]; then
    filename="$2"
else
    filename="gitlog-files.txt"
fi

# 检查Android源码根目录下是否存在一个指定的git log信息文件.
# 该变量保存脚本所要解析的文件名.这个文件存有所要拷贝的文件信息.
if [ ! -f "${filename}" ]; then
    echo "出错: 在当前目录下不存在要解析的 ${filename} 文件!"
    exit 2
fi

# 过滤repo -p -c git log --name-status命令所生成的git log信息,会将"project"
# 后面跟着的仓库名添加到git log命令所打印的文件路径前面,组成完整的文件路径,
# 并进行排序,删除重复行.这样就得到基于Android源码根目录的完整文件路径.
# 例如下面的"project"后面的"linux-3.4"是仓库名,
# "M"后面的内容是该仓库下发生变动的文件路径,添加上仓库名后就是完整的路径名.
# project linux-3.4/
# M   drivers/input/sw-device.c
# 则过滤后的内容是: linux-3.4/drivers/input/sw-device.c
# 过滤后的文件内容会被保存到 target_gitlog_file 指定的文件下.
target_gitlog_file="target-gitlog-files.txt"

parse_gitlog_info()
{
    if [ $# -ne 1 ]; then
        echo "Usage: ${FUNCNAME} git_log_filename"
        return 1
    fi
    local PROJECT_IDENTIFY="project"
    local gitlog_file fileline
    local header project_dir sub_file_path full_file_path
    local temp_file="temp.txt"

    # 获取要解析的源文件名,并把要过滤的git log信息写入到该文件.
    gitlog_file="${1}"

    # 如果文件的最后一行没有以换行符'\n'结尾, read 命令在读取最后一行
    # 时会返回false,从而退出下面的 while 循环,导致最后一行没有被处理,
    # 会少复制一个文件.下面使用 tail 命令获取文件的最后一个字符,由于
    # $() 表达式会去掉输出结果末尾的换行符,如果文件的最后一个字符是换
    # 行符,经过 "$()" 扩展后会变成空,可以通过判断扩展后的结果是否为空
    # 来确认文件是否以换行符结尾.如果不以换行符结尾,则使用 echo 命令
    # 给文件末尾追加一个换行符. test -n 命令判断字符串不为空返回true.
    if test -n "$(tail "${gitlog_file}" -c 1)"; then
        echo >> "${gitlog_file}"
    fi

    while read fileline; do
        header="$(echo ${fileline} | awk '{print $1}')"
        if [ "${header}" == "${PROJECT_IDENTIFY}" ]; then
            project_dir="$(echo ${fileline} | awk '{print $2}')"
            local lastchar=${project_dir: -1:1}
            # project_dir 被作为目录路径使用,要求最后一个字符
            # 必须是'/',以便组装成目录路径.如果没有以'/'结尾,
            # 则在该变量值后面加上 '/' 字符.
            if [ "$lastchar" != "/" ]; then
                project_dir="${project_dir}/"
            fi
        elif [ -n "${fileline}" ]; then
            # 当文件中有空行时,readline的内容会是null,后面组装
            # sub_file_path的值会有异常,所以上面用-n判断不为空才处理.
            sub_file_path="$(echo ${fileline} | awk '{print $2}')"
            # 实际测试发现,如果project git_root_dir/字符串后面没有foo
            # 占位符,那么获取到git_root_dit/后面会跟着回车符\r,下面的
            # project_dir变量的值也有换行符,此时再拼装到full_file_path
            # 里面会有问题,这些内容不在同一行里面,无法正常解析.
            # NOTE: 后来发现是这个文件是在Windows下生成,文件末尾是\r\n
            # 字符,其实echo命令会过滤掉末尾的\n,但不会过滤\r,这个字符
            # 导致了敲回车的效果,出现异常.如果把文件格式转成unix格式,
            # 那么文件的project行不加foo占位符也是正常的.
            full_file_path="${project_dir}${sub_file_path}"
            echo "${full_file_path}" >> "${temp_file}"
        fi
    done < "${gitlog_file}"

    # 对生成的文件内容进行排序,并删除重复行.
    # 这里不能cat target_gitlog_file 再用 > 重定向到 target_gitlog_file,
    # 否则target_gitlog_file文件内容会是空.目前原因不明.
    cat "${temp_file}" | sort | uniq > "${target_gitlog_file}"
    rm "${temp_file}"
}

copy_gitlog_files()
{
    if [ $# -ne 1 ]; then
        echo "Usage: ${FUNCNAME} gitlog_files"
        return 1
    fi
    local target_file_dir target_file_path source_file_path fileline

    while read fileline; do
        # 合并出远程服务器上文件的绝对路径,以及本地文件所在的绝对路径
        target_file_path="${COPY_TARGET_DIR}/${fileline}"
        source_file_path="${fileline}"

        # 拷贝时,如果文件所在目录不存在会报错,所以先判断文件所在目录
        # 是否存在,如果不存在,则递归新建文件所在的目录
        target_file_dir="$(dirname ${target_file_path})"
        if [ ! -d "${target_file_dir}" ]; then
            mkdir -p "${target_file_dir}"
        fi

        # 调试的时候,可以打开下面两个语句的注释.
        # echo "--SOURCE_FILE_PATH--: ${source_file_path}"
        # echo "++TARGET_FILE_PATH++: ${target_file_path}"
        cp -uv "${source_file_path}" "${target_file_path}"
    done < "$1"
}

# 把windows的dos格式文件转换成unix格式.
# dos格式文件末尾是\r\n,而unix格式的文件末尾是\n,且把\r视作有效字符,
# 如果不做转换,那么传入一个dos格式的文件,最后得到的文件名路径会包含\r
# 字符,它会被当做文件名的一部分,cp命令拷贝时会提示找不到这样的文件.
# 当使用 file 命令查看 dos 格式文件时,打印信息会包含
# "CRLF line terminators" 字符串.下面检查所给文件是否
# 为 dos 格式. 如果是,则执行 dos2unix 命令转换为 unix 格式文件.
if [[ "$(file filename)" =~ "CRLF line terminators" ]]; then
    dos2unix "${filename}"
fi

parse_gitlog_info "${filename}"
copy_gitlog_files "${target_gitlog_file}"

# 将git log文件拷贝到"0-代码修改"目录下,以便标记这个目录下的文件来源.
cp -uv "${filename}" "${COPY_TARGET_ROOT}/${filename}"
mv -v "${target_gitlog_file}" "${COPY_TARGET_ROOT}/${target_gitlog_file}"

exit
