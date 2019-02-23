#!/bin/bash
# 这是一个git命令辅助脚本.可以输入一些常用git命令的简写来执行对应的git命令.
# 例如提供 ln 这个参数,脚本会执行 git log --name-status 命令.减少输入量.
# 其实 git 提供了这样的别名功能.在 .gitconfig 中添加"[alias]"项就能设置命令
# 别名.只是在知道这一点之前,该脚本已经写好,于是又另外添加了repo命令的简写.

# git辅助命令的配置文件.这个配置文件中的部分命令是该脚本自定义的函数.
GIT_HELPER="${HOME}/.myconf/gitinfo.txt"

# 将 git, repo 命令定义为常量.
GIT="git"
REPO="repo"
REPO_GIT="${REPO} forall -p -c ${GIT}"

lgit_show_help()
{
printf "USAGE
        $(basename $0) [option] cmd [argument1 [... [argumentn]]]
OPTIONS
        option: 可选选项,描述如下:
            -h: 打印这个帮助信息,并退出.
            -l: 查看脚本支持的命令简写及其对应的命令.
            -v: 以键值对的方式打印详细的配置文件信息.
            -i: 在配置文件中查找指定内容.需要一个参数来指定要查找的内容.
            -e: 使用 vim 打开脚本的配置文件,以供编辑.
            -a: 增加或修改一个命令简写和对应的命令到配置文件.需要一个参数,
                用单引号括起来,以指定命令简写和命令.格式为: 路径简写|路径.
                例如-a 's|git status',如果s简写不存在则新增它,否则修改它.
            -d: 从脚本配置文件中删除一个命令简写和对应的命令.需要一个参数,
                以指定命令简写,脚本将从配置文件中删除该命令简写对应的行.
                例如 -d s, 将删除命令简写为 s 的行.
        cmd: 所要执行的命令简写.支持的简写可以用-l或-v选项来查看.
        argument1 ... argumentn:
            命令简写对应命令的参数.
"
}

# 执行,并打印所提供的命令.
execute_command()
{
    local cmd="$1"

    # ${cmd} ----> 原先只写为这一句,想要执行 ${cmd} 字符串所对应的命令.
    # 例如,当${cmd}为"git status"时,想要执行该命令.实际执行发现,当配置
    # 文件中指定的命令不带双引号时,该命令就能被执行 (如git status).当
    # 指定的命令带有双引号时,就命令就不会被执行 (如git log --author="
    # john@ococci.com").而git log --author=john@ococci.com能被执行.
    # 执行set -x,打开脚本调试信息.发现指定的命令带有双引号时,${cmd}被
    # 扩展为如下的形式.即在 --author 前后多了一对单引号.
    #   + git log --name-status '--author="john@ococci.com"'
    # 目前认为,出现这种情况的原因在于,所获取的命令中带有双引号,为了在
    # 进行引号移除操作时不移除这个双引号,所以用单引号将它们括起来.
    #
    # 如果将 ${cmd} 用双引号括起来,可以避免这种情况,但是会报另外的错:
    #   + 'git log --name-status --author="john@ococci.com"'
    #   git log --name-status --author="john@ococci.com": 未找到命令
    # 可以看到, "${cmd"} 扩展的结果被单引号括起来,整个扩展结果被当成独
    # 立的单词,所要执行的命令名不再是git,而是这整个字符串,找不到该命令.
    #
    # 此时有两个方法可以避免这个问题: (1)配置文件中的命令都去掉双引号.
    # 这个可以做到,因为"--author"选项并不要求参数带双引号. (2)使用
    # "bash -c"来执行${cmd}所指定的命令.配置文件中的命令可以带有双引号,
    # 而 ${cmd} 要用双引号括起来,写成 bash -c "${cmd}" 的形式.
    #
    # 使用 set -x 查看 bash -c ${cmd} 的扩展结果,输出的结果如下:
    #   + bash -c git log --name-status '--author="john@ococci.com"'
    # 可以看到, --author 前面还是有一对单引号.此时这个 git 命令会报错,
    # 它无法处理 '--author="john@ococci.com"' 这个参数.
    #
    # 使用 set -x 查看 bash -c "${cmd}" 的扩展结果,输出的结果如下:
    #   + bash -c 'git log --name-status --author="john@ococci.com"'
    # 可以看到,整个${cmd}命令的扩展结果前面多了一对单引号,被当成一个
    # 独立的整体看待.此时,这个 git 命令能正确执行,不会报错.
    # bash -c "${cmd}"
    #
    # 当配置文件中指定该脚本自定义的函数时,需要使用export -f命令来将
    # 这些函数以及相关全局变量导入到子shell中,子shell才能正确执行这些
    # 函数.目前觉得有点麻烦,先改成配置文件命令不带双引号的形式.
    #
    # 将位置参数左移一位,移除命令名,剩下的就是命令选项 (如果有的话),传
    # 递这些命令选项给所要执行的命令.例如, repo_push() 需要额外的参数.
    shift 1
    ${cmd} "$@"

    # 打印刚才执行的命令名,及其参数.有些命令会输出很多内容,先打印命令
    # 名的话,需要拉动终端滚动条,才能找到打印出来的命令名,不方便查看.
    echo -e "\033[33m${cmd} $@\033[0m"
}

