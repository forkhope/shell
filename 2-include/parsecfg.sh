#!/bin/bash
# 这个脚本提供函数接口来解析操作特定格式的配置文件.其默认格式为: key|value
# 例如: a|android. 其中, a 就是 key. android 就是 value. 脚本支持如下功能:
# 1.根据所提供的 key 获取到对应的 value.
# 2.查看配置文件的内容.
# 3.使用 vim 打开配置文件,以供编辑.
# 4.提供函数来插入一个键值对到配置文件中.
# 5.提供函数来从配置文件中删除所提供的 key 对应的键值对.
# 上面的 | 是键名和键值之间的分隔符.脚本提供set_info_ifs()函数来设置新的值.

# 定义一个关联数组,保存配置文件中的键值对.会先清空key_values的定义,避免通
# 过 source 命令调用该脚本时, key_values 所保存的值没有被清空,造成干扰.
unset key_values
declare -A key_values

# 该变量保存传入的配置文件名
unset cfg_filename
declare cfg_filename

# 定义配置文件中键名和键值的分隔符,默认是 '|'.可以执行
# set_info_ifs() 函数来设置这个变量的值,从而指定想要的分隔符.
unset info_ifs
info_ifs="|"

# 该函数用于设置配置文件中键名和键值的分隔符.接受一个参数,用于
# 指定新的分隔符.分隔符不累加,而是覆盖之前的值.
set_info_ifs()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME separator"
        return 1
    fi

    info_ifs="$1"
}

# 从传入的项中提取出键名,并把键名写到标准输出,以供调用者读取.
# 下面echo的内容要用双引号括起来.双引号可以避免进行文件名扩展等.
# 当所echo的内容带有 '*' 时,不加双引号的话, '*' 可能会进行文件
# 名扩展,导致输出结果发生变化. 后面的几个函数也要参照这个处理.
get_key_of_entry()
{
    local entry="$1"
    echo "${entry%%${info_ifs}*}"
}

# 从传入的项中提取出键值,并把键值写到标准输出,以供调用者读取.
get_value_of_entry()
{
    local entry="$1"
    echo "${entry#*${info_ifs}}"
}

# 该函数根据传入的键名从 key_values 关联数组中获取对应键值.如果匹配,就将键
# 值写到标准输出,调用者可以读取该标准输出来获取键值.该函数有两个返回值.
# 一个是写入到标准输出的键值,如果没有匹配所提供键名的键值,输出会是空.
# 另一个是函数的返回状态码,如果匹配到,返回为0,如果匹配不到,返回为非0.
get_value_by_key()
{
    local key value
    key="$1"
    value="${key_values["${key}"]}"
    echo "${value}"
    # 判断获取到的键值是否为空,如果不为空,"test -n"的退出状态码是0.如果
    # 为空,"test -n"的退出状态码是1.该函数返回"test -n"命令的退出状态码.
    test -n "${value}"
    return "$?"
}

# 根据传入的键名删除配置文件中对应该键名的行.这里不做过多的参数判断.
# 例如判断是否有第一个参数,判断 cfg_filename 变量的值是否为空.
delete_entry_by_key()
{
    local key="$1"
    # 这里要在${key}的前面加上^,要求${key}必须在行首.
    sed -i "/^${key}|/d" "${cfg_filename}"
    # 将关联数组中对所要删除键名的值设成空.
    key_values["${key}"]=""
}

# 根据传入的键名,删除它在配置文件中对应的行
delete_key_value()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME key_name"
        return 1
    fi
    local key="$1"

    # 如果所给的键名在配置文件中已经存在,get_value_by_key()函数返回0.
    # get_value_by_key() 函数会将获取到键值写到标准输出,为了不显示该
    # 输出,将这个输出结果重定向到 /dev/null.
    get_value_by_key "${key}" > /dev/null
    if [ $? -eq 0 ]; then
        delete_entry_by_key "${key}"
    else
        echo "出错,找不到路径简写 '${key}' 对应的行"
    fi
}

# 该函数先从传入的键值对中解析出键名,然后执行get_value_by_key()函数来
# 判断该键名是否已经在配置文件中,如果在,就删除该键名对应的行.最终,
# 新传入的键值对会被追加到配置文件的末尾.
append_key_value()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME key_value"
        return 1
    fi
    local full_entry key_name match_value
    full_entry="$1"

    # 从传入的键值对中解析出键名
    key_name=$(get_key_of_entry "${full_entry}")
    # 从配置文件中获取该键名对应的值.如果能够获取到值,表示该键名已经存在于
    # 配置文件中,会先删除这个键值对,再追加新传入的键值对到配置文件末尾.
    match_value=$(get_value_by_key "${key_name}")
    if [ $? -eq 0 ]; then
        echo "更新 ${key_name}${info_ifs}${match_value} 为: ${full_entry}"
        delete_entry_by_key "${key_name}"
    fi

    # 追加新的键值对到配置文件末尾
    echo "${full_entry}" >> "${cfg_filename}"
    # 将新项的键名和键值添加到 key_values 数组中,以便实时反应这个修改.
    key_values["${key_name}"]="$(get_value_of_entry "${full_entry}")"
}

