#!/bin/bash
# 过滤repo -p -c git log --name-status命令所生成的git log信息,过滤后的结果
# 只包含以"project"开头,以"M "(M后面是空格)开头,以"A "(A后面是空格)开头的行

if [ $# -lt 1 ]; then
    echo "Usage: $(basename $0) git_log_filename [target_filename]"
    exit 1
fi

# 要解析的源文件名
filename="${1}"

# 保存解析结果的文件名,可以通过第二个参数来指定
target_filename="after-gitlog.txt"
if [ $# -eq 2 ]; then
    target_filename="${2}"
fi

# \s表示空格,"^M\s"要求以M开头且M后面跟着空格. "^A\s"的效果类似
grep -E '^project|^M\s|^A\s' ${filename} > ${target_filename}

exit
