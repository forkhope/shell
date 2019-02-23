#!/bin/bash
# 该脚本用于在exdroid或者lichee根目录下,全项目下载远程代码分支
set -e

# 导入Android相关脚本的通用常量.
source android.sh

show_help()
{
printf "USAGE
        $(basename $0) e|l [branch1 branch2 ... branchn]
OPTIONS
        e|l: 表示要下载exdroid下的分支,还是lichee下的分支.
            e: 表示要下载exdroid下的分支.
            l: 表示要下载lichee下的分支.
        branch1 branch2 ... branchn: 可选参数,指定要下载的分支名
            如果不提供任何分支名,脚本会弹出一个列表以供选择.
"
}

# 该全局变量用于保存选择后的代码分支,即要下载的代码分支
chosen_branch=""

# 该函数使用select语句列出远程服务器的代码分支列表,当选择正确的分支后,
# 返回成功,如果选择了错误的分支,或者没有选择分支,函数报错返回.
# 该函数在 cd 到 CHECK_DIR 之前,假设此时就位于exdroid或者lichee目录下.
choose_remote_branch()
{
    if [ "$#" != "1" ]; then
        echo "Usage: $FUNCNAME the_dir_to_check"
        return 1
    fi

    check_dir=$1
    cd ${check_dir}
    all_srv_branch=$(git branch -r)
    # 在函数中执行 cd 命令后,退出函数时,当前工作目录还是保持在 cd 后的
    # 目录,所以需要手动执行 cd - 命令会回到原来的工作目录
    cd -
    select srv_branch in ${all_srv_branch}; do
        if [ "${srv_branch}" ]; then
            chosen_branch=$(echo ${srv_branch} | awk -F '/' '{print $2}')
            return 0
        fi
    done
    return 1
}

checkout_remote_branch()
{
    if [ "$#" != "2" ]; then
        echo "Usage: $FUNCNAME local_branch remote_branch"
        return 1
    fi

    local_branch=$1
    remote_branch=$2
    repo forall -c git checkout -b ${local_branch} ${remote_branch}
}

# 由于在exdroid或者lichee根目录下,不方便获取远程服务器的代码分支,需要
# cd 到一个具体的git仓库下,使用git branch -r命令查看所有的远程代码分支.
# 下面的CHECK_DIR变量就保存要 cd 的具体git仓库路径.
if [ "$1" == "e" ]; then
    REMOTE_ROOT_DIR=${EXDROID}
    CHECK_DIR="frameworks/base"
elif [ "$1" == "l" ]; then
    REMOTE_ROOT_DIR=${LICHEE}
    CHECK_DIR="tools"
else
    echo "第一个参数有误,请查看脚本的帮助信息"
    show_help
    exit 1
fi

# 当前目录下要有.repo目录才能正确执行repo相关命令,所以先 cd 到 exdroid
# 或者 lichee 的代码根目录下.下面调用pwd_dir_check()函数来确定当前目录
# 下是否包含名为 "exdroid" 或者 "lichee" 的子目录.如果没有,脚本就退出.
source procommon.sh
pwd_dir_check ${REMOTE_ROOT_DIR}
if [ $? -ne 0 ]; then
    exit 1
fi

# 要先 cd 到exdroid或者lichee里面之后,再执行choose_remote_branch()函数,
# 因为该函数在 cd 到CHECK_DIR时,假设当前就位于exdroid或者lichee目录下.
cd ${REMOTE_ROOT_DIR}

# 使用 shift 1 命令跳过第一个参数,以便后面的 $@ 不再返回该参数.
# 执行shift 1后,如果参数个数为空,说明没有提供要下载的分支名,脚本将会
# 弹出一个列表,以供选择要下载的远程代码分支.
shift 1
if [ $# -eq 0 ]; then
    choose_remote_branch "${CHECK_DIR}"
    if [ $? -ne 0 ]; then
        echo "选择的远程代码分支有误,或者没有作出选择,终止执行."
        exit 1
    fi
    branch_lists="${chosen_branch}"
else
    branch_lists="$@"
fi

# 这里有个潜规则,现有一个develop分支,则假设服务器上对应的lichee远程分支
# 为lichee/develop,且对应的exdroid分支为exdroid/develop,即刚好跟本地代码
# 根目录下的exdroid,lichee两个子目录的目录名相同. 脚本将使用分支名和子目
# 录名来组成远程服务器上的分支名.当服务器分支命名规则改变后,要注意这一点.
for branch in ${branch_lists}; do
    checkout_remote_branch "${branch}" "${REMOTE_ROOT_DIR}/${branch}"
done

exit
