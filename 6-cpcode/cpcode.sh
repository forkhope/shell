#!/bin/bash
# 在整理代码修改前后时,需要拷贝代码到after和before目录下,该脚本就用于
# 自动拷贝修改前后的代码到各自的目录下.它会在当前工作目录下新建一个
# "0-代码修改"的目录,然后根据操作选项(-a或-b),又在"0-代码修改"目录里面
# 新建一个after或者before目录,然后读取所给的文件来获得要拷贝的文件信息,
# 把里面指定的文件按照对应的目录结构拷贝到after或者before目录下.
set -e

# 要拷贝的文件信息的具体的格式为:
# project git_root_dir1/
# foo     file_path1
# project git_root_dir2/
# foo     file_path1
# 里面的内容分为多段,每段以project作为标识,project后面跟着git仓
# 库的根目录,要求以'/'结尾.在遇到下一个project开头的行之前,当前
# project往下的行都属于该段,这些行的第一列是占位符,内容不限,但一
# 定要有;第二列是git仓库下的文件路径.一个例子如show_help()函数所示.
# 这些信息可以通过repo status或者git log --name-status命令得到.
show_help()
{
printf "USAGE
        $(basename $0) e|l a|b [filename]
OPTIONS
        该脚本接受 3 个参数,且至少提供两个参数,描述如下:
        e|l: 指定远程服务器代码的根目录,字母'e'表示exdroid,字母'l'表示
             lichee.这两个字母只能提供一个.
        a|b: 指定本地代码的目录,字母'a'表示代码被拷贝到本地的after目录,
             字母'b'表示代码被拷贝本地的before目录.这两个字母只能提供一个.
        filename: 文件名,该文件里面保存了要拷贝的文件信息,一个例子为:
             project frameworks/opt/telephony/     branch develop
             -m  src/java/com/android/internal/telephony/PhoneProxy.java
             project hardware/ril/                 branch develop
             -m   include/telephony/ril.h
             !!注意!!: 该文件要放在远程服务器代码的根目录下.如果没有提供
             该参数,默认使用的文件名是: final-filter-gitlog.txt
"
}

if [ $# -lt 3 ]; then
    echo "该脚本的参数个数至少要有两个,请查看脚本的帮助信息"
    show_help
    exit 1
fi

EXDROID="exdroid"
LICHEE="lichee"
# 下面的变量指定远程服务器代码的根目录,其值是exdroid,或者lichee.
if [ "$1" == "e" ]; then
    remote_root_dir="${EXDROID}"
elif [ "$1" == "l" ]; then
    remote_root_dir="${LICHEE}"
else
    echo "第一个参数有误,请查看脚本帮助信息"
    show_help
    exit 1
fi

AFTER="after"
BEFORE="before"
# 下面的变量指定本地代码的类型,是修改前的,还是修改后的.
if [ "$2" == "a" ]; then
    LOCAL_CODE_TYPE="${AFTER}"
elif [ "$2" == "b" ]; then
    LOCAL_CODE_TYPE="${BEFORE}"
else
    echo "第二个参数有误,请查看脚本帮助信息"
    show_help
    exit 1
fi

# 下面获取当前工作目录的路径,并在路径末尾添加要新建的本地目录.
# 本地要新建的目录是:0-代码修改/${LOCAL_CODE_TYPE}/{remote_root_dir}.
# 这里还不需要执行新建操作,后面拷贝文件时,会新建本地文件所在的目录
LOCAL_DIR="$(pwd)/0-代码修改/${LOCAL_CODE_TYPE}/${remote_root_dir}"

# 执行跟远程服务器相关的操作,如挂载远程服务器,cd到远程文件系统,检测远程
# 目录是否符合要求等.执行完该脚本后,当前工作目录会被切换到远程目录上.
# 之后,再执行 cd - 命令返回原来的目录,此时,要求第三个参数指定的文件要放在
# 执行该命令时的路径下.这样,同一个文件就不用放到远程服务器的两个目录下.
source procommon.sh
setup_remote_path "${remote_root_dir}"
REMOTE_DIR="$(pwd)/${remote_root_dir}"

# 如果没有提供第三个参数,则使用默认的git log信息文件名.如果提供了
# 第三个参数,则使用该参数所提供的文件名.
if [ $# -eq 3 ]; then
    filename="$3"
else
    filename="final-filter-gitlog.txt"
fi
fileinfo_path="${REMOTE_DIR}/${filename}"

# 检查远程服务器代码根目录下是否存在一个指定的git log信息文件.
# 该变量保存脚本所要解析的文件名.这个文件存有所要拷贝的文件信息.
# 注意: 这个文件的最后一行一定要以空行结尾,否则最后一行处理不到!
if [ ! -f "${fileinfo_path}" ]; then
    echo "出错: 所指定的文件 ${fileinfo_path} 在远程服务器下不存在!"
    exit 1 
fi

# 返回原先目录,所拷贝的目录会保存在原先目录下.
cd -

parse_fileinfo()
{
    local local_file_dir local_file_path remote_file_path fileline

    while read fileline; do
        # 合并出远程服务器上文件的绝对路径,以及本地文件所在的绝对路径
        local_file_path="${LOCAL_DIR}/${fileline}"
        remote_file_path="${REMOTE_DIR}/${fileline}"

        # 拷贝时,如果文件所在目录不存在会报错,所以先判断文件所在目录
        # 是否存在,如果不存在,则递归新建文件所在的目录
        local_file_dir="$(dirname ${local_file_path})"
        if [ ! -d "${local_file_dir}" ]; then
            mkdir -p "${local_file_dir}"
        fi

        # 调试的时候,可以打开下面两个语句的注释.
        # echo "--REMOTE_FILE_PATH--: ${remote_file_path}"
        # echo "++LOCAL_FILE_PATH++: ${local_file_path}"
        cp -v "${remote_file_path}" "${local_file_path}"
    done
}

parse_fileinfo < "${fileinfo_path}"

exit
