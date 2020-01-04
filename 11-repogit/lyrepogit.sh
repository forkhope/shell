#!/bin/bash
# 该脚本用于方便执行repo命令和git命令,省去输入很多字母的麻烦,
# 并过滤部分命令的输出结果,便于查看哪些仓库发生了改动.

# Shell脚本默认是在非交互模式下执行,此时不会继承父shell的alias别名,
# 那么grep命令不会带--color=auto选项,搜索结果没有颜色高亮.
# 为了显示颜色高亮,下面定义 GREP_COLOR 变量来加上 --color=auto 选项.
# 要说明的是,交互式shell就是在终端上执行,shell等待你的输入来作为命令,
# 并执行提交的命令;非交换式shell一般是以shell脚本方式执行,读取脚本
# 文件中的命令并执行它们,不需要用户输入要执行的命令.当然,脚本里面有些
# 命令可能会让用户输入内容(例如read命令)或者做个选择(例如select命令),
# 这是命令自身的功能,但是这个命令本身不是用户输入的.
GREP_COLOR="grep --color=auto"
# 某些厂商可能会修改repo源码,并命名为其他名字,为了提升脚本的可移植性,
# 下面定义 REPO 变量来表示repo命令.如有需要,只需要改动这里面的值即可.
REPO="repo"

show_help()
{
printf "USAGE
    lyrepogit.sh option [option2...]
OPTIONS
    option:  所要进行的操作,至少要提供一个选项.
    option2: 可选选项,可以提供一个或者多个,该脚本
             支持传入多个参数,一次性进行多个操作.
    目前支持的选项如下：
    -b branch_name: 设置要处理的git branch名称. 默认名称是
       xxxxxxxxx (由脚本的branch_name变量指定)
       注意: 这个设置只是单次有效,指定-b选项后,需要再传入要进行
       的操作简写.如果只指定-b选项,再单独传入操作简写,不会生效.
    s: 执行 repo status 命令查看所有仓库状态,并过滤掉没有改动的
       仓库名,只打印有变动的仓库名和变动的文件名.
    sc: 先执行 repo status 命令查看所有仓库状态,过滤掉没有改动的
        仓库名,最后再过滤掉部分不需要关注的仓库信息.在全编译之后,
        有些仓库底下的文件会被改动,或者新增一些文件.我们可能只是
        想查看自己改动的仓库变动,不关注那些编译后自动改动的仓库,
        所以要过滤掉它们.这些仓库的信息从~/.liconfig/lyrepo.txt
        文件读取到,修改这个文件就能动态添加或删除不关注的仓库信息.
        仓库信息的格式是repo status命令所打印的仓库路径,例如打印:
        project android/frameworks/base/      branch branch_name
        那么仓库信息就是android/frameworks/base/.一行一个仓库信息.
    rp: 通过 repo forall 命令为符合条件的git仓库执行pull操作.
        符合条件是指git仓库的当前分支在远端服务器上存在同名的分支.
    pb: 执行'git pull --stat --no-tags 远端仓库名 远端分支名'命令
        来更新且只更新本地当前分支.要求本地分支名跟远端分支名一致.
"
}

if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# 默认设置git branch名称为下面的值.
# 可以通过 -b branch_name 选项来改变要操作的branch名称.
# TODO 请自行替换下面的 xxxxxxxxx 为个人常用的分支名.
branch_name="xxxxxxxxx"

