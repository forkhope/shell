#!/bin/bash
set -e

# project git_root_dir1/ foo
# foo     file_path1
# project git_root_dir2/ foo
# foo     file_path1
# 里面的内容分为多段,每段以project作为标识,project后面跟着git仓
# 库的根目录,要求以'/'结尾.在遇到下一个project开头的行之前,当前
# project往下的行都属于该段,上面写有foo的部分是占位符,内容不限,但一
# 定要有;第二列是git仓库下的文件路径.一个例子如show_help()函数所示.
# 这些信息可以通过repo status或者git log --name-status命令得到.
show_help()
{
printf "USAGE
        $(basename $0) a|b [filename]
OPTIONS
        该脚本要在Android源码根目录下执行,可以接受2个参数,且至少提供一个参数:
        a|b: 指定本地代码的目录,字母'a'表示代码被拷贝到本地的after目录,
             字母'b'表示代码被拷贝本地的before目录.这两个字母只能提供一个.
        filename: 文件名,该文件里面保存了要拷贝的文件信息,一个例子为:
             project frameworks/opt/telephony/     branch develop
             -m  src/java/com/android/internal/telephony/PhoneProxy.java
             project hardware/ril/                 branch develop
             -m   include/telephony/ril.h
             !!注意!!: 该文件要放在Android源码的根目录下.如果没有提供
             该参数,默认使用的文件名是: gitlog-files.txt.
             这个文件必须是unix格式,不带\r字符,如果带了\r字符,可以用dos2unix
             命令来转换成unix格式文件,再执行这个脚本.
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
    show_help
    exit 1
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
# 注意: 这个文件的最后一行一定要以空行结尾,否则最后一行处理不到!
if [ ! -f "${filename}" ]; then
    echo "出错: 在当前目录下不存在要解析的 ${filename} 文件!"
    exit 1 
fi

# 过滤repo -p -c git log --name-status命令所生成的git log信息,会将"project"
# 后面跟着的仓库名添加到git log命令所打印的文件路径前面,组成完整的文件路径,
# 并进行排序,删除重复行.这样就得到基于Android源码根目录的完整文件路径.
# 例如下面的"project"后面的"linux-3.4"是仓库名,
# "M"后面的内容是该仓库下发生变动的文件路径,添加上仓库名后就是完整的路径名.
# project linux-3.4/ foo
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
    local gitlog_file
    local header project_dir sub_file_path full_file_path
    local temp_file="temp.txt"

    # 获取要解析的源文件名,并把要过滤的git log信息写入到该文件.
    gitlog_file="${1}"

    while read fileline; do
        header="$(echo ${fileline} | awk '{print $1}')"
        if [ "${header}" == "${PROJECT_IDENTIFY}" ]; then
            project_dir="$(echo ${fileline} | awk '{print $2}')"
        elif [ -n "${fileline}" ]; then
            # 当文件中有空行时,readline的内容会是null,后面组装
            # sub_file_path的值会有异常,所以上面用-n判断不为空才处理.
            sub_file_path="$(echo ${fileline} | awk '{print $2}')"
            # 实际测试发现,如果project git_root_dir/字符串后面foo
            # 占位符,那么获取到git_root_dit/后面会跟着回车符\r,下面的
            # project_dir变量的值也有换行符,此时z拼装到full_file_path
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
# 为了避免多次执行这个语句,先注释掉.对于dos格式的文件单独执行下面的命令
# dos2unix "${filename}"
parse_gitlog_info "${filename}"
copy_gitlog_files "${target_gitlog_file}"

# 将git log文件拷贝到"0-代码修改"目录下,以便标记这个目录下的文件来源.
cp -uv "${filename}" "${COPY_TARGET_ROOT}/${filename}"
mv -v "${target_gitlog_file}" "${COPY_TARGET_ROOT}/${target_gitlog_file}"

exit 
