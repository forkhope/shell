# 介绍一个解析、以及增删改查键值对格式配置文件的 shell 脚本

# 介绍配置文件的格式和使用场景
本篇文章介绍一个解析、以及增删改查键值对格式配置文件的 bash shell 脚本。

该 shell 脚本处理的基本配置格式信息是：`key|value`。

在脚本中，把 *key* 称为 “键名”。把 *value* 称为 “键值”。

把整个 *key|value* 称为 “键值对”。

把中间的 *|* 称为 “分隔符”。

默认的分隔符是 *|*。脚本里面提供了设置函数可以修改分隔符的值，以便自定义。

基于这个配置格式，可以配置下面的一些信息。

## 配置目录路径简写
配置一个目录路径简写，通过一个、或几个字符，就可以快速 `cd` 到很深的目录底下。

例如，在配置文件中有下面的信息：
```
am|frameworks/base/services/core/java/com/android/server/am/  
w|frameworks/base/wifi/java/android/net/wifi/
```
假设有一个 `quickcd.sh` 脚本可以解析这个配置信息。

在执行 `quickcd.sh w` 命令时，该脚本会基于 *w* 这个键名，获取到 *frameworks/base/wifi/java/android/net/wifi/* 这个键值。

然后脚本里面执行 `cd frameworks/base/wifi/java/android/net/wifi/` 命令，进入到对应的目录下。

这样就不需要输入多个字符，非常方便。

后面的文章会介绍在不同目录之间快速来回 `cd` 的 `quickcd.sh` 脚本。

同时，所解析的配置信息保存在配置文件里面。

如果要新增、删除配置项，修改配置文件自身即可，不需要改动脚本代码。

这样可以实现程序数据和程序代码的分离，方便复用。

## 配置命令简写
配置一个命令简写，通过一个、或几个字符，就可以执行相应的命令。

例如，在配置文件中有如下的信息：
```
l|adb logcat -b all -v threadtime
png|adb shell "screencap /sdcard/screen.png"
```
这里配置了 Android 系统的 adb 命令。

类似的，假设有一个 `quickadb.sh` 脚本可以解析这个配置信息。

执行 `quickadb.sh l` 命令，该脚本实际会执行 `adb logcat -b all -v threadtime` 命令。

这样可以减少输入，快速执行内容比较长的命令。

使用配置文件保存命令简写，可以动态添加、删除命令，跟脚本代码独立开来。

后面的文章会介绍一个通过命令简写执行对应命令的 `tinyshell.sh` 脚本。

## 使用场景总结
总的来说，这里介绍的配置文件是基于键值对的形式。

常见的使用场景是，提供比较简单的键名来获取比较复杂的键值，然后使用键值来进行一些操作。

但是在实际输入的时候，只需要输入键名即可，可以简化输入，方便使用。

当然，实际使用并不局限于这些场景。

如果有其他基于键值对的需求，可以在对应的场景上使用。

# 脚本使用方法
这个解析配置文件的 shell 脚本是一个独立的脚本，可以在其他脚本里面通过 `source` 命令进行调用。

假设脚本文件名为 `parsecfg.sh`，调用该脚本的顺序步骤说明如下：

- `source parsecfg.sh`

    在调用者的脚本中引入 `parsecfg.sh` 脚本的代码，以便后续调用 `parsecfg.sh` 脚本里面的函数。

    这里需要通过 `source` 命令来调用，才能共享 `parsecfg.sh` 脚本里面的函数、全局变量值。

- （可选的）`set_info_ifs separator`

    *set_info_ifs* 是 `parsecfg.sh` 脚本里面的函数，用于设置分隔符。

    所给的第一个参数指定新的分隔符。

    默认分隔符是 *|*。如果需要解析的配置文件用的是其他分隔符，就需要先设置分隔符，再解析配置文件。

    如果使用默认的分隔符，可以跳过这个步骤。

- `open_config_file filename`

    *open_config_file* 是 `parsecfg.sh` 脚本里面的函数，用于解析配置文件。

    所给的第一个参数指定配置文件名。

- （可选的）`handle_config_option -l|-v|-i|-e|-a|-d`

    *handle_config_option* 是 `parsecfg.sh` 脚本里面的函数，用于处理选项参数。

    ‘-l’ 选项打印配置文件本身的内容。

    ‘-v’ 选项以键值对的形式打印所有配置项的值。

    ‘-i’ 选项后面要跟着一个参数，查询该参数值在配置文件中的具体内容。

    ‘-e’ 选项使用 vim 打开配置文件，以便手动编辑。

    ‘-a’ 选项后面跟着一个参数，把指定的键值对添加到配置文件末尾。

    ‘-d’ 选项后面跟着一个参数，从配置文件中删除该参数所在的行。

    如果没有需要处理的选项，可以跳过这个步骤。

- 解析配置文件后，就可以调用 `parsecfg.sh` 脚本提供的功能函数来进行一些操作。

    *get_key_of_entry* 函数从 “key|value” 形式的键值对中获取到 *key* 这个键名。

    *get_value_of_entry* 函数从 “key|value” 形式的键值对中获取到 *value”* 这个键值。

    *get_value_by_key* 函数在配置文件中基于所给键名获取到对应的键值。

    *search_value_from_file* 函数在配置文件中查找所给的内容，打印出匹配的行。

    *delete_key_value* 函数从配置文件中删除所给键名对应的行。

    *append_key_value* 函数把所给的键值对添加到配置文件的末尾。

# `parsecfg.sh` 脚本代码
列出 `parsecfg.sh` 脚本的具体代码如下所示。

在这个代码中，几乎每一行代码都提供了详细的注释，方便阅读。

这篇文章的后面也会提供一个参考的调用例子，有助理解。
```bash
#!/bin/bash
# 这个脚本提供函数接口来解析、处理键值对格式的配置文件.
# 默认的配置格式为: key|value. 该脚本提供如下功能:
# 1.根据所提供的 key 获取到对应的 value.
# 2.查看配置文件的内容.
# 3.使用 vim 打开配置文件,以供编辑.
# 4.提供函数来插入一个键值对到配置文件中.
# 5.提供函数从配置文件中删除所给 key 对应的键值对.
# 上面的 | 是键名和键值之间的分隔符.脚本提供set_info_ifs()函数来设置新的值.

# 下面变量保存传入的配置文件名.
PARSECFG_filepath=""

# 定义配置文件中键名和键值的分隔符. 默认分隔符是 '|'.
# 可以调用 set_info_ifs() 函数来修改分隔符的值,指定新的分隔符.
info_ifs="|"

######## 下面函数是当前脚本实现的功能函数 ########

# 从传入的项中提取出键名,并把键名写到标准输出,以供调用者读取.
# 下面echo的内容要用双引号括起来.双引号可以避免进行路径名扩展等.
# 当所echo的内容带有 '*' 时,不加双引号的话, '*' 可能会进行路径
# 名扩展,导致输出结果发生变化. 后面的几个函数也要参照这个处理.
get_key_of_entry()
{
    local entry="$1"
    # ${param%%pattern} 表达式删除匹配的后缀,返回前面剩余的部分.
    echo "${entry%%${info_ifs}*}"
}

# 从传入的项中提取出键值,并把键值写到标准输出,以供调用者读取.
get_value_of_entry()
{
    local entry="$1"
    # ${param#pattern} 表达式删除匹配的前缀,返回后面剩余的部分.
    echo "${entry#*${info_ifs}}"
}

# 该函数根据传入的键名从 key_values 关联数组中获取对应键值.
# 如果匹配,将键值写到标准输出,调用者可以读取该标准输出来获取键值.
# 该函数把查询到的键值写入到标准输出的键值. 如果没有匹配所提供
# 键名的键值,输出会是空. 调用者需要检查该函数的输出是否为空.
get_value_by_key()
{
    # 所给的第一个参数是要查询的键名.
    local key="$1"
    # 使用键名从键值对数组中获取到键值,并输出该键值.
    echo "${key_values["${key}"]}"
}

# 根据传入的键名删除配置文件中对应该键名的行.
delete_entry_by_key()
{
    # 所给的第一个参数是要删除的键名,会删除对应的键值对.
    local key="$1"
    # 这里要在${key}的前面加上^,要求${key}必须在行首.
    sed -i "/^${key}|/d" "${PARSECFG_filepath}"
    # 将关联数组中被删除键名对应的键值设成空.
    # key_values["${key}"]=""
    # 将键值设成空,这个键名还是存在于数组中.可以用 unset name[subscript]
    # 命令移除指定下标的数组元素.移除之后,这个数组元素在数组中已经不存在.
    # 注意用双引号把整个数组元素括起来. unset 命令后面的参数会进行路径名
    # 扩展.例如提供key_values[s]参数,如果当前目录下有一个key_valuess文件,
    # 那么key_values[s]会对应 key_valuess,而不是对应数组下标为s的数组元素.
    # 为了避免这个问题,使用双引号把整个数组元素括起来,不进行路径名扩展.
    unset "key_values[${key}]"
}

# 根据传入的键名,删除它在配置文件中对应的行
delete_key_value()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME key_name"
        return 1
    fi
    local key="$1"

    # 如果所给的键名在配置文件中已经存在,get_value_by_key()函数输出
    # 的内容不为空. 判断该函数的输出内容,不为空时才进行删除.
    local value=$(get_value_by_key "${key}")
    if test -n "${value}"; then
        delete_entry_by_key "${key}"
    else
        echo "出错: 找不到路径简写 '${key}' 对应的行"
    fi
}

# 该函数先从传入的键值对中解析出键名,然后执行get_value_by_key()
# 函数来判断该键名是否已经在配置文件中,如果在,就删除该键名对应的行.
# 最终,新传入的键值对会被追加到配置文件的末尾.
append_key_value()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME key_value"
        return 1
    fi
    # 所给的第一个参数是完整的键值对.
    local full_entry="$1"

    # 从传入的键值对中解析出键名
    local key_name=$(get_key_of_entry "${full_entry}")
    # 从配置文件中获取该键名对应的值.如果能够获取到值,表示该键名已经存在
    # 于配置文件中,会先删除这个键值对,再追加新传入的键值对到配置文件末尾.
    local match_value=$(get_value_by_key "${key_name}")
    if test -n "${match_value}"; then
        echo "更新 ${key_name}${info_ifs}${match_value} 为: ${full_entry}"
        delete_entry_by_key "${key_name}"
    fi

    # 追加新的键值对到配置文件末尾
    echo "${full_entry}" >> "${PARSECFG_filepath}"
    # 将新项的键名和键值添加到 key_values 数组中,以便实时反应这个修改.
    key_values["${key_name}"]="$(get_value_of_entry "${full_entry}")"
}

# 使用 cat 命令将配置文件的内容打印到标准输出上.
show_config_file()
{
    echo "所传入配置文件的内容为:"
    cat "${PARSECFG_filepath}"
}

# 打印从配置文件中解析得到的键值对.
show_key_values()
{
    local key_name
    # ${!array[@]} 对应关联数组的所有键. ${array[@]}对应关联数组的所有值.
    # 下面先获取关联数组的键,再通过键名来获取键值,并把键名和键值都打印出来.
    for key_name in "${!key_values[@]}"; do
        printf "key='\e[32m${key_name}\e[0m' \t"
        printf "value='\e[33m${key_values["${key_name}"]}\e[0m'\n"
    done
}

# 使用 vim 打开配置文件,以供编辑. 注意: 使用vim编辑文件后,文件所发生的改动不能
# 实时在脚本中反应出来,需要再次执行脚本,重新读取配置文件才能获取到所作的修改.
# 为了避免这个问题,在退出编辑后,主动调用open_config_file函数,重新解析配置文件.
edit_config_file()
{
    vim "${PARSECFG_filepath}"
    # 调用 open_config_file() 函数解析配置文件,重新为 key_values 赋值.
    open_config_file "${PARSECFG_filepath}"
}

# 在配置文件中查找指定的内容,看该内容是否在配置文件中.
search_value_from_file()
{
    # 如果查找到匹配的内容,grep命令会打印匹配的内容输出,以便查看.
    grep "$1" "${PARSECFG_filepath}"
    if [ $? -ne 0 ]; then
        echo "配置文件中不包含所给的 '$1'"
        return 1
    fi
}

######## 下面函数是初始化时需要调用的函数 ########

# 该函数用于设置配置文件中键名和键值的分隔符.
# 所给的第一个参数会指定新的分隔符,并覆盖之前设置的分隔符.
set_info_ifs()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME separator"
        return 1
    fi

    if [ -n "${PARSECFG_filepath}" ]; then
        # 如果配置文件名不为空,说明之前已经解析过配置文件.
        # 那么之前解析文件没有使用新的分隔符,报错返回.需要
        # 调用者修改代码,先调用当前函数,再调用open_config_file()
        # 函数,以便使用新指定的分隔符来解析配置文件的内容.
        echo "出错: 设置分隔符要先调用 set_info_ifs,再调用 open_config_file."
        return 2
    fi

    info_ifs="$1"
}

# 读取配置文件,并将配置文件的内容保存到关联数组中. 每次解析配置文件
# 之前,都要先调用该函数.后续直接通过关联数组来获取对应的值,不再多次
# 打开文件. 该函数接收一个参数,指定要解析的配置文件路径名.
open_config_file()
{
    if [ $# -ne 1 ]; then
        echo "Usage: $FUNCNAME config_filename"
        return 1
    fi

    # 判断所给的配置文件是否存在,且是否是文本文件.
    if [ ! -f "${1}" ]; then
        echo "ERROR: the file '${1}' does not exist"
        return 2
    fi
    # 存在配置文件,则把文件路径名保存到 PARSECFG_filepath 变量.
    # 使用 readlink -f 命令获取文件的绝对路径,包括文件名自身.
    # 一般来说,所给的文件名是相对路径.后续 cd 到其他目录后,用
    # 所给的相对路径会找不到这个文件, -l 选项无法查看文件内容.
    PARSECFG_filepath="$(readlink -f $1)"
    # 定义一个关联数组,保存配置文件中的键值对. 要先重置key_values的定义,
    # 避免通过 source 命令调用该脚本时, key_values 所保存的值没有被清空,
    # 造成混乱. 在函数内使用 declare 声明变量,默认是局部变量,跟 local
    # 命令类似. 使用 declare -g 可以在函数内声明变量为全局变量.
    unset key_values
    declare -g -A key_values

    local key value entryline

    # 逐行读取配置文件,并从每一行中解析出键名和键值,保存到关联数组
    # key_values中.后续直接通过键名来获取键值.如果键名不存在,键值为空.
    while read entryline; do
        # 由于配置文件的键值中可能带有空格,下面的${entryline}要用双引号
        # 括起来,避免带有空格时,本想传入一个参数,却被分割成了多个参数.
        # 例如${entryline}是service list,在不加引号时,get_value_of_entry()
        # 函数会接收到两个参数,第一个参数是$1,对应service,第二个参数是$2,
        # 对应list,而get_value_of_entry()函数只获取了第一个参数的值,这样就
        # 会处理出错.在传递变量值给函数时,变量值一定要用双引号括起来.
        key=$(get_key_of_entry "${entryline}")
        value=$(get_value_of_entry "${entryline}")
        # 经过验证,当 key_values[] 后面跟着等号'='时,所给的[]不会进行
        # 路径名扩展,不需要像上面用 unset 命令移除数组元素那样用双引号
        # 把整个数组元素括起来以避免路径名扩展.
        key_values["${key}"]="${value}"
        # 下面是预留的调试语句.在调试的时候,可以打开下面的注释.
        # echo "entryline=${entryline}"
        # echo "key=${key}"
        # echo "value=${value}"
    done < "${PARSECFG_filepath}"
    # 查看关联数组 key_values 的值.调试的时候,可以打开下面的注释.
    # declare -p key_values
}

# 操作配置文件的功能选项.建议外部调用者通过功能选项来指定要进行的操作.
# 该函数最多接收两个参数:
#   第一个参数: 提供选项名,该选项名要求以'-'开头,才是合法选项.
#   第二个参数: 提供选项的参数. 部分选项后面需要跟着一个参数.
# 当传入的选项被handle_config_option()函数处理时,该函数返回处理后的状态码.
# 例如,处理成功返回0,失败返回非0. 当传入的选项不被该函数处理时,它返回127.
handle_config_option()
{
    if [ -z "${PARSECFG_filepath}" ]; then
        # 如果配置文件变量值为空,说明还没有解析配置文件,不能往下处理.
        echo "出错: 请先调用 open_config_file filename 来解析配置文件."
        return 1
    fi
    local option="$1"
    local argument="$2"

    case "${option}" in
        -l) show_config_file ;;
        -v) show_key_values ;;
        -i) search_value_from_file "${argument}" ;;
        -e) edit_config_file ;;
        -a) append_key_value "${argument}" ;;
        -d) delete_key_value "${argument}" ;;
         *) return 127 ;;
    esac

    # 当return语句不加上具体状态码时,它会返回上一条执行命令的状态码.
    return
}
```

# 使用 `parsecfg.sh` 脚本的例子
假设有一个 `testparsecfg.sh` 脚本，具体的代码内容如下：
```bash
#!/bin/bash

CFG_FILE="cfgfile.txt"

# 通过 source 命令加载 parsecfg.sh 的脚本代码
source parsecfg.sh

# 调用 open_config_file 函数解析配置文件
open_config_file "$CFG_FILE"

# 调用 handle_config_option 函数处理 -v 选项.
# 该选项以键值对的形式列出所有配置项.
handle_config_option -v

# 获取 am 这个键名对应的键值
value=$(get_value_by_key "am")
echo "The value of 'am' key is: $value"

# 使用 get_key_of_entry 函数从键值对中获取键名.该函数
# 针对键值对自身进行处理,所给的键值对可以不在配置文件中.
key=$(get_key_of_entry "a|adb logcat -b all")
echo "The key of 'a|adb logcat -b' is: $key"
```
这个脚本所调用的函数都来自于 `parsecfg.sh` 脚本。

这个 `testparsecfg.sh` 脚本指定解析一个 *cfgfile.txt* 配置文件。

该配置文件的内容如下：
```
am|frameworks/base/services/core/java/com/android/server/am/
w|frameworks/base/wifi/java/android/net/wifi/
```

把 `parsecfg.sh` 脚本、`testparsecfg.sh` 脚本、和 *cfgfile.txt* 配置文件都放到同一个目录下。

然后给这两个脚本文件都添加可执行权限。

执行 `testparsecfg.sh` 脚本，具体结果如下：
```
$ ./testparsecfg.sh
key='am'        value='frameworks/base/services/core/java/com/android/server/am/'
key='w'         value='frameworks/base/wifi/java/android/net/wifi/'
The value of 'am' key is: frameworks/base/services/core/java/com/android/server/am/
The key of 'a|adb logcat -b' is: a
```

可以看到，在 `testparsecfg.sh` 脚本中通过 `source` 命令引入 `parsecfg.sh` 脚本.

之后可以调用 `parsecfg.sh` 脚本里面的代码来解析配置文件，非常方便。

如果多个脚本需要解析多个不同的配置文件，可以在各自脚本中引入 `parsecfg.sh` 脚本，然后提供不同的配置文件名即可。
