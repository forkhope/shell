#!/bin/bash

FRAMEWORKS="frameworks"

# 该函数检查当前工作目录是否存在一个指定的子目录.
# $1 -- 要检查的子目录名
# 如果 $1 不是当前工作目录的子目录,函数会报错返回.
pwd_check_sub_dir()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME dirname"
        return 1
    fi
    local dir_to_check

    dir_to_check="$1"
    if [ ! -d "${dir_to_check}" ]; then
        echo "当前目录 $(pwd) 下不包含指定的 ${dir_to_check} 目录."
        echo "请 cd 到包含 ${dir_to_check} 的目录!"
        return 1
    fi
}
