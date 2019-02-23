#!/bin/bash
# 调用Android SDK Tool的android命令来创建Android project.当前脚本接收两个
# 参数,第一个参数指定Android project的名字和所生成project的存放目录名(为了
# 方便,强制保持Android project名字和所在目录名为同一个名字),第二个参数指定
# Android project默认Activity的名字,可以不提供,默认名字是MainActivity.

if [[ $# -ne 1 && $# -ne 2 ]]; then
    echo "Usage: crdroid.sh <project_name> [<activity_name]"
    exit 1
fi

PROJECT_NAME="$1"
PACKAGE_NAME="com.example.${PROJECT_NAME,,}"
ACTIVITY_NAME="MainActivity"

if [ $# -eq 2 ]; then
    ACTIVITY_NAME="$2"
fi

echo -ne "\033[32m"
echo "PACKAGE_NAME='${PACKAGE_NAME}, PROJECT_NAME='${PROJECT_NAME}'"
echo "ACTIVITY_NAME='${ACTIVITY_NAME}'"
echo -ne "\033[0m"

android create project --target "1" \
    --name ${PROJECT_NAME} --path ${PROJECT_NAME} \
    --activity ${ACTIVITY_NAME} --package ${PACKAGE_NAME}

exit 0
