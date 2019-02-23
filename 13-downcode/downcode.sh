#!/bin/bash
# 在bash下,使用help set命令,可以看到set命令的帮助信息,里面对-e选项描述为:
# -e  Exit immediately if a command exits with a non-zero status.
set -e

# .codeurl.txt中存放各个代码的repo路径,里面每一行的格式需要满足如下形式:
# 代码标识^android代码的repo路径^lichee代码的repo路径
# 其中,代码标识是类似于 cs-a13-4.0, sw-a13-4.0 的字符串,正好是这个脚本前
# 三个参数的组合,代码标识一定要符合这个格式,否则脚本在根据传入的参数进行
# 匹配时,将匹配不到.
CODEURL="${HOME}/.myconf/codeurl.txt"

# 导入Android相关脚本的通用常量.
source android.sh

# 打印脚本使用提示信息. 注意下面的 OPTIONS 和 最后一个" 要顶头来写,
# 如果有空格或者tab的话,打印出来的也会有空格和tab. bash中,定义函数
# 时, function 关键字是可选的.
show_help()
{
printf "USAGE
        $(basename $0) location product android_version [branch_name]
OPTIONS
        location:          cs, sw.
        product:           a13, a31, a31s, a20, etc.
        android_version:   4.0, 4.1, 4.2, etc.
        branch_name:       optional, specifies the branch to checkout
"
}

# 打印 do_repo() 函数的使用提示信息.
show_do_repo_help()
{
printf "USAGE
        do_repo: dirname repo_url
OPTIONS
        dirname:            the directory to place downloaded code
        repo_url:           the url that to repo init
"
}

# 这个函数的参数说明如下:
# 第一个参数表示要新建的目录名,repo下来的代码将会存放在这个目录里面,目录名
# 要求和远程服务器的目录名相同,例如在checkout远程分支时,一般会写为:
# git checkout -b develop exdroid/develop (或者 lichee/develop),那么目录
# 名就应该是 exdroid 或者 lichee.
# 第二个参数是repo init指向的 URL,这个 URL 就是要下载的代码路径.
do_repo()
{
    if [ $# -ne 2 ]; then
        show_do_repo_help
        exit 1
    fi
    local do_dir do_repourl

    do_dir="${1}"
    do_repourl="${2}"

    mkdir -v ${do_dir}
    \cd ${do_dir}
    repo init -u ${do_repourl}
    repo sync
    \cd -
}

if [ ! -f "${CODEURL}" ]; then
    echo "$(basename $0): the ${CODEURL} doesn't exist."
    exit 1
fi

# 注意,bash中, $# 的值是不计算脚本本身的,如./a.sh a b,则 $# 是2,而不是3
if [ $# -lt 3 ]; then
    show_help
    exit 1
fi

# 脚本中, $1, $2, $3 之类的位置变量出现比较多,为了阅读方便,将脚本参数的值
# 赋给下面的变量,通过变量名对这些参数的值提供一个说明,让其含义明确一点.
location="${1}"
product="${2}"
android_version="${3}"

# 为了 cd 的时候方便 tab 补全,家目录下的代码目录都以数字开头,下面先执行cd
# 命令回到家目录,然后读取家目录下最大的开头数字,然后将这个数字加1,作为新建
# 目录的开头数字.
cd
sortdir=$(ls -d *-*/ | awk -F '-' '{print $1}')
maxdir="0"
for val in ${sortdir[@]}; do
    if [[ "${val}" -gt "${maxdir}" ]]; then
        maxdir=${val}
    fi
done
maxdir=$((maxdir+1))

# 下面通过 grep 匹配到目标行,再使用awk得到以 '^' 分割的各个字符串. 下面的
# projectdir 表示最外面的新建目录,这个目录里面将会再新建两个目录: exdroid
# 和 lichee. 这几个参数都可能为空. 下面不用判断 $target 是否为空, 当所给
# 参数在 ${CODEURL} 文件中找不到时, grep 返回 1, 由于脚本开头设置了 set -e
# 意味着: Exit immediately if a command exits with a non-zero status.
# 所以当找不到所给参数的匹配行时,脚本自己就终止了,不需要再判断是否为空.
target=$(grep "${location}-${product}-${android_version}" ${CODEURL})
projectdir=${maxdir}-$(echo ${target}   | awk -F '^' '{print $1}')
android_xml=$(echo ${target}            | awk -F '^' '{print $2}')
lichee_xml=$(echo ${target}             | awk -F '^' '{print $3}')

echo ${android_xml}
echo ${lichee_xml}

# 开始新建最外面的目录并cd进去,开始下载代码,下载代码时,让它们在后台
# 运行,这样就可以同时下载 android 代码和 lichee 代码.
mkdir -v ${projectdir}
cd ${projectdir}
do_repo "${LICHEE}" "${lichee_xml}" &
do_repo "${EXDROID}" "${android_xml}" &

# 使用 help wait 可以查看bash的内置命令wait的说明.其作用是:
# wait [id]: Wait for job completion and return exit status. If ID is not
# given, waits for all currently active child processes, and the return
# status is zero. 前面两个在后台运行的do_repo()函数就属于当前激活的子进程,
# 所以 wait 会等待这两个 do_repo() 函数执行结束,也就是一直等到代码下载完.
wait

# 使用 shift 去掉前面三个参数,只保留后面的branch参数.这里不需要判断是否
# 提供了分支名.如果没有提供分支名, repocheck.sh 脚本会弹出一个分支名列表,
# 以供选择要切换的代码分支.
shift 3
repocheck.sh e "$@"
repocheck.sh l "$@"

# 分别创建 android 和 lichee 打包方案的快捷方式,以便快速cd到这两个目录
ellink.sh
# 在 lichee 根目录下,创建用于编译lichee的脚本,生成lichee目录的ctags文件
cd ${LICHEE} && bulichee.sh ${product} foobar && vimconf.sh -a
# 在 exdroid 根目录下,生成 ctags 文件
cd ../${EXDROID} && vimconf.sh -a

exit
