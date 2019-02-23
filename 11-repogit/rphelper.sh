#!/bin/bash
# 该脚本用于方便执行repo命令,省去输入很多字母的麻烦,并过滤部分命令的
# 输出结果,便于查看哪些仓库发生了改动.

DEFAULT_AUTHOR="john@ococci.com"
REPO_GIT_COMMAND="repo forall -p -c git"

# 查看所有仓库状态.repo status命令的输出结果已经过滤过,不需要再过滤.
# 该函数的第一个参数用于指定并发查询的线程数,如果没有指定,默认是4.
function repo_status()
{
    local jobs=4
    if [ $# -eq 1 ]; then
        jobs="$1"
    fi

    # 使用repo status的"-j"选项开启多线程查询,加快该命令的执行速度
    reset; repo status -j ${jobs}
    # repo status -j ${jobs} | cat
}

# 更新所有仓库代码.为了方便查看具体哪些仓库发生了改动,下面使用grep命令
# 过滤了repo forall -p -c git pull命令的输出结果.
function repo_pull()
{
    # 根据repo forall -p -c git pull命令的输出结果,下面用grep过滤出包含
    # "project"或者"|"(实际上用了"\|"来转义)的行,一个示例输出如下:
    # project device/softwinner/polaris-ococci/
    #  polaris_ococci.mk |    5 +++--
    # 可以看到,带有"project"的行指明了仓库的名字.而带有"|"的行指定了哪些
    # 文件发生了改变.这样就方便看出发生了改变的文件属于哪个仓库.
    # 奇怪的是,即使使用repo forall -p -c git pull | grep -E "project|\|"
    # 语句来对输出结果进行过滤,但还是会输出一些不匹配的行,如下:
    # From ssh://192.168.1.95/home/sw/sw_git/A23/platform/system/core
    #    b986d9d..ce3ccbf  a23-x7s-2.0 -> exdroid/a23-x7s-2.0
    #  * [new branch]      x7s-2.0-dnixs -> exdroid/x7s-2.0-dnixs
    # 这应该是跟重定向有关,例如使用"repo forall -p -c git pull > a.txt"来
    # 将输出结果重定向到"a.txt"文件里面,还是会看到类似的输出.但是在a.txt
    # 中看不到这部分输出,所以推断这部分输出被写入到了标准错误输出,而用'|'
    # 或者'>'重定向时,只重定向了标准输出,标准错误输出还是会打印到终端上.
    #
    # 对于管道来说,如果想同时重定向标准错误输出,可以使用'|&'来替代'|'.根据
    # 'man bash'的'Pipelines'小节的说明, '|&' 是 '2>&1 |' 的缩写,它先将标准
    # 错误输出重定向到标准输出,再将这两个输出一起写入到管道.
    reset; ${REPO_GIT_COMMAND} pull |& grep -E "project|\|"
}

# 对所有仓库执行git push命令,推送更新到远程仓库上.
# 该函数必须传入两个参数.第一个参数指定远程仓库名,第二个参数指定分支名.该
# 分支名同时指定了本地分支名和远程分支名,强制本地分支和远程分支保持同名.
function repo_push()
{
    if [ $# -ne 2 ]; then
        echo "Usage: $FUNCNAME repository branch"
        return 1
    fi
    local repository=$1
    local branch=$2

    reset; ${REPO_GIT_COMMAND} push ${repository} ${branch}:${branch}
}

# 下面的函数按照如下的方式来组装"git log"的选项.目前,不做参数检查.
# git log --name-status --author="author_name" --grep="pattern" -n
function repo_log()
{
    # $1 的格式是 "--author=author_name".注意,"--author"就是参数的一部分,且
    # 必须要有,"author_name"用于指定名作者名.
    # $2 的格式是 "--grep=pattern".其中,"pattern"用于指定查找模式.
    # $3 的格式是 "-n".其中,"n"指定了显示前面的多少条log信息.
    # 实际上,参数顺序不限.例如 $1 传入 "--grep=pattern" 也是可以的.
    reset; ${REPO_GIT_COMMAND} log --name-status $1 $2 $3
}

# 在所有仓库查看指定作者的log信息.
# 函数的第一个参数用于指定要查看的作者名,如果不指定,默认是"john@ococci.com"
function repo_log_author()
{
    local author=${DEFAULT_AUTHOR}
    if [ $# -eq 1 ]; then
        author="$1"
    fi

    repo_log --author="${author}"
}

# 在所有仓库查找所指定的模式的log信息.
# 该函数必须传入一个参数,用于指定要查找的模式(可以用正则表达式).
function repo_log_grep()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME grep_pattern"
        return 1
    fi
    local pattern="$1"

    repo_log --grep="${pattern}"
}

# 实际使用中,一般都是查看自己或其他同事的log,很少查找Android原生log.所以在
# 查看log时,会先根据作者过滤出一部分log,再进行grep,这样就看不到其他人的log
function repo_log_author_grep()
{
    local pattern author
    if [ $# -eq 1 ]; then
        author="$DEFAULT_AUTHOR"
    elif [ $# -eq 2 ]; then
        author="$2"
    else
        echo "Usage: $FUNCNAME grep_pattern <author>"
        echo "author可选,如果不指定,默认是'$DEFAULT_AUTHOR'"
        return 1
    fi
    pattern="$1"

    repo_log --author="${author}" --grep="${pattern}"
}

function repo_log_author_since()
{
    local date_t="$1"
    local author="$2"

    reset; ${REPO_GIT_COMMAND} log --name-status --since="${date_t}" \
        --author="${author}"
}

function repo_log_since()
{
    repo_log_since $1
}

function show_help()
{
printf "USAGE
    rphelper.sh <option> [argument1] [argument2] ...
OPTIONIS
    option: 所要进行的操作,支持的选项如下:
    (1) s: 执行 repo status 命令查看所有仓库状态
    (2) a: 查找指定作者的上库信息. 如果提供了第二个参数,则该参数指定要查找
           的作者名.如果不提供,默认作者名是'john@ococci.com'.
    (3) g: 使用 git grep 命令查找指定的上库注释.此时,需要一个argument1参数.
    (4) ag: 使用 git grep 命令查找某个作者的上库注释.此时,需要再提供两个
           参数,argument1指定作者名,argument2指定要查找的上库注释.
    (5) f: 查看所有仓库的第一条上库log信息.
    (6) l: 对所有仓库执行 git pull 操作.
    (7) p: 对所有仓库执行 git push 操作,主要用于上传新分支.
    (8) t: 查看从指定时间点往后的上库信息,不指定作者.
    (9) at: 查看 'john@ococci.com' 这个作者在指定时间名之后的上库信息,
"
}

# 目前不做参数检查.
case $1 in
    s)
        repo_status ;;
    a)
        # 如果提供了第二个参数,则该参数指定要查找的作者名.
        # 如果没有提供,则使用默认作者名.
        repo_log_author $2 ;;
    g)
        # 此时, $2表示要查找的模式
        repo_log_grep $2 ;;
    ag)
        # 此时, $2表示要查找的作者名, $3表示要查找的模式
        repo_log_author_grep $2 $3 ;;
    f)
        # 'f' 是 "first" 的缩写,表示要查看第一条log信息.
        repo_log -1 ;;
    l)
        repo_pull ;;
    p)
        # 此时, $2表示远程仓库名, $3表示本地分支和远程分支的名字.
        repo_push $2 $3 ;;
    t)
        # 此时, $2 表示从哪个时间点开始查找
        repo_log_since ;;
    at)
        # 此时, $2 还是表示从哪个时间点开始查找,但是只查找默认作者的log
        repo_log_author_since ;;
    *)
        echo "Unknown argument"
        show_help
        ;;
esac

exit
