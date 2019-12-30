# 描述 grep 命令的使用

在 Linux 命令中，`grep` 命令是最常用的命令之一。下面基于实例介绍 `grep` 命令的常见用法。

# grep 命令格式
查看 man grep 对 `grep` 命令的说明如下：
- grep - print lines matching a pattern  
grep [OPTIONS] PATTERN [FILE...]  
grep [OPTIONS] [-e PATTERN | -f FILE] [FILE...]  
- grep searches the named input FILEs (or standard input if no files are named, or if a single hyphen-minus (-) is given as file name) for lines containing a match to the given PATTERN.
- By default, grep prints the matching lines.
- The exit status is 0 if selected lines are found, and 1 if not found. If an error occurred the exit status is 2.

即，`grep` 命令在所给文件中查找特定模式的字符串，可以提供多个文件名，在多个文件中查找。如果没有提供文件名，则读取标准输入。默认会打印出包含特定模式的整行内容，以便查看是哪一行包含了这个模式。

**注意**：跟在 `grep` 命令的 *PATTERN* 参数后面的参数会被认为是文件名，即使用引号把参数值括起来也还是当成文件名，不会当成字符串。刚接触 `grep` 命令的常见误区是，以为用双引号把参数值括起来就变成查找字符串，这是错误的用法。具体举例说明如下：
```bash
$ cat testfile
This is a test string.
$ grep "string" testfile
This is a test string.
$ grep "string" "testfile"
This is a test string.
$ grep "string" "This is a test string."
grep: This is a test string.: No such file or directory
```
可以看到，当前目录下有一个 *testfile* 文件，它里面只有一行 "This is a test string." 字符串。`grep "string" testfile` 命令会在 *testfile* 文件中查找 "string" 字符串，找到后打印出对应的行。

`grep "string" "testfile"` 命令也是在 *testfile* 文件中查找 "string" 字符串，即使用双引号把 testfile 括起来，也不代表是在 "testfile" 字符串中查找 "string" 字符串。而 `grep "string" "This is a test string."` 命令会执行报错，提示找不到名为 *This is a test string.* 的文件，它不是在 "This is a test string." 字符串中查找 "string" 字符串。

如果确实需要用 `grep` 命令来查找字符串，可以用管道操作符 `|` 来连接标准输入。例如用 `echo` 命令打印字符串的值，然后通过管道操作符把这个值传递到 `grep` 命令的标准输入。举例如下：
```bash
$ echo "This is a test string." | grep string
This is a test string.
$ value="This is a new test string."
$ echo "$value" | grep new
This is a new test string.
$ echo $?
0
```
可以看到，`echo "This is a test string." | grep string` 命令通过 `echo` 先输出字符串的值，再通过管道操作符 `|` 把这个输出连接到 `grep` 命令的标准输入，就能查找字符串，不会执行报错。

`echo "$value" | grep new` 命令在 *value* 变量值中查找 "new" 字符串，`grep` 命令在查找到匹配模式时，会返回 0，也就是 true。可以使用 `$?` 获取到命令返回值，检查这个返回值是否为 0，就能判断某个字符串是否为另一个字符串的子字符串。

**注意**：这里使用管道操作符 `|` 来连接标准输入，让 `grep` 命令能够查找字符串，但是使用重定向标准输入操作符 `<` 并不能让 `grep` 命令查找字符串。重定向是基于文件的操作，所给的字符串会被当成文件名，举例如下：
```bash
$ grep "string" < "This is a test string."
-bash: This is a test string.: No such file or directory
```
可以看到，在重定向标准输入操作符 `<` 右边的 "This is a test string." 字符串被当成文件名，bash 提示找不到文件。这里不是 `grep` 命令报错，而是 bash 在处理重定向的时候报错。

# 查找多个文件
在 `grep` 的命令格式中，默认是一个匹配模式对应多个文件，而不是多个匹配模式对应一个文件。在 *PATTERN* 参数后面的所有参数都会认为是文件名，可以提供多个文件名，在这些文件中统一查找同一个匹配模式。举例说明如下：
```bash
$ grep test testfile retestfile
testfile:This is a test string.
retestfile:retestfile
```
在上面的 `grep test testfile retestfile` 命令中，*test* 是 *PATTERN* 参数，指定匹配模式，*testfile* 和 *retestfile* 都是要查找的文件名，并不是在 *retestfile* 文件中查找 *test* 模式和 *testfile* 模式。

