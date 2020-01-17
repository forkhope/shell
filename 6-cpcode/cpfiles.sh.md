# 介绍一个批量复制文件到指定目录的 shell 脚本

本篇文章介绍一个可以批量复制文件到指定目录的 shell 脚本。  
假设这个 shell 脚本的名称为 `cpfiles.sh`。

在实际开发工作中，可能需要按照目录结构来保存一些改动后的文件，以作备份。  
这些目录结构可能包含多个子目录、或者需要复制多个文件。  
如果直接复制外面的目录，会包含没有发生改动的文件。  
如果手动创建各个子目录，再来复制多个文件，比较麻烦。

当前脚本预期把要复制的文件路径保存到一个配置文件里面。  
然后解析所给的配置文件，自动创建对应的子目录，复制文件到指定目录下。  
当配置了多个文件路径时，就可以批量复制文件。

同时，当前脚本进行了扩展，可以处理 Android 系统的 repo status 命令打印的修改文件信息。  
执行 repo status 查看 Android 源码仓库的改动时，打印的文件信息格式如下：
```
project frameworks/base/
-m services/core/java/com/android/server/ServiceThread.java
project packages/apps/Music/
-m src/com/android/music/MusicPicker.java
```
在每个 project 后面，会跟着某个代码仓库相对于 Android 源码根目录的路径。  
接下来的行对应该仓库下面的文件路径，这个文件路径相对于代码仓库的根目录。

例如，上面的 ServiceThread.java 文件在 Android 源码根目录中的完整路径是 “frameworks/base/services/core/java/com/android/server/ServiceThread.java”

当需要备份 Android 源码多个仓库下发生改动的文件时，可以使用 repo status 列出修改文件信息。  
把这些文件信息保存到一个文件里面，当前脚本可以解析这些文件信息，批量复制所列出的文件到指定目录下。

在其他使用 git 管理代码的项目上，git log --name-status 打印的修改文件信息跟 repo status 的信息类似。  
只是缺少了 “project project_path” 这一行，手动补上这一行，就可以使用当前脚本复制 git 仓库下面的文件。

# 脚本代码
列出 `cpfiles.sh` 脚本的具体代码如下所示。  
在这个代码中，对大部分关键代码都提供了详细的注释，方便阅读。  
这篇文章的后面也会提供一个参考的调用例子，有助理解。