# 查看所有仓库状态.repo status命令的输出结果已经过滤过,不需要再过滤.
# 该函数的第一个参数用于指定并发查询的线程数,如果没有指定,默认是 4.
repo_status()
{
    local job_number=4
    if [ $# -eq 1 ]; then
        job_number="$1"
    fi

    # 使用repo status的"-j"选项开启多线程查询,加快该命令的执行速度
    reset; execute_command ${REPO} status -j "${job_number}"
    # 如果某个仓库的输出结果多于一页时, repo status 会使用 less 命令先显示
    # 这个输出结果,需要手动翻页,或者输入q来退出less命令,为了避免这种情况,可
    # 以直接使用cat命令来显示输出结果,但是这样又失去了颜色高亮,先注释它.
    # ${REPO} status -j ${job_number} | cat
}

# 更新所有仓库代码.为了方便查看具体哪些仓库发生了改动,下面使用grep命令
# 过滤了repo forall -p -c git pull命令的输出结果.
repo_pull()
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
    # reset; ${REPO_GIT} pull |& grep -E "project|\|"
    #
    # !!注意!!: 这条语句表示将"execute_command ${REPO_GIT} pull"命令的
    # 输出结果通过管道 |& 重定向到 grep 命令. |& 本身,以及它后面的参数不会
    # 被传递到 execute_command() 函数.如果用双引号将 |& 括起来,它以及它后
    # 面的参数就能被传递到execute_command()函数,但是在函数内获取该参数时,
    # 它会被单引号括起来,从而失去原有的特殊含义,不再作为管道操作符使用,这
    # 条 repo 命令会执行出错,所以没有这么做,而是额外查找"repo"这个字符串,
    # 在输出结果中包含 execute_command() 函数所打印的命令名及其参数.
    reset; execute_command ${REPO_GIT} pull |& grep -E "project|\||repo"
}

