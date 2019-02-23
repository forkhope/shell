#!/bin/bash
# 分别将 Android 和 Lichee 的打包方案目录链接到代码根目录下,以便快速进入.

# 导入Android相关脚本的通用常量.
source android.sh

AW_DEVICE_DIR="${EXDROID}/device/softwinner/*ococci"
SYS_PACK_DIR="${LICHEE}/tools/pack*/chips/sun*i*/configs/android/*ococci"

# 将 android 打包方案链接到当前目录后的目录名
TARGET_EXDROID_LINK="config-android"
# 将 lichee 打包方案链接到当前目录后的目录名
TARGET_LICHEE_LINKE="sys-config"

# 先检查当前目录下是否有 "exdroid" 目录,如果没有则报错.
source procommon.sh
pwd_dir_check "${EXDROID}"
if [ $? -ne 0 ]; then
    exit 1
fi

# 为了 AW_DEVICE_DIR 和 SYS_PACK_DIR 中的 '*' 生效,不能用双引号将
# ${AW_DEVICE_DIR} 和 ${SYS_PACK_DIR} 括起来.双引号内不进行文件名扩展.
ococci_android=$(ls -d ${AW_DEVICE_DIR})
ococci_lichee=$(ls -d ${SYS_PACK_DIR})
if [ $? -ne 0 ]; then
    echo -e "\033[31m没有找到 ococci 的打包方案,不生成链接文件.\033[0m"
    exit 1
fi

echo "ococci_android=${ococci_android}"
echo "ococci_lichee=${ococci_lichee}"

# 先删除已经存在的链接文件.使用 "-f" 使得文件不存在时 rm 命令不报错.
rm -f ${TARGET_EXDROID_LINK} ${TARGET_LICHEE_LINKE}
ln -s ${ococci_android} ${TARGET_EXDROID_LINK}
ln -s ${ococci_lichee} ${TARGET_LICHEE_LINKE}

exit
