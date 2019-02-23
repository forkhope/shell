#!/bin/bash

# 该函数检查当前工作目录是否存在一个指定的子目录.
# $1 -- 要检查的子目录名
# 如果 $1 不是当前工作目录的子目录,函数会报错返回.
pwd_dir_check()
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

# 该函数接受两个参数,用于检查当前工作目录下是否包含一个子目录.
# $1 -- 指定要查找的父目录名
# $2 -- 指定要检查的子目录名
# 如果在当前工作目录下找不到 $2 对应的子目录,将获取 $1 下的子目录名,并
# 传递给 select 语句来弹出一个选择菜单,以供选择要cd到的目录,然后 cd 到
# $1 指定的目录下.注意: 该函数不会 cd 到 $2 指定的子目录下.
cd_project_root()
{
    if [ $# -ne 2 ]; then
        echo "Usage: $FUNCNAME dirpath dir_to_check"
        return 1
    fi
    local dirpath dir_to_check ls_list rootdir

    dirpath="$1"
    dir_to_check="$2"
    if [ ! -d "${dir_to_check}" ]; then
        # 在获取 $1 目录下的子目录名,要求这些子目录名中带有字符'-'.这是
        # 根据实际目录结构来的,不具有移植性.
        ls_list=$(ls -d ${dirpath}/*-*/)
        select rootdir in ${ls_list}; do
            # 注意,select语句中,如果输入的选择不包含在选择列表上时,rootdir
            # 的值会是空,所以需要先判断rootdir的值是否为空,不为空才是对的.
            if [ -n "${rootdir}" ]; then
                \cd "${rootdir}"
                # cd 到选择的目录后,再次判断当前目录是否包含指定的子目录.
                pwd_dir_check "${rootdir}"
                break
            fi
        done
    fi
}

# 该函数用于挂载远程文件系统,并 cd 到指定的远程目录上.
# $1 -- 要 cd 到的远程目录名
setup_remote_path()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME remote_dirname"
        return 1
    fi
    local root_dir="$1"
    local MOUNT_ROOT="/mnt/smb"
    local MOUNT_TEST="${MOUNT_ROOT}/bin"

    # 该判断用于检测是否已经挂载了远程文件系统. 192.168.1.88服务器的目录被
    # 挂载在/mnt/smb目录下,我在服务器上建了一个bin目录,用该目录来做判断依据
    # 首先会判断/mnt/smb/bin目录是否存在,如果不存在,认为远程文件系统还没有
    # 挂载,执行mount命令去挂载它.显而易见,如果该目录已经存在,则已经挂载了.
    if [ ! -d "${MOUNT_TEST}" ]; then
        echo "远程文件系统没有挂载,将尝试挂载......"
        sudo mount //192.168.1.88/john /mnt/smb \
            -o codepage=cp936,iocharset=utf8,username=john,passwd=1qaz2wsx
    fi

    cd_project_root "${MOUNT_ROOT}" "${root_dir}"
}