# 对所有仓库执行git push命令,推送更新到远程仓库上.该函数接受两个或三个参数.
#   第一个参数指定远程仓库名.               第二个参数指定本地分支名.
#   第三个参数指定远程分支名.如果不提供该参数,远程分支和本地分支同名.
repo_push()
{
    if [[ $# -ne 2 && $# -ne 3 ]]; then
        echo "Usage: ${FUNCNAME} repository local_branch [remote_branch]"
        return 1
    fi
    local repository local_branch remote_branch

    repository="$1"
    local_branch="$2"
    if [ $# -eq 3 ]; then
        remote_branch="$3"
    else
        remote_branch="$2"
    fi

    reset; execute_command ${REPO_GIT} push \
        ${repository} ${local_branch}:${remote_branch}
}

# 在 git log 上库注释中查找指定的信息. 该函数接受如下的参数:
#   $1: 指定用来查找信息的命令.如 git(查找单独仓库), repo(查找所有仓库)等.
#   $2: 要查找的模式,可以使用正则表达式.必选参数.
#   $3: 要查找哪个作者的上库信息.可选参数,如果不指定,查找所有人的上库信息.
# git log --grep=<pattern>: Limit the commits output to ones with log
#   message that matches the specified pattern (regular expression).
# git log --author=<pattern>, --committer=<pattern>: Limit the commits
#   output to ones with author/committer header lines that match the
#   specified pattern (regular expression).
grep_git_commit()
{
    # 这个函数会被调用来查找git上库注释,下面的帮助信息希望显示调用该函数
    # 的那个函数名,而不是显示这个函数名本身.所以使用 ${FUNCNAME[1]} 来获
    # 取函数堆栈中栈顶的下一个元素,即调用这个函数的那个函数名.
    if [ $# -lt 2 ]; then
        echo "Usage: ${FUNCNAME[1]} command pattern [author]"
        return 1
    fi
    local cmd pattern author

    cmd="$1"
    pattern="--grep=$2"
    if [ $# -eq 3 ]; then
        author="--author=$3"
    fi

    reset; execute_command ${cmd} log --name-status ${pattern} ${author}
}

# 在单独的 git 仓库中查找指定的上库注释,可以指定查找模式和上库作者.
git_log_grep()
{
    grep_git_commit "${GIT}" "$@"
}

# 在 repo 的所有 git 仓库中查找指定的上库注释,可以指定查找模式和上库作者.
repo_log_grep()
{
    grep_git_commit "${REPO_GIT}" "$@"
}

# 添加当前目录下的改动 (修改的文件,新增的文件,删除的文件),并进行提交.
git_add_commit()
{
    if [ $# -ne 1 ]; then
        echo "Usage: ${FUNCNAME} commit_message"
        return 1
    fi
    local message="$1"

    # git add 的 -A 选项能同时添加所修改的文件和被删除的文件,不需要分别
    # 执行 "git add ." 和 "git add -u ." 命令.
    execute_command ${GIT} add -A .
    execute_command ${GIT} status
    execute_command ${GIT} commit -m "${message}"
}

# 查找当前目录下所有的 git patch 文件,并尝试合入该补丁.
git_apply()
{
    for name in $(ls *.patch); do
        echo "Patch name: $name"
        # 打补丁后,删除补丁文件,避免用 git 提交修改时,误提交该补丁.
        execute_command ${GIT} apply "${name}"
        rm "${name}"
    done
}

# 过滤repo -p -c git log --name-status命令所生成的git log信息,会进行两次过
# 滤.第一次过滤后的结果只包含以"project"开头,以"M "(M后面是空格)开头,以"A "
# (A后面是空格)开头的行.针对第一次过滤后的内容再进行第二次过滤,将"project"
# 后面跟着的仓库名添加到git log命令所打印的文件路径前面,组成完整的文件路径.
# 并进行排序,删除重复行.之所以进行第二次过滤,就是为了删除重复出现的文件名.
# 例如第一次过滤后的部分内容如下.其中,"project"后面的"linux-3.4"是仓库名,
# "M"后面的内容是该仓库下发生变动的文件路径,添加上仓库名后就是完整的路径名.
# project linux-3.4/
# M   drivers/input/sw-device.c
# 则第二次过滤后的内容是: linux-3.4/drivers/input/sw-device.c
# 这种内容方便被脚本处理.例如 cpcode.sh 所处理的就是这种格式的内容.
git_log_filter()
{
    if [ $# -lt 1 ]; then
        echo "Usage: ${FUNCNAME} git_log_filename [target_filename]"
        return 1
    fi
    local DEFAULT_TARGET_FILENAME="final-filter-gitlog.txt"
    local PROJECT_IDENTIFY="project"
    local temp="filter-temp.txt"
    local filename target
    local header project_dir sub_file_path full_file_path

    # 获取要解析的源文件名,并把要过滤的git log信息写入到该文件.
    filename="${1}"
    # FIXME: 目前只是简单地把所有仓库中特定作者的git log信息获取出来,
    # 不具有通用性.后续有需要的话,再做扩展.
    ${REPO_GIT} log --name-status --author=john@ococci.com > "${filename}"

    # 保存过滤结果的文件名,可以通过第二个参数来指定
    if [ $# -eq 2 ]; then
        target="${2}"
    else
        target="${DEFAULT_TARGET_FILENAME}"
    fi

    # \s表示空格,"^M\s"要求以M开头且M后面跟着空格. "^A\s"的效果类似.
    # !!注意!!: 下面这条语句中, > "${temp}" 并不是execute_command函数的
    # 参数,虽然本意上期望是这样,但实际上,execute_command函数中的所有输出都
    # 会重定向到"${temp"}指定的文件中,包括最后echo输出的命令内容.所输出
    # 的命令内容是不需要的信息,所以用sed命令删除文件的最后一行,去掉它.
    execute_command grep -E '^project|^M\s|^A\s' "${filename}" > "${temp}"
    sed -i '$d' "${temp}"

    while read fileline; do
        header="$(echo ${fileline} | awk '{print $1}')"
        if [ "${header}" == "${PROJECT_IDENTIFY}" ]; then
            project_dir="$(echo ${fileline} | awk '{print $2}')"
        else
            sub_file_path="$(echo ${fileline} | awk '{print $2}')"
            full_file_path="${project_dir}${sub_file_path}"
            echo "${full_file_path}" >> "${target}"
        fi
    done < "${temp}"

    # 对生成的文件内容进行排序,并删除重复行.
    cat "${target}" | sort | uniq > "${temp}"

    # 将临时文件改名为最终的文件名.
    mv "${temp}" "${target}"
}

# 下载并切换到远程分支上.其第一个参数指定切换单独git仓库,还是切换repo仓库.
checkout_remote_branch()
{
    if [ $# -ne 3 ]; then
        echo "Usage: ${FUNCNAME} command local_branch remote_branch"
        return 1
    fi
    local cmd local_branch remote_branch

    cmd="$1"
    local_branch="$2"
    remote_branch="$3"
    execute_command ${cmd} checkout -b "${local_branch}" "${remote_branch}"
}

# 在单独的 git 仓库中下载并切换到远程分支上.
git_checkout_remote_branch()
{
    checkout_remote_branch "${GIT}" "$@"
}

# 在 repo 的所有 git 仓库中下载并切换到远程分支上.
repo_checkout_remote_branch()
{
    checkout_remote_branch "${REPO_GIT}" "$@"
}

# 处理所提供的命令简写,以及剩余的命令参数.
handle_input()
{
    local key cmd

    key="$1"
    cmd="$(get_value_by_key "${key}")"
    if [ $? -eq 0 ]; then
        # 将位置参数左移一位,移除命令简写这个参数,剩下的是待处理的参数.
        shift 1
        execute_command "${cmd}" "$@"
    else
        echo "出错,找不到命令简写 '${key}' 对应的行"
    fi
}

if [ $# -eq 0 ]; then
    lgit_show_help
    exit 1
fi

# 如果 parsecfg.sh 解析配置文件失败,则退出,不再往下执行.
source parsecfg.sh "${GIT_HELPER}"
if [ $? -ne 0 ]; then
    exit
fi

# 获取命令选项,并处理.
while getopts "hlvi:ea:d:" opt; do
    handle_config_option "-${opt}" "${OPTARG}"
    if [ $? -ne 127 ]; then
        continue
    fi

    case ${opt} in
        h) lgit_show_help ;;
        ?) lgit_show_help ;;
    esac
done

# 如果所提供的参数全都是命令选项,则直接退出,不再往下执行.
if [ $# -eq $((OPTIND-1)) ]; then
    exit
fi

# 移动脚本的位置参数,去掉上面已经处理过的命令选项,剩下待处理的参数.
# 待处理的参数分为命令简写,命令简写对应命令的参数.
shift $((OPTIND-1))
handle_input "$@"
