# 该脚本用于push exdroid目录下的文件到板子上,并重启板子.
#!/bin/bash
set -e

# 导入Android相关脚本的通用常量.
source android.sh

# 编译出来的apk或者jar所在的目录,要求product目录下有且只有一个目录,
# 否则可能会push错文件
SYSTEM_DIR="${EXDROID}/out/target/product/*/system"

# 要push到板子上的目录
BOARD_SYSTEM_DIR="/system"

# BASH 支持关联数组,可以使用任意的字符串作为下标(不必是整数)来访问数组
# 元素.关联数组的下标和值称为键值对,它们是一一对应关系,键是唯一的,值可以
# 不唯一. 注意,在使用关联数组之前,需要使用 declare -A array 来进行显式声明
# 关联数组的常用操作如下:
# ${!array[*]}: 取关联数组所有键
# ${!array[@]}: 取关联数组所有键
# ${array[*]}:  取关联数组所有值
# ${array[@]}:  取关联数组所有值
# ${#array[*]}: 关联数组的长度
# ${#array[@]}: 关联数组的长度
# 定义一个关联数组,将文件后缀名和其前一个目录关联起来.例如Phone.apk
# 是存放在app/目录里面,framework.jar是存放在framework目录里面.
declare -A filetypes
filetypes=([apk]=app [jar]=framework [so]=lib)

# 如果某个文件不带有后缀名,则默认认为它是在bin目录下面
BIN="bin"

function show_help()
{
printf "USAGE
        $(basename $0) filename1 filename2 ... filenamen
OPTIONS
        该脚本接受多个参数,每个参数对应要push到平板上的文件名.
        该名字有两种形式,例如Phone.apk, app/Phone.apk.
        当输入Phone.apk时,脚本会试图自动补全前面的'app/'.
        当输入framework.jar时,脚本会试图自动补全前面的'framework/'.
        而输入app/Phone.apk,或framework/framework.jar时,将不会做目录补全.
        目前支持自动补全的后缀名有:
        (1) apk: 默认认为apk文件存放在 app/ 目录下
        (2) jar: 默认认为jar文件存放在 framework/ 目录下
        (3) so : 默认认为so 文件存放在 lib/ 目录下
        (4) (null): 如果文件名不带有后缀名,默认认为它在 bin/ 目录下
        如果某个文件的后缀名是apk,却不是存放在app/目录下时,需要指定具体的
        目录名,避免push错文件,例如framework/framework-res.apk就要指定前缀.
        同理,不支持自动补全的后缀名也需要指定具体的目录名,如etc/camera.cfg
"
}

function push_file()
{
    # 要求有且只有一个参数,该参数就是要push到板子上的文件名
    if [ "$#" != "1" ]; then
        echo "Usage: ${FUNCNAME} filename"
        return 1
    fi

    # 将传入的参数赋值到 object 变量
    object=$1

    # 获取文件的后缀名,以便根据后缀名来进行目录补全.BASH中,${STR##$PREFIX}
    # 表示: 去头,从开头去除最长匹配前缀.则 ${string##*.} 将去掉所有匹配 *.
    # 的最长前缀,剩下的就是文件的后缀名.
    suffix=${object##*.}

    # dirname: strip last component from file name. 例如:
    # dirname app/Phone.apk 会输出"app". dirname Phone.apk 会输出"."
    dir_name=$(dirname ${object})

    # 对于下面说的"前缀","后缀" 描述如下:
    # 如果传入app/Phone.apk,那么"app"就是前缀,"apk"就是后缀.
    # 如果传入Phone.apk,那么它就是不带前缀,但是带了后缀.
    # 如果传入rild,那么它即不带前缀,也不带后缀.

    # 1. 处理 "有前缀名" 的情况,此时传入参数可以带后缀,也可以不带.
    # 当dirname返回不是"."时,表示传入的参数带有"app/"或者"jar/",此时
    # 直接使用传入的参数名接口.该参数名已经带前缀了,例如app/Phone.apk
    if [ ${dir_name} != "." ]; then
        last_dir=${object}
    # 2. 处理 "不带前缀名,带了后缀名" 的情况.
    # 如果某个文件不带有后缀名,那么$suffix变量的值等于原先的$object的
    # 值.所以$suffix不等于$object时,传入的参数名就带有后缀名
    elif [ ${suffix} != ${object} ]; then
        last_dir=${filetypes["${suffix}"]}/${object}
    # 3. 处理 "不带前缀名,也不带后缀名" 的情况,此时默认该文件在bin目录下
    else
        last_dir=${BIN}/${object}
    fi

    # 补全要push到板子上的目录,例如Phone.apk要push到/system/app下
    object_path="${SYSTEM_DIR}/${last_dir}"
    target_path="${BOARD_SYSTEM_DIR}/${last_dir}"
    echo ${target_path}, ${object_path}

    # 将文件push到板子上
    adb push ${object_path} ${target_path}
}

if [ "$#" == "0" ]; then
    show_help
    exit 1
fi

# 使用source命令执行procommon.sh脚本.注意,该脚本的路径最好写为绝对
# 路径,这样在任何地方执行当前脚本时,当前脚本才能正确的找到procommon.sh
source procommon.sh
# 调用 procommon.sh 中的 setup_remote_path() 函数来设置远程文件系统
setup_remote_path "${EXDROID}"

# $@ 表示命令行的所有参数(不包括$0),下面使用for对其进行遍历,挨个处理
for arg in "$@"; do
    push_file ${arg}
done

# 最开始会执行adb reboot,重启板子.但有时候并不想重启,却还是重启了.
# 所以改成不重启.需要重启时,另外执行命令重启板子即可.
# adb reboot

exit
