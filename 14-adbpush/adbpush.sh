#!/bin/bash
# 该脚本用于push exdroid目录下的文件到板子上,并重启板子.
set -e

# 导入Android相关脚本的通用常量.
source android.sh

# Android目录编译出来的apk, so, jar等所在的目录,要求product目录下有且只有
# 一个名字中带有 "ococci" 的目录,否则可能会push错文件.
SYSTEM="/system"
EXDROID_OUT="${EXDROID}/out/target/product/*ococci"
EXDROID_SYSTEM_OUT="${EXDROID_OUT}${SYSTEM}"
# 如果某个文件不带有后缀名,则默认认为它是在bin目录下面
BIN="bin"
BOOT_IMG="boot.img"

# lichee目录编译出来的ko所在的目录.
LICHEE_OUT="${LICHEE}/linux-*/output/lib/modules/*"
KO="ko"
# sys_config.fex配置文件打包后的目录,和要push到板子上的bin文件名.
FEX_OUT="${LICHEE}/tools/pack*/out/sys_config.bin"
FEX_TARGET_BIN="script.bin"

# 板子上的相关目录的路径
SYSTEM_DIR="/system"
DATA_DIR="/data"
DEV_NAND="/dev/block/nand"

# 将 adb命令 定义为只读常量
ADB="adb"
ADB_PUSH="${ADB} push"
ADB_SH="${ADB} shell"

# BASH 支持关联数组,可以使用任意的字符串作为下标(不必是整数)来访问数组元
# 素.关联数组的下标和值称为键值对,它们是一一对应关系,键是唯一的,值可以不
# 唯一. 注意,在使用关联数组之前,需要使用 declare -A array 来进行显式声明.
# 关联数组的常用操作如下:
# ${!array[*]}: 取关联数组所有键
# ${!array[@]}: 取关联数组所有键
# ${array[*]}:  取关联数组所有值
# ${array[@]}:  取关联数组所有值
# ${#array[*]}: 关联数组的长度
# ${#array[@]}: 关联数组的长度
# 定义一个关联数组,将文件后缀名和该类型文件push到板子后的子目录关联起来.
# 例如Mms.apk存放于priv-app/目录,framework.jar存放于framework目录.
declare -A filetypes
filetypes=([apk]="priv-app/" [jar]="framework/" [so]="lib/" [ko]="")

adbpush_show_help()
{
printf "USAGE
        $(basename $0) [option] filename1 filename2 ... filenameN
OPTIONS
        option: 可选选项,描述如下:
            -b: push boot.img到机器里面,并烧写该img到nandc
            -f: push sys_config.fex打包后的bin文件到机器里面
        该脚本接受多个参数,每个参数对应要push到平板上的文件名.
        该名字有两种形式,例如Mms.apk, priv-app/Mms.apk.
        当输入Mms.apk时,脚本会试图自动补全前面的'priv-app/'.
        当输入framework.jar时,脚本会试图自动补全前面的'framework/'.
        而输入priv-app/Mms.apk,或framework/framework.jar时,不做目录补全.
        目前支持自动补全的后缀名有:
        (1) apk: 默认认为apk文件存放在 priv-app/ 目录下
        (2) jar: 默认认为jar文件存放在 framework/ 目录下
        (3) so : 默认认为so文件存放在 lib/ 目录下
        (4) ko : 默认认为ko文件不需要前面的子目录名.
        (5) (null): 如果文件名不带有后缀名,默认认为它在 bin/ 目录下
        如果某个文件的后缀名是apk,却不是存放在priv-app/目录下时,需要指定详
        细路径名,避免push错文件,例如framework/framework-res.apk就要指定前缀
        同理,不支持自动补全的后缀名也需要指定具体的目录名,如etc/camera.cfg
"
}

push_bootimg()
{
    local block_name
    block_name="${DEV_NAND}c"

    ${ADB_PUSH} ${EXDROID_OUT}/${BOOT_IMG} "${DATA_DIR}"
    ${ADB_SH} dd if=${DATA_DIR}/${BOOT_IMG} of=${block_name}
    ${ADB_SH} sync
}

push_fex()
{
    # 下面将临时目录名从"/a"改成"/data/fex".有些机器的根目录是只读的,
    # 不能在它下面创建目录.而Android的"/data"目录一般都是可读可写.
    local temp_dir="/data/fex"
    local nanda="${DEV_NAND}a"

    ${ADB_SH} mkdir "${temp_dir}"
    ${ADB_SH} mount -t vfat "${nanda}" "${temp_dir}"
    # 下面是 A13 打包后的bin文件路径.
    # adb push ${LICHEE}/tools/pack/out/bootfs/script.bin ${temp_dir}
    # 下面是 A31s Andrroid4.4 打包后的bin文件路径.
    # 注意:为了让FEX_OUT中的'*'号生效,不能用双引号括起来.双引号内不进行
    # 文件名扩展和波浪号扩展.
    ${ADB_PUSH} ${FEX_OUT} "${temp_dir}/${FEX_TARGET_BIN}"

    ${ADB_SH} umount ${temp_dir}
    # 即使重启机器,"/data"目录下的改变也不会被还原,如果不删除该目录,则重复
    # 执行该函数时,上面的mkdir命令会报错.由于脚本设置了"set -e"标记,遇错就
    # 会停止执行脚本.为了避免这种情况,下面删除刚才创建的临时目录.
    ${ADB_SH} rm -rf ${temp_dir}
}