set_branch_name()
{
    if [ $# -ne 1 ]; then
        echo "Usage $FUNCNAME branch_name"
        return 1
    fi
    branch_name="$1"
}

execute_command()
{
    local cmd="$@"
    # 由于这个脚本支持传入多个参数,每个参数对应一个操作,
    # 为了方便区分不同操作打印的信息,下面先打印要执行的命令,
    # 再执行该命令,就能知道后续打印的信息是这个命令所输出.
    echo -e "\033[32m---- ${cmd} ----\033[0m"
    bash -c "${cmd}"
}

# 执行 repo status 命令查看所有仓库状态,并过滤出发生变动的文件和project.
repo_status_filter()
{
    # 指定使用单线程来查询,避免多线程查询时,打印的信息重叠错乱,影响过滤.
    local jobs=1
    # 如果某个仓库的输出结果多于一页时, repo status 会使用 less 命令先显示
    # 这个输出结果,需要手动翻页,或者输入q来退出less命令.使用grep命令来过滤
    # 输出结果可以避免这种情况,但是会失去repo status本身的颜色高亮.
    # 下面的 ^ 表示匹配行首, \s 表示一个空格, \- 表示-字符,该字符需要用\来
    # 转义,否则它会被当做命令选项来处理,导致异常.它们结合起来就是匹配" --"、
    # " -m"、或" -d"开头的行.基于 repo help status 命令对repo status所打印
    # 信息的说明,可知 -- 对应new/unknown的文件, -m 对应modified文件,-d 对应
    # delted文件. 然后再用 grep 的 -B 1 选项指定显示所匹配行的上一行,会打印
    # project信息,grep命令本身会保证上一行是不匹配的行.例如对于下面三行来说:
    # project android/vendor/third/opensource/interfaces/ branch 
    # --     camera/device/1.0/Android.bp
    # --     display/allocator/1.0/Android.bp
    # 匹配到第一个 -- 的行时,打印它的上一行是project这一行.匹配到第二个 --
    # 的行时,它的上一行是第一个 -- 的行,但是grep不会重复打印第一个 -- 的行,
    # 不会出现某个匹配行被重复打印的情况. 但是grep的 -B 1 选项会在匹配之后
    # 自动打印一个内容为 "--" 的行,目前没有特别过滤掉这一行,保留grep的打印.
    # 注意: 这里要用双引号把repo命令和grep命令都引起来,这两个命令中间有|管道
    # 命令,如果不加双引号,这个管道会被当成execute_command函数和grep之间的管
    # 道,导致execute_command内部用echo命令打印的信息会被grep过滤掉而不显示.
    execute_command \
        "${REPO} status -j ${jobs} | ${GREP_COLOR} -B 1 -E '^\s\-\-|^\s\-m|^\s\-d'"
}

# 使用 repo forall 命令对符合条件的git仓库执行reset、pull的动作,
# 这里的"符合条件"指的是git仓库的当前分支在远端服务器上存在同名的分支.
# 当本地文件有改动时,需要先执行git reset/git checkout回退本地修改,才能执
# 行git pull操作.目前代码编译之后,部分文件会被自动修改,导致无法直接pull.
repo_forall_reset_pull()
{
    # repo forall 的 -p 选项说明是: Show project headers before output.
    # git rev-parse --abbrev-ref HEAD 打印且只打印当前分支名.
    # git rev-parse --abbrev-ref branch_name@{upstream} 查询branch_name
    #   分支在远端服务器上是否存在同名分支.如果不存在,该命令的返回值是false.
    #   下面通过这个命令判断该git仓库的当前分支在远端服务器上是否存在同名
    #   分支.如果不存在,就不会继续操作,可以避免覆盖本地调试分支的修改.
    #   注意: 这里的 "@{upstream}" 是整个命令的一部分,不是脚本自身的变量
    # git reset --hard: Resets the index and working tree. 这会覆盖本地修改.
    # git pull --stat --no-tags: 参考下面git_pull_current_branch_only()的说明
    # 执行git pull --stat命令,会打印仓库的状态,下面用grep命令过滤出发生变动
    # 的分支和改动的文件.第一次grep到的project信息会包含没有变动的project名,
    # 第二次grep过滤发生变动的文件,用-B 1打印上一行的信息,就是该文件所在的
    # project路径.基于实际打印的信息可知,带有"|"的行指定了哪些文件发生了改变.
    # 由于这些git命令会在所有仓库都执行,这些结果无法体现在 execute_command()
    # 里面,这里不通过 execute_command 来执行下面命令.
    # !!注意!! 下面 -c 后面的命令要用单引号括起来,不能用双引号括起来.用双引号
    # 括起来,解析脚本时,会先扩展$(git rev-parse --abbrev-ref HEAD)的结果,再把
    # 扩展结果传给repo forall命令.使用set -x选项查看,打印出类似下面的结果:
    #   + repo forall -p -c 'branch_name= && git rev-parse --abbrev-ref
    # 而预期是把$(git rev-parse --abbrev-ref HEAD)作为命令参数一部分传给repo
    # forall命令,使用双引号的情况而预期不符,会导致执行结果也不符合预期.
    # 使用单引号括起来,解析脚本是不会先扩展$(git rev-parse --abbrev-ref HEAD)
    # 的结果,使用set -x选项查看,打印出类似下面的结果:
    #   + repo forall -p -c 'branch_name=$(git rev-parse --abbrev-ref HEAD)
    # 可以看到,$(git rev-parse --abbrev-ref HEAD)被作为命令参数一部分传给了
    # repo forall命令,才能起到在每个git仓库都执行这些git命令的效果.
    ${REPO} forall -p -c 'branch_name=$(git rev-parse --abbrev-ref HEAD) &&\
        git rev-parse --abbrev-ref ${branch_name}@{upstream} &&\
        git reset --hard &&\
        git pull --stat --no-tags $(git remote) ${branch_name}' |\
        grep -E 'project|\|' | ${GREP_COLOR} -B 1 '|'
}

# 将 远端指定分支 拉取到 本地指定分支 上:
#   git pull 远端仓库名 <远端分支名>:<本地分支名>
# 将 远端指定分支 拉取到 本地当前分支 上:
#   git pull 远端仓库名 <远端分支名>
# 执行 git pull 会更新服务器所有branch、tag的信息,之后再执行
# git branch -r 命令会看到服务器所有branch列表,影响Tab键自动补全.
# 如果不想更新这些branch、tag信息到本地,可以指定要pull的远端分支名.
# 下面函数把本地当前分支名作为远端分支名来进行pull.这里要求本地
# 分支名必须和远端分支名一致,否则会报错.
git_pull_current_branch_only()
{
    # git remote打印远端仓库名
    local remote_name=$(git remote)
    # git rev-parse --abbrev-ref HEAD打印且只打印本地当前分支名
    local branch_name=$(git rev-parse --abbrev-ref HEAD)
    # 使用 --stat 选项指定打印改动的文件信息.
    # 使用 --no-tags 选项指定不获取tag信息
    execute_command "git pull --stat --no-tags ${remote_name} ${branch_name}"
}

#### NOTE: 下面的功能基于特殊环境、特殊目录做特殊处理,不具有移植性.
# 判断传入的project路径是否属于要忽略的仓库.如果属于,就需要忽略,
# 会返回0.如果不属于,不需要忽略,返回1.
# 注意: 传入的project路径只能包含路径内容,不能有其他字段.
check_ignore_project()
{
    if [ $# -ne 1 ]; then
        echo "Usage $FUNCNAME project_path"
        return 1
    fi
    # 改成在配置文件中配置要过滤的仓库信息,以便动态添加或删除,
    # 不需要修改脚本代码. 为了方便后续参考遍历数组的方法,先不
    # 删除下面代码,只是注释掉.
    # local ignore_projects=(\
    #     "project android/tools/" \
    #     "project android/vendor/third/opensource/interfaces/" \
    #     "project android/vendor/third/proprietary/camx/" \
    #     "project android/vendor/third/proprietary/chi-cdk/" \
    #     "project android/vendor/third/proprietary/interfaces/" \
    # )
    # 编译 ignore_projects 数组,由于该数组的元素内容带有空格,
    # 要用双引号引起来,才能获取到完整的单个数组元素值.
    # for item in "${ignore_projects[@]}"; do
    #     echo "$project" | grep -wq "$item"
    #     if [ $? -eq 0 ]; then
    #         return 0
    #     fi
    # done
    # return 1
    local IGNORE_PROJECTS_FILE="${HOME}/.liconfig/lyrepo.txt"
    local project="$1"
    # grep的 -w 选项表示要完整全词匹配传入的字符串.例如下面两行:
    # android/frameworks/base/
    # android/frameworks/base/core
    # 那么用 grep -w android/frameworks/base/ 来过滤,只能匹配
    # 第一行.如果不加 -w,会两行都匹配到.
    # grep的 -q 选项的说明如下:
    # Quiet; do not write anything to standard output. Exit immediately
    # with zero status if any match is found.
    # 即,不输出匹配内容,只返回是否匹配到,可以用 $? 来获取这个结果. 
    grep -wq "$project" "${IGNORE_PROJECTS_FILE}"
    return $?
}

# 如上面show_help()的说明,全编译后,部分仓库代码被自动改动,在查看代码
# 修改时,不想打印这些自动改动的代码,只想打印我们自己修改的仓库代码.
# 下面函数用于实现这个功能,在打印仓库改动时,会过滤掉需要忽略的仓库.
repo_status_filter_custom()
{
    local status_temp_file="status_temp.txt"
    local PROJECT_IDENTIFY="project"
    local ignore=0
    local header project_path

    # 为了方便单行处理,把repo status的输出重定向到临时文件,
    # 然后用 read 命令逐行读取文件内容,并进行处理.
    # repo_status_filter 函数使用了grep -B 1 选项,会自动插入
    # "--" 的行,下面用 grep -v 选项反过滤掉这一行.
    # 下面调用的 repo_status_filter 是脚本自定义的函数,而
    # execute_command 通过bash -c来执行传入的命令,bash -c是在
    # 子shell中执行,会找不到 repo_status_filter 函数,除非用
    # export -f命令将repo_status_filter导入到子shell中.目前不采用
    # 这种做法,改成复制repo_status_filter所执行的命令到这里来.
    # repo_status_filter | grep -v '^\-\-' > "${status_temp_file}"
    # 用\换行时,换行后的多个空格会被保留,那么execute_command打印命令
    # 命令时会看到多个空格,为了避免这种情况,下面的grep -v命令写到行首.
    execute_command "${REPO} status -j1 | grep -B1 -E '^\s\-\-|^\s\-m|^\s\-d'|\
grep -v '^\-\-' > ${status_temp_file}"

    while read statusline; do
        # 基于repo status命令的输出,预期包含project字段的格式如下:
        # project android/frameworks/base/ branch branch_name
        header="$(echo ${statusline} | awk '{print $1}')"
        project_path="$(echo ${statusline} | awk '{print $2}')"
        if [ "${header}" == "${PROJECT_IDENTIFY}" ]; then
            check_ignore_project "${project_path}"
            if [ $? -eq 0 ]; then
                # 忽略这个project,不需要打印project信息
                ignore=1;
            else
                # 不要忽略这个project,打印project信息
                ignore=0;
                echo -e "\033[33m${statusline}\033[0m"
            fi
        elif [ ${ignore} -eq 0 ]; then
            # 只在不忽略project时,才打印project的文件变动信息
            echo " ${statusline}"
        fi
    done < "${status_temp_file}"
    rm "${status_temp_file}"
}
#### END ABOVE SPECIAL NOTE

handle_option()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME option"
        return 1
    fi

    local opt="$1"
    case $opt in
        s) repo_status_filter ;;
        sc) repo_status_filter_custom ;;
        rp) repo_forall_reset_pull ;;
        pb) git_pull_current_branch_only ;;
        *) echo "出错: 不支持的选项: $opt"; show_help ;;
    esac
}

# 解析命令选项,每个选项都要以'-'开始
while getopts "b:" opt; do
    case $opt in
        b) set_branch_name $"OPTARG" ;;
        ?) show_help ;;
    esac
done

# $# 等于OPTIND减去1,说明传入的参数都是命令选项.此时,直接
# 结束执行,不需要再往下处理,直接退出.
if [ $# -eq $((OPTIND-1)) ]; then
    exit
fi

# 移动脚本的参数,去掉前面输入的命令选项,只剩下命令简写参数.
shift $((OPTIND-1))
# 处理选项后面的命令简写参数,可以一次传入多个参数,逐个处理.
for arg in "$@"; do
    handle_option "$arg"
done

exit