在 `grep` 命令中使用 bash 的星号 `*` 通配符时，可能就会扩展成查找多个文件的情况：
```bash
$ set -x
$ grep *test* testfile
+ grep --color=auto retestfile testfile testfile
$ grep test *test*
+ grep --color=auto test retestfile testfile
retestfile:retestfile
testfile:This is a test string.
$ set +x
```
刚接触 `grep` 命令和 bash 的星号 `*` 通配符时，常见的误区是认为 `grep *test* testfile` 命令会在 *testfile* 文件查找任意包含 *test* 的字符串。但是上面的打印结果为空。打开 bash 调试信息，可以看到该命令扩展为 `grep --color=auto retestfile testfile testfile`，基于 `grep` 的命令格式，其实是在 *testfile* 文件中查找 "retestfile" 字符串，而且会查找两次，因为提供了两次 *testfile* 文件名。

Bash 的 `*` 通配符没有被引号括起来时，其扩展结果来自于当前目录下的文件名，如果多个文件名符合所给模式，就会把多个文件名作为参数传递给被执行命令，导致被执行命令的参数个数发生变化，要注意这个扩展结果是否符合预期。

可以看到，`grep test *test*` 命令的扩展结果是 `grep --color=auto test retestfile testfile`，在 *retestfile*、*testfile* 这两个文件中查找 "test" 字符串。

即，认识到 `grep` 命令是一个匹配模式对应多个文件，有助于理解在命令参数中使用 bash 的 `*` 通配符、或者其他通配符时的执行结果。

如果要查找多个匹配模式，要通过其他选项、或者正则表达式来指定。后面会具体说明。

# 匹配模式为空字符串时会匹配所有行
当 `grep` 命令的 *PATTERN* 参数为空字符串时，会匹配所给文件的所有行。举例说明如下：
```bash
$ cat testfile
This is a test string.
$ grep "" testfile
This is a test string.
$ grep '' testfile
This is a test string.
```
可以看到，`grep "" testfile` 命令和 `grep '' testfile` 命令都匹配了 *testfile* 文件的所有行。

GNU grep 的在线帮助链接 <https://www.gnu.org/software/grep/manual/grep.html#Usage> 对此进行了说明：
> **11. Why does the empty pattern match every input line?**  
The grep command searches for lines that contain strings that match a pattern. Every line contains the empty string, so an empty pattern causes grep to find a match on each line. It is not the only such pattern: ‘^’, ‘$’, ‘.*’, and many other patterns cause grep to match every line.

> To match empty lines, use the pattern ‘^$’. To match blank lines, use the pattern ‘^[[:blank:]]*$’. 

即，`grep` 命令认为每一行都包含空字符串，所以提供的匹配模式为空字符串时，会匹配到所有行。匹配模式写为 `'^'`、`'$'`、`'.*'`，也是会匹配到所有行。

如果想要匹配空行，匹配模式可以写为 `'^$'`，空行只包含一个行末的换行符。如果想要匹配只包含空白字符（空格、或 tab 字符）的行，匹配模式可以写为 `^[[:blank:]]*$`。

# 颜色高亮匹配到的模式字符串
在 Linux 中，`grep` 命令默认不会颜色高亮匹配到的模式字符串。  
如果想要高亮所匹配的部分，需要加上 `--color=auto` 或者 `--color=always` 选项才会显示颜色高亮。

在一些 Linux 系统上，执行 `grep` 命令，没有手动加 `--color=auto` 也会看到颜色高亮。  
这是因为 bash 设置了 `alias` 别名，默认已经加上 `--color=auto` 选项。

具体举例说明如下：
```bash
$ alias grep
alias grep='grep --color=auto'
```
可以看到，bash 设置了 *grep* 字符串为 `grep --color=auto` 命令的别名。  
那么在 bash 中执行 `grep` 命令，实际执行的是 `grep --color=auto`，所以能够颜色高亮。

可以使用 `\grep` 来指定不使用 `alias` 别名，执行原始的 `grep` 命令，就能看到没有颜色高亮。

具体举例说明如下：
> $ grep "string" testfile  
This is a test <span style="color:red;">string.</span>  
$ \grep "string" testfile  
This is a test string.  
$ \grep --color=auto "string" testfile  
This is a test <span style="color:red;">string.</span>

在这个测试结果中，只有 `\grep "string" testfile` 命令确实没有加 `--color=auto` 选项，打印的匹配结果没有颜色高亮。