push_file()
{
    # 要求有且只有一个参数,该参数就是要push到板子上的文件名.
    if [ $# -ne 1 ]; then
        echo "Usage: ${FUNCNAME} filename"
        return 1
    fi
    local object suffix dir_name last_dir
    local file_out_dir="${EXDROID_SYSTEM_OUT}"
    local board_target_dir="${SYSTEM}"

    # 将传入的参数赋值到 object 变量.
    object="$1"

    # 获取文件的后缀名,以便根据后缀名来进行目录补全.BASH中,${STR##$PREFIX}
    # 表示: 去头,从开头去除最长匹配前缀.则 ${string##*.} 将去掉所有匹配 *.
    # 的最长前缀,剩下的就是文件的后缀名.
    suffix="${object##*.}"

    # dirname: strip last component from file name. 例如:
    # dirname app/Mms.apk 会输出"app". dirname Mms.apk 会输出"."
    dir_name=$(dirname ${object})

    # 对于下面说的"前缀","后缀" 描述如下:
    # 如果传入app/Mms.apk,那么"app"就是前缀,"apk"就是后缀.
    # 如果传入Mms.apk,那么它就是不带前缀,但是带了后缀.
    # 如果传入rild,那么它即不带前缀,也不带后缀.

    # 1. 处理 "有前缀名" 的情况,此时传入参数可以带后缀,也可以不带.
    # 当dirname返回不是"."时,表示传入的参数带有"app/"或者"jar/",此时
    # 直接使用传入的参数名接口.该参数名已经带前缀了,例如app/Mms.apk
    if [ "${dir_name}" != "." ]; then
        last_dir="${object}"
    # 2. 处理 "不带前缀名,带了后缀名" 的情况.
    # 如果某个文件不带有后缀名,那么$suffix变量的值等于原先的$object的
    # 值.所以$suffix不等于$object时,传入的参数名就带有后缀名.
    elif [ "${suffix}" != "${object}" ]; then
        last_dir=${filetypes["${suffix}"]}${object}
        # lichee编译出来的ko文件跟Android编译出来的文件位于不同的目录下.
        # 如果所给文件的后缀名是ko时,修改所要拷贝目录为lichee的out目录.
        if [ "${suffix}" == "${KO}" ]; then
            file_out_dir="${LICHEE_OUT}"
            board_target_dir+="/vendor/modules"
        fi
    # 3. 处理 "不带前缀名,也不带后缀名" 的情况,此时默认该文件在bin目录下.
    else
        last_dir="${BIN}/${object}"
    fi

    # 补全要push到板子上的目录,例如Mms.apk要push到/system/app下.
    object_path="${file_out_dir}/${last_dir}"
    target_path="${board_target_dir}/${last_dir}"
    echo "'${object_path}' -> '${target_path}'"

    # 将文件push到板子上.下面的 ${object_path} 不能用双引号括起来.
    ${ADB_PUSH} ${object_path} "${target_path}"
    # 由于内核对ko文件的权限要求是644,所以push ko文件后,需要修改权限.
    if [ "${suffix}" == "${KO}" ]; then
        ${ADB_SH} "chmod 644 ${target_path}"
    fi
}

if [ $# -eq 0 ]; then
    adbpush_show_help
    exit 1
fi

# 使用source命令执行procommon.sh脚本.注意,该脚本的路径最好写为绝对
# 路径,这样在任何地方执行当前脚本时,当前脚本才能正确的找到procommon.sh
source procommon.sh
# 调用 procommon.sh 中的 setup_remote_path() 函数来设置远程文件系统.
setup_remote_path "${EXDROID}"

# 在一些项目上,默认配置系统盘为只读,如果不先执行adb remount命令的话,不能
# push文件到机器里面,会提示"Read-only file system",所以下面先remount.
${ADB} remount

while getopts "bf" opt; do
    case ${opt} in
        b) push_bootimg ;;
        f) push_fex ;;
        ?) show_help ;;
    esac
done

if [ $# -eq $((OPTIND-1)) ]; then
    exit 0
fi

# $@ 表示命令行的所有参数(不包括$0),下面使用for对其进行遍历,挨个处理.
shift $((OPTIND-1))
for arg in "$@"; do
    push_file "${arg}"
done

# 最开始会执行adb reboot,重启板子.但有时候并不想重启,却还是重启了.
# 所以改成不重启.需要重启时,执行其他命令重启板子即可.
# adb reboot
