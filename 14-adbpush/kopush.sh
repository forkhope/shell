#!/bin/bash
set -e

# 导入Android相关脚本的通用常量.
source android.sh

LINUX="linux"
MIDDLE_PATH="output/lib/modules"
TARGET_PATH="/vendor/modules/"
ADB_PUSH="adb push"
ADB_SH="adb shell"

# 使用source命令执行procommon.sh脚本.注意,该脚本的路径最好写为绝对
# 路径,这样在任何地方执行当前脚本时,当前脚本才能正确的找到procommon.sh
source procommon.sh
# 调用 procommon.sh 中的 setup_remote_path() 函数来设置远程文件系统
setup_remote_path "${LICHEE}"

show_help()
{
printf "USAGE
        $(basename $0) [option] koname1 koname2...
OPTIONS
    option: 可选选项,描述如下:
        -b: push boot.img到机器里面,并烧写该img到nandc
        -f: push sys_config.fex打包后的bin文件到机器里面
    koname1 koname2...: 要push到机器的驱动文件名,可指定多个名字
"
}

push_bootimg()
{
    local data_dir boot_img block_name
    data_dir="/data"
    boot_img="boot.img"
    block_name="/dev/block/nandc"

    ${ADB_PUSH} exdroid/out/target/product/*-ococci/${boot_img} ${data_dir}
    ${ADB_SH} dd if=${data_dir}/${boot_img} of=${block_name}
    ${ADB_SH} sync
}

push_fex()
{
    # 下面将临时目录名从"/a"改成"/data/a".有些机器的根目录是只读的,不能
    # 在它下面创建目录.而Android的"/data"目录一般都是可读可写.
    local temp_dir="/data/a"
    ${ADB_SH} mkdir ${temp_dir}
    ${ADB_SH} mount -t vfat /dev/block/nanda ${temp_dir}
    #adb push lichee/tools/pack/out/bootfs/script.bin ${temp_dir}
    # 下面是 A23 打包后的bin文件路径
    ${ADB_PUSH} lichee/tools/pack/out/sys_config.bin ${temp_dir}/script.bin
    # 下面是 A31s Andrroid4.4 打包后的bin文件路径
    # ${ADB_PUSH} lichee/tools/pack_brandy/out/sys_config.bin ${temp_dir}/script.bin
    ${ADB_SH} umount ${temp_dir}
    # 即使重启机器,"/data"目录下的改变也不会被还原,如果不删除该目录,则重复
    # 执行该函数时,上面的mkdir命令会报错.由于脚本设置了"set -e"标记,遇错就
    # 会停止执行脚本.为了避免这种情况,下面删除刚才创建的临时目录.
    ${ADB_SH} rm -rf ${temp_dir}
}

# 传入的参数就是要push到板子上的ko名字
if [ "$#" == "0" ]; then
    show_help
    exit 1
fi

# A20下有linux-3.3, linux-3.4目录,实际编译的是linux-3.4目录,
# 所以这里需要选择到linux-3.4目录.之所以没有强制写为linux-3.4,
# 是因为A13, A31s等只有linux-3.3目录,下面做个判断,让该脚本更通用.
# 判断时,认为lichee目录下版本号最高的linux目录是被编译的目录.
# 例如A20下有linux3.3, linux3.4,则认为linux3.4才是被编译的目录.
maxversion="linux"
for i in $(ls -d ${LICHEE}/${LINUX}*); do
    if [ "${maxversion}" < "${i}" ]; then
        maxversion=${i}
    fi
done

while getopts "bf" arg; do
    case ${arg} in
        b) push_bootimg ;;
        f) push_fex ;;
        ?) show_help ;;
    esac
done

if [ "$#" == "$((OPTIND-1))" ]; then
    exit
fi

# version_num=$(echo ${maxversion} | awk -F '-' '{print $2}')
# 本来打算在modules_path中填充版本号,但是A13的linux-3.0上,它生成
# 的out里面的版本号却是3.0.8+,和3.0不等,导致出错,只好改成下面的
# 方式,此时假设modules目录下只有一个子目录,否则可能出错.
shift $((OPTIND-1))
for arg in "$@"; do
    modules_path=${maxversion}/${MIDDLE_PATH}/*/${arg}
    echo "'$modules_path' -> '${TARGET_PATH}${arg}'"
    ${ADB_PUSH} ${modules_path} ${TARGET_PATH}
    ${ADB_SH} chmod 644 ${TARGET_PATH}${arg}
done

exit