查看 man grep 对 `--color` 选项、以及它的取值说明如下：
> **--color[=WHEN], --colour[=WHEN]**  
> Surround the matched (non-empty) strings, matching lines, context lines, file names, line numbers, byte offsets, and separators (for fields and groups of context lines) with escape sequences to display them in color on the terminal.  
> WHEN is never, always, or auto.

一般来说，当指定为 *always*、*auto* 时，可以显示颜色高亮。  
当指定为 *never* 时，不会显示颜色高亮。  
如果没有提供 `--color` 选项，默认值就是 *never*，不显示颜色高亮。

**注意**：在非交互式 shell 中，默认不能使用 alias 别名。  
由于 shell 脚本默认运行在非交互式 shell 下，当在 shell 脚本中使用 `grep` 命令时，不会自动在 `grep` 命令后面加上 `--color=auto` 选项，打印的匹配结果没有颜色高亮。

在 shell 脚本中执行 `grep` 命令时，如果想要打印的匹配结果显示颜色高亮，需要在 shell 脚本的 `grep` 命令后面主动加上 `--color=auto` 选项。

查看 man bash 里面对非交互式 shell 不能使用 alias 别名的说明如下：
> Aliases are not expanded when the shell is not interactive, unless the expand_aliases shell option is set using shopt.

# 使用 -r 选项指定查找所给目录、及其子目录的所有文件
在 `grep` 命令的 `-r` 选项后面可以提供一个目录名，指定在所给目录、及其子目录的所有文件中进行匹配。查看 man grep 对 `-r` 选项的说明如下：
> **-r, --recursive**  
Read all files under each directory, recursively, following symbolic links only if they are on the command line. This is equivalent to the -d recurse option.

即，`-r` 选项指定递归读取所给目录下的所有文件，默认不处理符号链接文件，除非在命令行参数中提供了符号链接的文件名。另外一个 `-R` 选项默认会处理符号链接文件，这里不讨论 `-R` 选项。

**注意**：`-r` 选项强调的是读取目录下的所有文件，不会匹配目录名本身，即使目录名符合指定模式也不会匹配。而 `grep` 命令默认可以匹配目录名本身。具体举例如下：
```bash
$ grep "string" *
grep: string: Is a directory
testfile:This is a test string.
$ grep "string" -r .
./testfile:This is a test string.
$ grep -d skip "string" *
testfile:This is a test string.
```
可以看到，`grep string *` 命令的打印结果里面，有一个 *string* 目录名匹配 "string" 字符串模式。而用 `grep "string" -r .` 命令查找当前目录下的所有文件，打印结果没有匹配到 *string* 这个目录名，加了 `-r` 选项不会再匹配目录名。

也可以使用 `-d skip` 选项来指定不匹配目录名，如 `grep -d skip "string" *` 命令的打印结果所示。

另外，`grep "string" *` 命令是由 bash 把通配符 `*` 扩展为当前目录下的所有文件名，包括子目录名自身，但不会递归扩展子目录下的文件名。而 `grep "string" -r .` 命令会递归查找子目录下的所有文件。注意这两者的区别。

# 使用 -w 选项指定全词匹配
`grep` 命令默认不是全词匹配，可以匹配到某个单词的一部分。如果想要全词匹配，可以加上 `-w` 选项。查看 man grep 对 `-w` 选项的说明如下：
> **-w, --word-regexp**  
Select only those lines containing matches that form whole words. The test is that the matching substring must either be at the beginning of the line, or preceded by a non-word constituent character. Similarly, it must be either at the end of the line or followed by a non-word constituent character. Word-constituent characters are letters, digits, and the underscore.

即，“全词匹配”指的是所匹配单词的开头和末尾前后都要是不能组成单词的字符。能够组成单词的字符是字母、数字、和下划线。具体举例如下：
```bash
$ echo -e "This is a test string.\nThis" > testfile
$ grep "is" testfile
This is a test string.
This
$ grep -w "is" testfile
This is a test string.
```
可以看到，`grep "is" testfile` 命令会匹配到 "This" 字符串，而 `grep -w "is" testfile` 命令不会匹配到 "This" 字符串。

**注意**：标点符号并不是能够组成单词的字符，字符串后面跟着标点符号并不影响全词匹配。举例如下：
```bash
$ grep -w "string" testfile
This is a test string.
```
可以看到，使用 `-w` 选项指定全词匹配 "string" 字符串，能够匹配到包含 "string." 字符串的这一行，单词后面的标点符号不影响全词匹配。