# 使用 cat 命令将配置文件的内容打印到标准输出上.
show_config_file()
{
    echo "所传入配置文件的内容为:"
    cat "${cfg_filename}"
}

# 打印从配置文件中解析得到的键值对.
show_key_value()
{
    echo "配置文件中的键值对为:"
    # ${!array[@]} 对应关联数组的所有键. ${array[@]}对应关联数组的所有值.
    # 下面先获取关联数组的键,再通过键名来获取键值,并把键名和键值都打印出来.
    # 用\t来打印TAB进行对齐,如果在\t前面不加空格有时候会对不齐,原因不明.
    for key_name in ${!key_values[@]}; do
        echo -ne "key='\033[32m${key_name}\033[0m' \t"
        echo -e "value='\033[33m${key_values["${key_name}"]}\033[0m'"
    done
}

# 使用 vim 打开配置文件,以供编辑. 注意: 使用vim编辑后,文件所发生的改动不能
# 实时在脚本中反应出来,需要再次执行脚本,重新读取配置文件才能获取到所作的修
# 改.如果要修改这个问题,可以在编辑结束后,再次执行open_config_file()函数.
edit_config_file()
{
    vim "${cfg_filename}"
    # open_config_file "${cfg_filename}"
}

# 在配置文件中查找指定的内容,看该内容是否在配置文件中.
search_value_from_file()
{
    grep "$1" "${cfg_filename}"
    if [ $? -ne 0 ]; then
        echo "配置文件中不包含所给的 '$1'"
        return 1
    fi
}

# 处理配置文件通用的选项.该函数最多接收两个参数.
#   第一个参数: 选项名,该选项名要求以'-'开头,才是合法选项.
#   第二个参数: 选项的参数.
# 当传入的选项被handle_config_option()函数处理时,该函数返回处理后的状态
# 码,如成功返回0,失败返回非0.当传入的选项不被该函数处理时,它返回127.
handle_config_option()
{
    local option argument

    option="$1"
    argument="$2"

    case ${option} in
        -l) show_config_file ;;
        -v) show_key_value ;;
        -i) search_value_from_file "${argument}" ;;
        -e) edit_config_file ;;
        -a) append_key_value "${argument}" ;;
        -d) delete_key_value "${argument}" ;;
         *) return 127 ;;
    esac

    # 当return语句不加上具体状态码时,它会返回上一条执行命令的状态码.
    return
}

# 读取配置文件,并将配置文件的内容保存到关联数组中.每次解释配置文件之前,都
# 要先调用该函数,后续直接通过关联数组来获取对应的值,不再多次打开文件.
# 该函数接受一个参数,指定要解析的配置文件路径.
open_config_file()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME config_filename"
        return 1
    fi

    # 判断所给的配置文件是否存在,且是否是文本文件.
    if [ ! -f "${1}" ]; then
        echo "ERROR: the file '${1}' does not exist"
        return 1
    fi

    local key value
    cfg_filename="${1}"

    # 逐行读取配置文件,并从每一行中解析出键名和键值,保存到关联数组
    # key_values中.后续直接通过键名来获取键值,如果键名不存在,键值会是空.
    while read fileline; do
        # 由于配置文件的键值中可能带有空格,下面的${fileline}要用双引号
        # 括起来,避免带有空格时,本想传入一个参数,却被分割成了多个参数
        # 例如当${fileline}是service list,在不加引号时,get_value_of_entry()
        # 函数会接收到两个参数,第一个参数是$1,对应sservice,第二个参数是$2,
        # 对应list,而get_value_of_entry()函数只获取了第一个参数的值,这样就
        # 会处理出错.在传递变量值给函数时,变量值一定要用双引号括起来.
        key=$(get_key_of_entry "${fileline}")
        value=$(get_value_of_entry "${fileline}")
        key_values["${key}"]="${value}"
        # echo "fileline=${fileline}"
        # echo "key=${key}"
        # echo "value=${value}"
    done < "${cfg_filename}"
    # 查看关联数组 key_values 的值.调试的时候,可以打开下面的注释.
    # declare -p key_values
}

# 在引用这个脚本时,需要传入一个参数,指明配置文件的路径名.
open_config_file "$1"
