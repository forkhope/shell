# 记录 Linux 处理路径名、文件名的相关笔记

# 使用 dirname 命令获取路径名的目录部分
在 Linux 中，可以使用 `dirname` 命令获取路径名的目录部分，不包含路径名最后的文件名。

查看 man dirname 的说明如下：
> **dirname [OPTION] NAME...**  
> dirname - strip last component from file name.
> Output each NAME with its last non-slash component and trailing slashes removed;
> if NAME contains no /'s, output '.' (meaning the current directory).

即，`dirname` 命令可以获取所给路径名的目录部分，也就是从最后一个 `/` 字符往前的部分，不包括 `/` 字符自身。

如果所给的路径名没有包含 `/` 字符，返回的目录部分是点号 ‘.’，认为是当前目录。

所给的路径名参数不要求是真实存在的路径，`dirname` 只是对所给的路径名字符串进行处理。

`dirname` 命令可以提供多个路径名参数，默认会逐行打印每个路径名的目录部分。

如果不想换行打印，可以使用 `-z` 选项，该选项的说明如下：
> **-z, --zero**  
separate output with NUL rather than newline

具体举例如下：
```bash
$ dirname app/Phone.apk src/lib/utils.c
app
src/lib
$ dirname utils.c
.
$ dirname -z app/Phone.apk src/lib/utils.c
app src/lib $
```
可以看到，`dirname app/Phone.apk src/lib/utils.c` 命令逐行打印了所给两个路径名的目录部分。

`dirname utils.c` 命令的路径名参数没有包含 `/` 字符，打印的目录部分是点号 ‘.’。

`dirname -z app/Phone.apk src/lib/utils.c` 使用 `-z` 选项指定在获取到的目录部分后面不要加换行符，那么打印结果都在同一行上，没有换行。  
打印结果最后的 `$` 字符是命令行提示符。

# 使用 basename 命令获取路径名的文件名部分
在 Linux 中，可以使用 `basename` 命令获取路径名的文件名部分，不包含文件名前面的目录路径。

查看 man basename 的说明如下：
> **basename NAME [SUFFIX]**  
> **basename OPTION... NAME...**  
> basename - strip directory and suffix from filenames.
> Print NAME with any leading directory components removed.
>If specified, also remove a trailing SUFFIX.

即，`basename` 命令可以获取所给路径名的文件名部分，也就是从最后一个 `/` 字符往后的部分，不包括 `/` 字符自身。

当只提供一个路径名参数时，后面可以提供一个可选的 *SUFFIX* 参数，该参数指定去掉文件名的后缀部分。

`basename` 默认只处理一个路径名参数。

如果想要处理多个路径名参数，需要使用 `-a` 选项，该选项的说明如下：
> **-a, --multiple**  
support multiple arguments and treat each as a NAME

当使用 `-a` 选项指定提供多个路径名参数时，`basename` 会逐行打印每个路径名的文件名部分。

如果不想换行打印，可以再使用 `-z` 选项，该选项的说明如下：
> **-z, --zero**  
separate output with NUL rather than newline

当提供多个路径名参数时，如果想指定去掉文件名的后缀部分，需要用 `-s` 选项，该选项的说明如下：
> **-s, --suffix=SUFFIX**  
remove a trailing SUFFIX

具体举例说明如下：
```bash
$ basename src/lib/utils.c
utils.c
$ basename src/lib/utils.c .c
utils
$ basename -s .c src/lib/utils.c
utils
$ basename -a src/lib/utils.c src/main.c
utils.c
main.c
$ basename -a -s .c src/lib/utils.c src/main.c
utils
main
$ basename -a -z src/lib/utils.c src/main.c
utils.c main.c $
```
可以看到，`basename src/lib/utils.c` 命令获取到所给路径名的文件名部分，也就是 *utils.c*。

`basename src/lib/utils.c .c` 命令指定从获取到的文件名中去掉 *.c* 后缀，返回 *utils*。

而 `basename -s .c src/lib/utils.c` 命令通过 `-s .c `指定从获取到的文件名中去掉 *.c* 后缀，要在 `-s` 选项后面提供去掉的文件名后缀部分。

`basename -a src/lib/utils.c src/main.c` 命令使用 `-a` 选项指定处理多个路径名，可以避免后面的文件名被当成 *SUFFIX* 参数，获取到的多个文件名会逐行打印。

`basename -a -s .c src/lib/utils.c src/main.c` 命令通过 `-a` 选项指定处理多个路径名，通过 `-s .c` 指定从获取到的文件名中去掉 *.c* 后缀。

`basename -a -z src/lib/utils.c src/main.c` 命令通过 `-a` 选项指定处理多个路径名，通过 `-z` 选项指定获取到的文件名部分后面不要加换行符，那么打印结果都在同一行上，没有换行。  
打印结果最后的 `$` 字符是命令行提示符。

# 使用 bash 的参数扩展获取文件名的后缀名
在 bash 中，可以使用参数扩展（parameter expansion）表达式来获取文件名的后缀名。

具体说明如下：
```bash
    ${filename##*.}
```
这个表达式在 *filename* 变量值中匹配 `.` 这个字符，一直到最后一次匹配为止，然后返回该字符后面的部分，也就是文件名的后缀名，不包含 `.` 这个字符。

**注意**：`${filename##*.}` 这个表达式是 bash 的参数扩展表达式，*filename* 会被当成变量名处理，获取该变量值以便进行参数扩展。  
它不能直接处理字符串，*filename* 不会被当成字符串处理，必须把字符串赋值给变量，然后把变量名放到该表达式中进行处理。

具体举例如下：
```bash
$ echo ${src/lib/utils.c##*.}

$ filename="src/lib/utils.c"
$ echo ${filename##*.}
c
$ filename="utils.c"
$ echo ${filename##*.}
c
$ filename="utils.1.c"
$ echo ${filename##*.}
c
$ echo '.'${filename##*.}
.c
$ filename="util"
$ echo ${filename##*.}
util
```
可以看到，`echo ${src/lib/utils.c##*.}` 命令输出为空。  
这里没有把 `src/lib/utils.c` 当成要处理的字符串，而是当成变量名。  
当前没有这个变量，变量值为空，匹配结果也为空。

当把 "src/lib/utils.c" 赋值给 *filename* 变量后，`echo ${filename##*.}` 命令打印出 *filename* 变量值对应字符串的后缀名，也就是 *c*，没有包含 `.` 这个字符。

修改 *filename* 变量值为 "utils.c"，`echo ${filename##*.}` 命令也打印了对应的后缀名。

把 *filename* 变量赋值为 "utils.1.c"，包含多个 `.` 字符，`${filename##*.}` 表达式会一直匹配到最后一个 `.` 字符，并返回该字符后面的部分。

由于这个表达式获取的后缀名不包含 `.` 字符，如果需要加上 `.` 字符，可以在表达式前面主动加上这个字符。

例如，`'.'${filename##*.}` 这个写法会在表达式返回值前面加上 `.` 字符。

要注意的是，当所给变量值中没有包含 `.` 字符时，这个表达式会返回变量值自身。修改 *filename* 变量值为 "util"，`echo ${filename##*.}` 命令打印了这个变量值自身。

当 `${filename##*.}` 返回的值等于 `$filename` 的值时，说明 *filename* 变量值不包含 `.` 字符，也就是不带有后缀名。