```bash
#!/bin/bash
# 在Android源码中,执行repo status命令可以查看修改的文件信息.格式为:
#   project frameworks/base/
#   -m services/core/java/com/android/server/ServiceThread.java
#   project packages/apps/Music/
#   -m src/com/android/music/MusicPicker.java
# 在这些信息中,每一个 project 段对应一个代码仓库路径.当需要复制多个
# 仓库的指定代码文件时,手动复制比较麻烦. 当前脚本用于处理这种格式的
# 配置信息,组装得到完整的文件路径,并复制后指定的目标目录下.
# 同时,该脚本也做了扩展,可以提供要复制的完整文件路径,使不局限于复制
# Android 源码目录下的代码文件,可以复制任意目录下的文件.
# 下面设置set -e,一旦报错就停止执行.例如复制某个文件出错就不再复制.
set -e

show_help()
{
printf "USAGE
    cpfiles.sh [source_fileinfos [target_dir]]
OPTIONS
    该脚本最多可以提供两个参数. 这两个参数是可选的.
    source_fileinfos: 指定保存源文件路径信息的配置文件名.
        如果没有提供该参数,默认解析的文件名是 'copy-files.txt'.
    target_dir: 指定要把源文件复制到哪个目录下.
        如果没有提供该参数,默认会复制到当前目录下的 '0-复制后' 目录.
        如果目标目录不存在,会自动新建对应的目录.
        这个参数必须是第二个参数.当提供该参数时,也要提供第一个参数.
NOTE
    配置源文件路径信息的参考格式如下:
        project base_top_dir1/
        -m     file_sub_path1
        project
        full_file_path2
    一般来说,每个 project 开头的段对应不同目录下的文件. 在project后面
    可以跟着一个目录路径,该段的源文件路径会自动加上这个目录路径.例如,
    在上面例子中,要复制的完整文件路径是 base_top_dir1/file_sub_path1
    如果project后面没有目录路径,则该段的文件路径就是要复制的完整路径.
"
}

# 下面变量指定配置源文件路径信息的文件名.解析该文件得到要复制的文件路径.
SRC_FILEINFO="copy-files.txt"
# 这个脚本的第一个参数用于指定配置源文件路径信息的文件名.
# 如果没有提供第一个参数,则使用默认的配置文件名.
if [ $# -gt 0 ]; then
    SRC_FILEINFO="$1"
fi

# 下面变量指定源文件被复制到的目标目录名,会在当前工作目录下新建该目录.
COPY_TARGET_TOP_DIR="0-复制后"
# 这个脚本的第二个参数用于指定源文件被复制到的目标目录名.
# 如果没有提供第二个参数,则使用默认的目标目录名.
if [ $# -eq 2 ]; then
    COPY_TARGET_TOP_DIR="$2"
fi

if [ $# -gt 2 ]; then
    echo "出错: 该脚本最多只能提供两个参数."
    show_help
    exit 1
fi

# 检查当前工作目录下是否存在一个指定的配置文件. 如果不存在,则报错返回.
if [ ! -f "${SRC_FILEINFO}" ]; then
    echo "出错: 在当前目录下不存在要解析的 ${SRC_FILEINFO} 文件."
    show_help
    exit 2
fi

# 从 SRC_FILEINFO 配置文件解析出完整的源文件路径信息后,把这些信息写入到
# FULL_FILEPATH 对应的文件里面.基于FULL_FILEPATH文件保存的文件路径进行复制.
FULL_FILEPATH="full_filepaths.txt"

# 从所给文件中解析要复制的源文件路径信息.第一个参数指定被解析的文件名.
# 解析得到的完整源文件路径信息会写入 FULL_FILEPATH 变量指定的文件里面.
# 所给配置文件里面配置了要复制的源文件路径信息. 具体格式如下:
#   project base_top_dir1/
#   foo     file_sub_path1
#   project
#   full_file_path2
# 配置内容可以分为多段. 每段以project开头. 每段里面可以配置多个源文件路径.
# 如果在project后面跟着一个目录路径,则该段的文件路径前面会自动加上这个目录
# 路径.例如在上面格式中,实际要复制的文件路径是 base_top_dir1/file_sub_path1.
# 此时,该段的文件路径前面要有一个 foo 占位字符串,具体内容不限,但一定要有.
# 这个格式是为了符合 Android 的 repo status 命令打印的文件信息.
# 如果project后面没有提供目录路径,表示该段的文件路径就是完整的目录路径.如果
# 所给的文件路径是相对路径,需要确保执行时的工作目录可以寻址到这个相对路径.
parse_file_infos()
{
    if [ $# -ne 1 ]; then
        echo "Usage: ${FUNCNAME} filename"
        return 1
    fi
    # 所给的第一个参数指定要解析的配置文件名.
    local parsefile="${1}"
    # 下面变量对应每段开始的 project 字符串.
    local IDENTIFY_PROJECT="project"
    local fileline lastchar
    local header project_dir sub_file_path full_file_path

    # 如果文件的最后一行没有以换行符'\n'结尾, read 命令在读取最后一行
    # 时会返回false,从而退出下面的 while 循环,导致最后一行没有被处理,
    # 会少复制一个文件.下面使用 tail 命令获取文件的最后一个字符.由于
    # $() 表达式会去掉输出结果末尾的换行符,如果文件的最后一个字符是换
    # 行符,经过 "$()" 扩展后会变成空.可以通过判断扩展后的结果是否为空
    # 来确认文件是否以换行符结尾.如果不以换行符结尾,则使用 echo 命令
    # 给文件末尾追加一个换行符. test -n 命令判断字符串不为空时返回true.
    if test -n "$(tail "${parsefile}" -c 1)"; then
        echo >> "${parsefile}"
    fi

    # /dev/null 是一个空文件,输出这个文件的内容为空.重定向到
    # FULL_FILEPATH 文件,清空该文件的内容,避免原有内容的影响.
    cat /dev/null > "${FULL_FILEPATH}"

    while read fileline; do
        header="$(echo ${fileline} | awk '{print $1}')"
        if [ "${header}" == "${IDENTIFY_PROJECT}" ]; then
            project_dir="$(echo ${fileline} | awk '{print $2}')"
            # project_dir 被作为目录路径使用,要求最后一个
            # 字符必须是'/',以便组装成目录路径.如果没有
            # 以 '/' 结尾,则在该变量值后面加上 '/' 字符.
            if [ -n "${project_dir}" ]; then
                lastchar="${project_dir: -1:1}"
                if [ "${lastchar}" != "/" ]; then
                    project_dir="${project_dir}/"
                fi
            fi
        elif [ -n "${fileline}" ]; then
            # 当文件中有空行时, fileline 的内容是空字符串. 后面组装
            # sub_file_path的值会有异常,所以上面用-n判断不为空才处理.
            #
            # 如果当前行没有以 project 开头,那么对应要复制的文件路径.
            # 当 project_dir 不为空时,表示当前解析的段配置了目录路径,
            # 那么源文件路径前面会有一个占位字符串,所以要获取空格隔开
            # 的第二列内容才是文件路径. 如果 project_dir 为空,则这一
            # 行就是完整的源文件路径.
            if [ -n "${project_dir}" ]; then
                sub_file_path="$(echo ${fileline} | awk '{print $2}')"
            else
                sub_file_path="${fileline}"
            fi
            full_file_path="${project_dir}${sub_file_path}"
            echo "${full_file_path}" >> "${FULL_FILEPATH}"
        fi
    done < "${parsefile}"

    # 由于有些文件可能被配置多次,下面对生成的内容进行排序,并删除重复行.
    # sort 命令的 -u 选项表示删除重复行. -o 选项后面提供文件名来指定排序
    # 后的内容要写入哪个文件. 如果没有提供 -o 选项,默认写到标准输出,不会
    # 直接修改所给文件自身.这里指定排序后的内容输出到同一个文件,覆盖文件.
    sort -u "${FULL_FILEPATH}" -o "${FULL_FILEPATH}"
}

# 该函数解析所给的文件,从中得到要复制的源文件路径,复制
# 指定文件到目标目录下. 所给的第一个参数指定要解析的文件名.
# 所给文件的每一行都对应一个要复制的完整文件路径.
copy_src_files()
{
    if [ $# -ne 1 ]; then
        echo "Usage: ${FUNCNAME} filepaths"
        return 1
    fi
    # 所给的第一个参数指定保存了源文件完整路径信息的文件名
    local copyfiles="$1"
    local source_file_path

    # 先创建目标目录.这个目录必须先创建, cp 命令才能复制文件过来. 当要
    # 创建的目录已经存在时, mkdir 命令默认会报错.使用 -p 选项使不报错.
    mkdir -pv "${COPY_TARGET_TOP_DIR}"

    while read source_file_path; do
        # cp 命令的 --parents 选项会在目标目录下自动创建源文件路径包含
        # 的子目录.不需要先在目标目录下创建各个子目录再复制.
        # cp --parents -v 命令会打印创建中间子目录的信息,导致打印的
        # 信息比较多.先不加 -v 选项.使用 -u 选项指定只复制较新的文件.
        cp --parents -u "${source_file_path}" "${COPY_TARGET_TOP_DIR}"
    done < "$copyfiles"
}

# 把Windows系统的dos格式文件转换成unix格式. Dos格式文件的行末是\r\n,
# 而unix格式文件的行末是\n,且把\r视作有效字符.如果不做转换,那么提供
# 一个dos格式的文件,最后得到的文件路径会包含\r字符,且被当做文件名的
# 一部分.用cp命令复制时,会提示找不到这样的文件.在使用 file 命令查看
# dos 格式文件时,打印的信息包含 "CRLF line terminators" 字符串.查看
# 所给文件的信息是否包含该字符串,就可以判断这个文件是不是 dos 格式.
# 如果是 dos 格式文件,则执行 dos2unix 命令转换为 unix 格式文件.
if [[ "$(file SRC_FILEINFO)" =~ "CRLF line terminators" ]]; then
    # dos2unix 命令默认直接修改所给文件自身,覆盖成 unix 格式.
    dos2unix "${SRC_FILEINFO}"
fi

# 调用 parse_file_infos 函数解析所给文件内容,得到要复制的源文件路径.
# 解析得到的源文件路径保存在 FULL_FILEPATH 变量名指定的文件里面.
parse_file_infos "${SRC_FILEINFO}"
# 调用 copy_src_files 函数,基于源文件路径,复制源文件到目标目录下.
copy_src_files "${FULL_FILEPATH}"
echo "已复制全部文件到 '${COPY_TARGET_TOP_DIR}' 目录下."

# 把所给文件和生成的路径信息文件移动到目标目录下,以便记录文件来源.
cp -v "${SRC_FILEINFO}" "${COPY_TARGET_TOP_DIR}/"
mv -v "${FULL_FILEPATH}" "${COPY_TARGET_TOP_DIR}/"

exit
```

