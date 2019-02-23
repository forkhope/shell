#!/bin/bash
# 使用 ant 编译 debug 版本的apk,安装该apk到机器上,并启动它.当前脚本接收两个
# 参数,第一个参数指定包名,可以不提供,默认使用当前目录名作为包名的最后一部分
# 第二个参数指定所要启动的Activity名,可以不提供,默认名字是MainActivity.

if [[ $# -gt 2 ]]; then
    echo "Usage: crdroid.sh [<activity_name] [<package_name>]"
    exit 1
fi

# 如果传入了第一个参数,则使用传入的参数作为Activity名
if [ -n "$1" ]; then
    ACTIVITY="$1"
else
    # 尝试从Android应用的 AndroidManifest.xml 文件中提取出主Activity的名字.
    # 目前认为Android应用的主Activity是被android.intent.action.MAIN所指定,
    # 且认为在AndroidManifest.xml文件中,主Activity的名字由 android:name 所
    # 指定. 一个例子如下:
    #   <activity android:name="MediaMonitorActivity"
    #      android:label="@string/app_name">
    #      <intent-filter>
    #          <action android:name="android.intent.action.MAIN" />
    # 在上面的例子中, MediaMonitorActivity 就是主Activity的名字.
    # 这部分内容经过下面的语句解析后,得到的内容是: MediaMonitorActivity
    # 之所以使用 '"' 作为 awk 的单词分隔符,而不是使用'=',是因为使用'='的话,
    # 分隔出来的 MediaMonitorActivity 前后会带有双引号,而使用'"'时,不会.
    ACTIVITY="$(grep -B 5 "android.intent.action.MAIN" AndroidManifest.xml\
        | grep "activity android:name" | awk -F '"' '{print $2}')"

    # 如果获取到的 ACTIVITY 名字为空,使用默认的Activity名.
    if [ -z "${ACTIVITY}" ]; then
        # 默认的 Activity 名为 "MainActivity"
        ACTIVITY="MainActivity"
    fi
fi

# 当提供了第二个参数时,使用传入的参数作为包名
if [ -n "$2" ]; then
    PACKAGE="$2"
else
    # 如果不提供第一个参数,默认获取当前目录名来作为包名的最后一部分
    # DIR_NAME="$(basename ${PWD})"
    # 下面的语句将 DIR_NAME 变量值的所有字符都转换为小写.
    # PACKAGE="${DIR_NAME,,}"
    # 这种拼装包名的方式还是不够准确,下面从Anroid应用的AndroidManifest.xml
    # 文件中提取出包名.目前认为包名定义在 package 关键字中.
    PACKAGE="$(grep package AndroidManifest.xml | awk -F '"' '{print $2}')"
fi

# 下面判断得到的包名是否完整.目前认为以"com"开头的包名是完整的.如果不完整,
# 则添加"com.example."到传入的包名开头处.对这条语句的解释如下:
# (1) 使用echo ${PACKAGE} | grep "^com"来判断$PACKAGE中是否以
#     "com"开头.对于grep命令来说,如果匹配到,会返回0,匹配不到,会返回1.
# (2) 使用 ! 操作符对echo ${PACKAGE} | grep "^com"命令的返回值取反.
# (3) 使用 "&&" 连接前后两个语句,只有当前面语句执行成功(返回0)时,才会执行
# 后面语句,所以当$PACKAGE中不以"com"开头时,grep命令返回1,在经过 ! 取
# 反得到0,执行后面的赋值语句,在PACKAGE变量的开头添加上"com.example."
! echo ${PACKAGE} | grep "^com" && \
    PACKAGE="com.example.${PACKAGE}"

echo -ne "\033[32m"
echo "ACTIVITY='${ACTIVITY}', PACKAGE='${PACKAGE}'"
echo -ne "\033[0m"

ant debug install && adb shell "am start -n ${PACKAGE}/.${ACTIVITY}"