不加 `-w` 选项时，也可以通过正则表达式来指定全词匹配。后面会具体说明。

# 使用 -n 选项指定打印所匹配行的行号
`grep` 命令在打印匹配行时，默认不显示该行的行号。如果想要显示行号，可以加上 `-n` 选项。查看 man grep 对 `-n` 选项的说明如下：
> **-n, --line-number**  
Prefix each line of output with the 1-based line number within its input file.

即，行号的编号从数字 1 开始。具体举例如下：
```bash
$ grep -n "is" testfile
1:This is a test string.
2:This
```
在匹配行前面打印的数字就是这一行的行号。

# 使用 -i 选项指定忽略大小写
`grep` 命令在匹配时，默认会区分大小写。例如 "TEST" 模式不能匹配到 "test" 字符串。可以使用 `-i` 选项来指定忽略大小写。查看 man grep 对 `-i` 选项的说明如下：
> **-i, --ignore-case**  
Ignore case distinctions in both the PATTERN and the input files.

具体举例如下：
```bash
$ grep "TEST" testfile
$ grep -i "TEST" testfile
This is a test string.
```
可以看到，`grep "TEST" testfile` 命令没有匹配到任何内容。而 `grep -i "TEST" testfile` 命令指定匹配时忽略大小写，可以匹配到 "test" 字符串。

# 使用 -v 选项指定打印不匹配的行
`grep` 命令默认会打印匹配的行，可以使用 `-v` 选项指定打印不匹配的行，也就是过滤掉匹配的行。查看 man grep 对 `-v` 选项说明如下：
> **-v, --invert-match**  
Invert the sense of matching, to select non-matching lines.

具体举例如下：
```bash
$ grep -v "test" testfile
This
```
可以看到，加了 `-v` 选项后，没有打印出包含 "test" 模式的 "This is a test string." 这一行，而是打印出不包含 "test" 模式的 "This" 这一行。

# 使用 -e 选项分别指定多个模式字符串
`grep` 命令可以使用 `-e` 选项来分别指定多个模式字符串，每个模式字符串前面都要加 `-e` 选项。查看 man grep 对 `-e` 的说明如下：
> **-e PATTERN, --regexp=PATTERN**  
Use PATTERN as the pattern.  This can be used to specify multiple search patterns, or to protect a pattern beginning with a hyphen (-).

即，在 `-e` 选项后面的 *PATTERN* 参数会被当成要匹配的模式字符串，提供多个 `-e` 选项就能匹配多个模式字符串。注意不要在单个 `-e` 选项后面直接跟多个模式字符串，否则会报错。

如果所给的模式字符串以 `-` 字符开头，`grep` 命令会认为是一个选项参数，导致报错。此时可以用 `\-` 对 `-` 字符进行转义，或者用 `-e` 选项来指定以 `-` 字符开头的模式字符串。具体举例如下：
```bash
$ grep "-test" testfile
grep: invalid option -- 't'
Usage: grep [OPTION]... PATTERN [FILE]...
Try 'grep --help' for more information.
$ grep -e "-test" -e "is" testfile
This is a test string.
New -test string
```
可以看到，`grep "-test" testfile` 命令想要匹配 *-test* 模式字符串，但是执行报错，`grep` 命令把该模式字符串前面的 *-t* 当成了一个选项。而 `grep -e "-test" -e "is" testfile` 命令不会执行报错，`-e "-test"` 选项可以正确识别是要匹配 *-test* 模式字符串。`-e "-test" -e "is"` 这两个选项指定匹配 *-test* 模式字符串或 *is* 模式字符串。

如果不想写多个 `-e` 选项，也可以通过 `-E` 选项使用扩展正则表达式来匹配多个模式。后面会具体说明。

# 使用基本正则表达式来指定匹配模式
`grep` 命令可以使用 `-G` 选项来指定基本正则表达式（basic regular expression）的匹配模式，默认会提供这个选项，可以不用手动提供。查看 man grep 对 `-G` 选项的说明如下：
> **-G, --basic-regexp**  
Interpret PATTERN as a basic regular expression (BRE).  This is the default.

