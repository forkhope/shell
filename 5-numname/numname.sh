#!/bin/bash
# 该脚本对当前目录的所有子目录进行重命名,支持下面的操作:
# (1)在目录名的前面添加上一个数字.例如有a,b两个目录,会重命名为1-a,2-b.
# (2)去掉目录名前面的数字编号.例如将 1-a 重命名为 a.
# (3)将以数字开头的目录名的数字加 1,并对目录进行重命名.

# 对目录重命名时,数字编号从 1 开始
sequence=1

# 重命名传入的目录名,在它的前面添加数字编号,该函数不判断传入的参数
# 是否就是一个目录名,由调用函数来保证这一点.
sort_num_dir()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME dirname"
        return 1
    fi
    local dirname="$1"

    mv -v "${dirname}" "${sequence}-${dirname}"
    sequence=$((sequence+1))
}

# 取消传入的目录名中的数字编号,该函数不判断传入的参数是否就是一个目录
# 名,由调用函数来保证这一点. 但是会判断传入的目录名中是否有数字编号.
cancel_num_dir()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME dirname"
        return 1
    fi
    local dirname="$1"

    # 注意,下面这个使用awk的语句有问题,例如目录名为1-a-b,
    # 则下面的语句中,$suffix的值将是a,而不是a-b,而这里需要
    # 的恰好是a-b,而不是a.
    # suffix=$(echo $i | awk -F '-' '{print $2}')
    # 所以,修改成下面的语句,截取第一个'-'之后的内容.
    local suffix="${dirname#*-}"

    # 当截取后的字符串和原来的字符串相等时,说明没有截取任何子字符串,
    # 即原来的字符串不符合截取的规则,在本例中,就是没有包含数字编号.
    if [ "${suffix}" == "${dirname}" ]; then
        echo "传入的目录名 ${dirname} 没有包含数字编号, 忽略."
        return 1
    fi
    mv -v "${dirname}" "${suffix}"
}

# 将当前目录名开头的数字加上 1.例如传入的目录名为1-a,则该函数将所给的目录
# 重命名为2-a.该函数会判断传入的目录名是否以数字开头,如果不是,不会重命名.
increase_num_dir()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME dirname"
        return 1
    fi
    local dirname prefix suffix count

    dirname="$1"
    # 获取目录名中位于'-'之前的部分.
    prefix="${dirname%%-*}"
    # 获取目录名中位于'-'之后的部分.
    suffix="${dirname#*-}"
    count="${#prefix}"

    # 使用正则表达式判断所获取到的目录名前缀是否是数字.
    # =~ 操作符会将右边的字符串视作扩展正则表达式.而 == 和 != 不会.
    if [[ ! "${prefix}" =~ [0-9]{${count}} ]]; then
        echo "传入的目录名不以数字开头,不进行重命名!"
        return 1
    fi

    # 将目录名开头的数字加 1,并用来组装出新的目录名,最后进行重命名.
    # 注意: 这里不是将 count 加 1,而是将 prefix 加 1. count 只是prefix
    # 字符串的长度而已, prefix 对应的才是目录名开头的数字值.
    prefix=$((prefix+1))
    mv -v "${dirname}" "${prefix}-${suffix}"
}

operator_type=""
CANCEL="0"
SORT="1"
INCREASE="2"
# 定义处理函数数组,数组元素的顺序要和上面定义的CANCEL, SORT等常量值一致
dir_func_array=(cancel_num_dir sort_num_dir increase_num_dir)

num_dir_common()
{
    for name in "$@"; do
        # 这里没有判断传入的文件名是否存在,如果不存在,下面的if判断会为假
        if [ -d "${name}" ]; then
            ${dir_func_array[${operator_type}]} "${name}"
        else
            echo "The ${name} isn't a directory, IGNORE."
        fi
    done
}

show_numname_help()
{
printf "USAGE
        $(basename $0) [option] [dirname1 dirname2 ... dirnamen]
OPTIONS
        option: 可选的选项,每次只能提供一个选项,含义如下:
        -h: 可选的第一个参数,将会打印这个帮助信息,然后退出程序.
        -r: 该参数可选,提供该参数,会将目录名前面的数字编号给去掉,例如1-a
            会被重命名为a. 当不提供该参数,会在目录名前面添加数字编号,例如
            目录 a 会被重命名为 1-a. 注意, -r 必须写为第一个参数才有效.
        -s: 该参数将以数字开头的目录名中的数字加 1,并对目录进行重命名.
            例如,原来的目录名是 1-a, 则提供该选项会将该目录重命名为 2-a.
        dirname1 dirname2 ... dirnamen: 
            这些参数就是要重命名的目录名.当不提供-r参数时,第一个目录名的
            编号是1,第二个目录名的编号是2,以此类推.即参数的顺序决定了它们
            的编号大小. 编号从 1 开始.
            如果想重命名当前目录下的所有目录,可以用 '*' 作为参数,shell会
            将'*'扩展为当前目录的所有文件名,但该脚本只对目录做重命名.也可
            以使用\`ls -d */\`,\$(ls -d */)来先获取当前目录下的子目录名.
            如果不提供任何要重命名的目录名,则对当前目录下的所有子目录进行
            重命名,相当于以'*'作为参数.这些参数主要用于重命名部分子目录.
"
}

# 该脚本只支持-h,-r,-s选项,其他以'-'开头的选项将被认为是要重命名的目录名.
if [ "$1" == "-h" ]; then
    show_numname_help
    exit 0
elif [ "$1" == "-r" ]; then
    # 此时,第一个参数"-r"并不是目录名,不需要对它进行重命名操作.使用
    # shift 1来跳过该参数. shift 是Bash内置命令,可以重命名脚本的位置参数.
    shift 1
    operator_type=${CANCEL}
elif [ "$1" == "-s" ]; then
    shift 1
    operator_type=${INCREASE}
else
    operator_type=${SORT}
fi

# 当没有提供参数,或者只提供了-r选项时,将会重命名当前目录下的所有子目录
if [ "$#" == "0" ]; then
    dir_list=$(ls -d */)
else
    dir_list="$@"
fi
num_dir_common ${dir_list}

exit 0