# 一个参考的测试例子
为了测试当前的 `cpfiles.sh` 脚本，可以先执行下面命令来创建一些目录和文件：
```bash
$ mkdir -p top/sub1/left1/left2
$ mkdir -p top/sub1/right1/
$ mkdir -p top/sub2/sub3
$ touch top/sub1/left1/left2/left_file.txt
$ touch top/sub1/right1/right_file.txt
$ touch top/sub2/sub3/sub_file.txt
```
这几个命令在当前工作目录下创建了一个 *top* 目录。  
在这个 *top* 目录底下还有一些子目录和文件。总共新建了三个文本文件。

下面会使用 `cpfiles.sh` 脚本来复制这三个文本文件，且保存在对应的目录结构里面。

基于上面创建的目录和文件，可以新建一个 *copy-files.txt* 文件，并在文件里面配置如下内容：
```
project top/sub1/
a   left1/left2/left_file.txt
a   right1/right_file.txt
project
top/sub2/sub3/sub_file.txt
```

在这个配置信息中，第一个 project 段后面跟着 *top/sub1/* 目录路径。  
那么该段下的文件路径会自动加上这个目录路径。  
例如，所配置的 *left1/left2/left_file.txt* 这个文件的完整复制路径会是 “top/sub1/left1/left2/left_file.txt”。

第二个 project 段后面提供目录路径。  
那么该段下的文件路径就是完整的目录路径。  
此时，需要确保可以基于当前工作目录寻址到所配置的文件。

把 `cpfiles.sh` 脚本和 *copy-files.txt* 文件放到当前目录下，为脚本添加可执行权限。  
具体执行结果如下：
```bash
$ ./cpfiles.sh
mkdir: created directory ‘0-复制后’
已复制全部文件到 '0-复制后' 目录下.
‘copy-files.txt’ -> ‘0-复制后/copy-files.txt’
‘full_filepaths.txt’ -> ‘0-复制后/full_filepaths.txt’
$ ls 0-复制后/
copy-files.txt  full_filepaths.txt  top
$ ls 0-复制后/top/
sub1  sub2
```

可以看到，执行 `cpfiles.sh` 脚本后，会在当前目录新建一个 “0-复制后” 目录。  
然后把所要复制的文件按照原先的目录结构复制到 “0-复制后” 目录下。  
同时，还会在 “0-复制后” 目录下生成所给的 *copy-files.txt* 文件、生成的 *full_filepaths.txt*。  
这两个文件记录了要复制的文件路径信息，以便后续进入该目录时，可以查看目录下的文件列表信息。

测试结束后，可以执行下面命令来删除所创建的测试目录和文件：
```bash
rm -r 0-复制后/ top/ copy-files.txt
```