在 man grep 的 *REGULAR EXPRESSIONS* 小节，对正则表达式语法有所介绍。常见表达式说明如下：
- 使用 `^` 匹配行首的空字符串。由于是匹配空字符串，其实就是匹配到行首，所以 `^This` 表示要匹配以 "This" 字符串开头的行。
- 使用 `$` 匹配行末的空字符串，也就是匹配到行末。例如 `string$` 表示匹配以 "string" 字符串结尾的行。
- 使用 `\<` 匹配单词开头的空字符串。例如 `\<is` 表示匹配以 "is" 开头的单词。注意这里的反斜线 `\` 并不是转义字符，它是这个表达式本身的一部分。
- 使用 `\>` 匹配单词末尾的空字符串。例如 `ing\>` 表示匹配以 "ing" 结尾的单词。
- 使用 `\<\>` 来全词匹配这两个表达式中间的单词。例如 `\<is\>` 表示全词匹配 "is" 这个字符串。
- 使用 `*` 匹配零个或连续多个前面的上一个字符。例如 `a*` 匹配空字符串、"aa" 字符串、"aaaaaa" 字符串等。
- 使用 `[]` 来匹配方括号内的任意一个字符。例如 `[abc]` 可以匹配字符 a、字符 b、字符 c。

还有一些其他的表达式，后面用到再具体说明。

使用基本正则表达式进行匹配的一些例子说明如下：
```bash
$ echo -e "This is a test string.\nNew. This is a testString" > testfile
$ grep "^This" testfile
This is a test string.
$ grep "ing$" testfile
New. This is a testString
$ grep "\<str" testfile
This is a test string.
$ grep "String\>" testfile
New. This is a testString
$ grep "\<test\>" testfile
This is a test string.
```
可以看到，`grep "^This" testfile` 匹配以 "This" 开头的行，没有匹配 "This" 在中间的行。`grep "ing$" testfile` 匹配以 "ing" 结尾的行，不会匹配 "ing." 的情况，末尾多了标点符号也不匹配。

`grep "\<str" testfile` 匹配包含以 "str" 开头的单词的行。`grep "String\>" testfile` 匹配包含以 "String" 结尾的单词的行。`grep "\<test\>" testfile` 全词匹配包含 "test" 这个单词的行，跟 `grep -w` 选项的功能相同。

### POSIX 字符类
`grep` 命令可以在正则表达式中使用 POSIX 字符类匹配某类特殊字符。例如在 ASCII 编码格式下，`[:alnum:]` 是 `A-Za-z0-9` 的另一个写法，那么 `[[:alnum:]]` 相当于 `[A-Za-z0-9]`，对应任意一个字母或数字。

**注意**：在 `[:alnum:]` 这个写法中，两边的方括号 `[]` 是这个字符类的一部分，并不是正则表达式的 `[]` 表达式，要把整个内容再放到方括号 `[]` 里面，写成 `[[:alnum:]]` 才是有效的正则表达式。具体举例如下：
```bash
$ grep [:alnum:] testfile
grep: character class syntax is [[:space:]], not [:space:]
$ grep [[:alnum:]] testfile
This is a test string.
New. This is a testString
```
可以看到，`grep [:alnum:] testfile` 命令执行报错，提示正确的语法格式是把 `[:space:]` 再放到一个方括号 `[]` 里面。这里打印的 `[:space:]` 是一个举例的提示，跟该命令提供的 `[:alnum:]` 无关。

而 `grep [[:alnum:]] testfile` 命令没有执行报错，它会匹配到各个字母、或数字。

参考 GNU grep 在线帮助手册 <https://www.gnu.org/software/grep/manual/html_node/Character-Classes-and-Bracket-Expressions.html>，对 `grep` 命令支持的各个 POSIX 字符类的说明如下：
| POSIX 字符类 | 含义 |
| -- | -- |
| [:alnum:]  | 字母字符和数字字符 (可以匹配中文字符) |
| [:alpha:]  | 字母字符 (可以匹配中文字符) |
| [:blank:]  | 空白字符，特指空格和 tab 字符，不包含换行符 |
| [:cntrl:]  | 控制字符 |
| [:digit:]  | 数字字符 |
| [:graph:]  | 图形字符，包括字母、数字、标点符号，不包括空格 |
| [:lower:]  | 小写字符 (不能匹配中文字符) |
| [:print:]  | 可打印字符，包括字母、数字、标点符号、和空格 |
| [:punct:]  | 标点符号，也包括运算符、各种括号等 |
| [:space:]  | 所有空白字符 (空格，制表符，换行符，回车符) |
| [:upper:]  | 大写字符 (不能匹配中文字符) |
| [:xdigit:] | 十六进制数字 (0-9，a-f，A-F) |

**注意**：虽然 `[:space:]` 可以匹配换行符，但是 `grep` 命令在读取文件内容时，会去掉行末的换行符，所以在 `grep` 中用 `[:space:]` 匹配不到只有一个换行符的空行。

# 使用扩展正则表达式来指定匹配模式
上面提到，`grep` 命令默认支持用基本正则表达式来指定匹配模式。除此之外，可以用 `-E` 选项来指定使用扩展正则表达式（extended regular expression）。查看 man grep 对 `-E` 选项的说明如下：
> **-E, --extended-regexp**  
Interpret PATTERN as an extended regular expression (ERE).

在 man grep 的 *Basic vs Extended Regular Expressions* 小节提到了基本正则表达式和扩展正则表达式的区别：
> In basic regular expressions the meta-characters ?, +, {, |, (, and ) lose their special meaning; instead use the backslashed versions \?, \+, \{, \|, \(, and \).

即，比起基本正则表达式，扩展正则表达式在使用一些元字符时，不需要用反斜线 `\` 进行转义就能使用。例如，在基本正则表达式中，`+` 就表示加号 ‘+’ 这个字符本身，没有什么特殊含义，如果想要当成正则表达式元字符，需要写成 `\+` 的形式。而在扩展正则表达式中，`+` 对应正则表达式的元字符，不用写成 `\+` 的形式。

**注意**：`grep` 命令使用 GNU BRE 版本的基本正则表达式，GNU BRE 也支持扩展正则表达式的这些元字符，只是要用反斜线 `\` 进行转义而已。而 POSIX 标准定义的 BRE 不支持 `?, +, {, |` 这些元字符。

对于部分元字符说明如下：
- 使用 `?` 表示匹配零个或一个前面的上一个字符，最多只能匹配一个字符。
- 使用 `+` 表示匹配一个或连续多个前面的上一个字符，至少匹配一个字符。
- 使用 `|` 表示匹配在该元字符前面的模式、或者匹配在该元字符后面的模式。例如，`abc|efg` 表示匹配 "abc" 字符串、或者匹配 "efg" 字符串。

一般常用 `grep -E` 和 `|` 元字符来指定匹配多个模式，类似于提供多个 `-e pattern` 选项。举例说明如下：
```bash
$ grep -E "test string|testString" testfile
This is a test string.
New. This is a testString
$ grep "test string\|testString" testfile
This is a test string.
New. This is a testString
$ grep "test string|testString" testfile
```
可以看到，`grep -E "test string|testString" testfile` 命令可以查找到包含 "test string" 字符串、或者包含 "testString" 字符串的行。

`grep "test string\|testString" testfile` 命令不提供 `-E` 选项，使用 GNU BRE 基本正则表达式，用 `\|` 对 `|` 元字符进行转义，也能查找到包含 "test string" 字符串、或者包含 "testString" 字符串的行。`grep "test string|testString" testfile` 命令则什么都没有查找到。

# 使用 -q 选项指定不打印任何内容
如前面说明，可以使用类似 `echo "$value" | grep pattern` 这样的命令，在 *value* 变量值中查找 *pattern* 模式，并检查 `grep` 命令的返回值，从而判断 *pattern* 模式字符串是不是 *value* 变量值的子字符串。

这个命令有一个小问题是会打印匹配结果。对于判断是否子字符串的需求来说，我们只需要使用 `$?` 获取 `grep` 命令返回值并进行检查即可，并不需要看到这个匹配结果。此时，可以使用 `-q` 选项指定不打印任何内容。查看 man grep 对 `-q` 选项的说明如下：
> **-q, --quiet, --silent**  
Quiet; do not write anything to standard output. Exit immediately with zero status if any match is found, even if an error was detected.

即，`-q` 选项指定不打印任何内容到标准输出，即使遇到错误也不打印，只会返回命令执行的结果，如果匹配返回 0，否则返回非 0 值。可以用 `$?` 来获取到这个返回值。举例说明如下：
```bash
$ grep -q "test" testfile
$ echo $?
0
$ grep -q "NONE" testfile
$ echo $?
1
```
可以看到，`grep -q "test" testfile` 命令在 *testfile* 文件中能查找到 "test" 字符串，但是没有打印出匹配行， `echo $?` 打印为 0，说明确实能匹配。对于查找不到 "NONE" 字符串的情况，`echo $?` 打印为 1。

# 使用 -A、-B、或 -C 选项查看匹配行前后的内容
`grep` 命令默认只打印包含匹配模式的行，如果想要打印这一行的前后几行，可以使用 `-A`、`-B`、或 `-C` 选项。查看 man grep 对这几个选项的说明如下：
> **-A NUM, --after-context=NUM**  
Print NUM lines of trailing context after matching lines. Places a line containing a group separator (--) between contiguous groups of matches.

> **-B NUM, --before-context=NUM**  
Print NUM lines of leading context before matching lines. Places a line containing a group separator (--) between contiguous groups of matches.

> **-C NUM, -NUM, --context=NUM**  
Print NUM lines of output context. Places a line containing a group separator (--) between contiguous groups of matches.

即，`-A NUM` 指定打印匹配行后面的 *NUM* 行。`-B NUM` 指定打印匹配行前面的 *NUM* 行。`-C NUM` 指定打印匹配行前后的 *NUM* 行，这个选项可以简写为 `-NUM`。

对于这三个选项来说，每一个匹配行会打印出多行内容，在不同匹配内容块之间会在打印一个只包含 `--` 的行来分隔开。具体举例说明如下：
```bash
$ echo -e "1\n2\n3\n4\n5\n11\n22\n33\n44\n55" > testfile
$ grep 3 -A 1 testfile
3
4
--
33
44
$ grep 3 -B 1 testfile
2
3
--
22
33
$ grep 3 -C 1 testfile
2
3
4
--
22
33
44
```
在这个打印结果中，`--` 这一行并不是 *testfile* 文件自身的内容，而是 `grep` 命令打印的分割线。

**注意**：如果在匹配行的前后内容中包含另一个匹配行，那么它们会连在一起打印，并不会重复打印同一个匹配行。如下面的例子所示：
```bash
$ echo -e "1\n2\n3\n33\n4\n5" > testfile
$ grep 3 -B 2 testfile
1
2
3
33
```
可以看到，匹配到 “3” 这一行时，它上面两行是 “2”、“1” 这两行，打印了这两行。匹配到 “33” 这一行时，它上面两行是 “3”、“2” 这两行，但是并没有分隔开来打印这两行，这两个匹配行连在一起打印。

即，使用 `-A`、`-B`、或 `-C` 选项时，不会出现同一个匹配行被打印两次的情况，相邻匹配行前后内容的同一行也不会被打印两次。`grep` 命令对这些情况都进行了优化。

# 使用 -l 选项只打印文件名，不打印匹配的行内容
当在多个文件中进行查找时，`grep` 命令会先打印文件名，随后再打印匹配的行内容。如果只想打印文件名，不打印匹配的行内容，可以加上 `-l` 选项。查看 man grep 对 `-l` 选项的说明如下：
> **-l, --files-with-matches**  
Suppress normal output; instead print the name of each input file from which output would normally have been printed. The scanning will stop on the first match.

例如，我们可能想要查看某个变量出现在哪些文件中，如果打印匹配的行内容，可能会有很多输出，不方便查看文件名，就可以加上 `-l` 选项来指定只打印文件名。举例如下：
```bash
$ grep Fexecute -l -r ./
./src/kwsearch.c
./src/grep.c
./src/search.h
```
基于这个打印结果，可以清楚地看到 *Fexecute* 变量在上面三个文件中出现过。

# 结合 find、xargs 命令一起使用
在 Linux 中，可以使用 `find` 命令来查找包含特定名称的文件，然后用 `xargs` 命令把这些文件名传给 `grep` 命令来统一查找特定的模式。

例如，下面命令会查找当前目录下所有后缀名为 `.c` 的文件，然后在这些文件中查找 "main" 字符串：
```bash
$ find . -name "*.c" | xargs grep "main"
```

**注意**：上面的 `xargs` 命令必须提供，否则不会查找文件内容。如果写成 `find . -name "*.c" | grep "main"`，那么是在 `find` 命令打印的文件名中查找 "main" 字符串，而不是在这些文件名对应的文件内容中进行查找。

另外，`xargs` 命令调用 `grep` 时，没有继承 bash 的 `alias` 别名，所以打印结果没有颜色高亮。如果想要显示颜色高亮，需要写为 `xargs grep --color=auto` 的形式。
