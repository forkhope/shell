# 描述 sed 命令的使用
在 Linux 中，`sed` 命令的完整格式如下：
> sed [OPTION]... {script-only-if-no-other-script} [input-file]...

# 修改输入文件本身的内容
sed 命令是一个流编辑器 (stream editor)，可以对输入的文本内容进行处理，文本内容可来自文件或者管道。

它默认把处理后的结果打印到标准输出，不修改文件本身内容。

在 man sed 里面没有具体说明 `sed` 命令的处理结果会输出到哪里。

查看 GNU sed 的在线帮助说明，提到会打印到标准输出：<https://www.gnu.org/software/sed/manual/sed.html#output>
> sed writes output to standard output.
> Use -i to edit files in-place instead of printing to standard output.
> See also the W and s///w commands for writing output to other files.
> The following command modifies file.txt and does not produce any output:
```bash
    sed -i 's/hello/world/' file.txt
```

即， sed 默认不会把处理结果写入到所给文件，如果要修改文件本身内容，要加 **-i** 选项。

# 寻址 Addresses
在 man sed 中，描述了 `sed` 命令如何选择要操作的行：
> Sed commands can be given with no addresses, in which case the command will be executed for all input lines; with one address, in which case the command will only be executed for input lines which match that address; or with two addresses, in which case the command will be executed for all input lines which match the inclusive range of lines starting from the first address and continuing to the second address. 

部分例子如下：
- number: Match only the specified line number. 直接用数字指定要操作的行数
- /regexp/: Match lines matching the regular expression regexp.
- $: Match the last line.

# 删除操作
sed 使用 **d** 命令来删除指定的行，man sed 的说明如下：
> **d**  
> Delete pattern space.  Start next cycle.

下面是几个使用 **d** 命令从输出结果中删除某些行的例子：
- 在输出结果中不打印filename文件的第一行：
```bash
    sed '1d' filename
```
- 在输出结果中不打印filename文件的最后一行，下面的 `$` 表示匹配最后一行：
```bash
    sed '$d' filename
```
- 在输出结果中不打印filename文件内所有包含 *xml* 字符串的行：
```bash
    sed '/xml/d' filename
```
        或者把 d 命令写在单引号外面
```bash
    sed '/xml/'d filename
```
> **注意**：写为 `sed '/*xml*/d' filename` 将匹配不到包含 *xml* 字符串的行。这跟`'*'`这个字符在通配符和正则表达式之间的差异有关。`sed` 命令使用正则表达式来匹配模式，而在正则表达式中，`'*'`表示匹配零个或任意多个前面的字符，而不是表示匹配任意字符串。
- 在输出结果中不打印只有一个换行符的空行：
```bash
    sed '/^$/d' filename
```
> ^ 表示匹配行首，$ 表示匹配行末，在行首和行末之间没有任何字符，也就是空行。严格来说，这里说的“行末”指的是最后一个换行符前面的一个字符，不包括换行符自身。“空行” 实际上还是包含有一个换行符。
- 在输出结果中不打印由空白字符 (空格,制表符,换行符,回车符) 组成的行：
```bash
    sed '/^[[:space:]]*$/d' filename
```
> 这里使用POSIX字符类`[:space:]`表示空白字符，把`[:space:]`放在`[]`里面，会成为正则表达式，表示匹配在`[]`里面的字符，后面跟了一个`*`，表示匹配0个或多个前面的字符，也就是匹配0个或多个空白字符。匹配到0个空白字符，就是匹配到只有换行符的空行。由于sed在处理时会先去掉行末的换行符，`[:space]`在这里其实匹配不到行末的换行符，而是通过匹配到0个空白字符，相当于 `/^$/d` 的方式去掉空行。

**注意**：这里举例的sed命令不会直接修改所给的 *filename* 文件本身的内容，只是用 d 命令从输出结果中删除匹配的行，如果要直接修改 *filename* 文件本身的内容，要加 -i 选项。

# 替换操作
sed 使用 **s/regexp/replacement/** 命令来替换匹配特定模式的内容，man sed 的说明如下：
> Attempt to match regexp against the pattern space.
> If successful, replace that portion matched with replacement.
> The replacement may contain the special character & to refer to that portion of the pattern space which matched, and the special escapes \1 through \9 to refer to the corresponding matching sub-expressions in the regexp.

举例说明如下，下面的 `sed` 命令表示从标准输入（也就是需要用户输入）读取内容，把输入的 foo 替换为 bar，再打印出来。  
在 `#` 后面的内容是注释说明，不是命令内容的一部分。
```bash
$ sed s'/foo/bar/'    # 从标准输入接收用户输入, 把 foo 替换 bar 再输出
afoo       # 手动输入 afoo, 然后回车
abar       # 回车之后, sed 打印输出结果, 替换显示为 abar
afooF      # foo 位于字符串的中间, 也会被替换
abarF
foo        # 当然, 完整的 foo 也会被替换
bar
```
可以用这个替换命令来删除行末的 '\r' 字符：
```bash
    sed -i 's/\r//' filename
```

Windows下的文本文件，每行的结尾是`\n\r`。  
而在Linux下，每行结尾只有`\n`，那个多出来的`\r`常常会导致一些问题，可以用这一个命令来去掉它。

# 在 sed 中引用 shell 变量
在输入 `sed` 命令时，可以引用当前shell定义好的变量值，用 `$` 来引用即可，但是有一些需要注意的地方：
- 不能使用单引号把替换模式括起来，例如 '/pattern/command/' 要改成 "/pattern/commond". 因为在Bash shell里面，单引号不支持扩展，`$`在单引号里面还是表示'$'字符自身，并不表示获取变量的值，无法用`${param}`来引用变量param的值。
- 实际上是由 bash 自身通过 `$` 来获取变量值，进行变量扩展后，再把变量值作为参数传递传递给 sed 命令进行处理。这不是由 sed 命令自身来获取 bash 定义的变量值。
- 如果变量名后面没有跟着其他字符，在变量名前后可以不加大括号`{}`。例如下面的sed命令获取shell的pat变量的值，然后从输出结果中去掉匹配pat变量值的行：
```bash
    sed /$pat/d filename
```
- 在引用shell变量时，如果变量名后面跟着其他字符，要用`{}`把变量名括起来，避免变量名后面的字符被当成变量名的一部分。例如，有一个pat变量，那么 $pat 获取这个变量的值，${pat}A 表示在pat变量值后面还跟着一个字符A，但是 $patA 表示的是获取名为 patA 的变量值。

# 只打印特定匹配的行
查看 GNU sed 的在线帮助链接：<https://www.gnu.org/software/sed/manual/sed.html>，里面有如下说明：
> By default sed prints all processed input (except input that has been modified/deleted by commands such as d).
> Use -n to suppress output, and the p command to print specific lines.
> The following command prints only line 45 of the input file:
```bash
    sed -n '45p' file.txt
```
即，`sed` 默认会打印出被处理的输入内容，这些内容跟原始输入内容不一定完全一样，`sed` 的一些命令可以修改或删除输入内容，再把新的内容打印出来。  
打印的输出结果并不是只对应匹配特定模式的行。  
那些没有被处理的行，会原样打印。

如果只想打印匹配特定模式的行，要用 `-n` 选项和 `p` 命令。

例如，用下面命令只打印后缀名为 ".xml" 的内容：
```bash
    sed -n '/\.xml$/p'
```
这里使用 `\.` 来转义匹配 '.' 字符，用 '$' 来匹配行末。所以 *\.xml$* 对应 *.xml* 后缀名。

上面贴出的 GNU sed 帮助链接对 -n 选项的具体说明如下：
> **-n**  
> **--quiet**  
> **--silent**  
> By default, sed prints out the pattern space at the end of each cycle through the script (see [How sed works](https://www.gnu.org/software/sed/manual/sed.html#Execution-Cycle)).  
> These options disable this automatic printing, and sed only produces output when explicitly told to via the p command.

查看 man sed 对 -n 选项的说明如下：
> **-n, --quiet, --silent**  
> suppress automatic printing of pattern space

可以看到，man sed 中的说明比较简略且含糊，而在线帮助链接的说明更容易理解，明确说明了 -n 选项避免自动打印pattern space的内容。

如果发现其他选项在man手册中说明不清楚，可以再查看 GNU 在线手册的说明。

**注意**：-n 选项并不表示打印匹配特定模式且被处理的行。  
例如，使用 -n 选项和 d 命令不会看到任何打印，并不会打印出被删除的行。

如果只是打印匹配特定模式的行，一般常用 `grep` 命令，但是 grep 命令不能对匹配的结果做二次处理，而 `sed` 命令可以做二次处理，打印特定匹配的行，且做一些修改。

例如下面的命令把后缀名为 ".cpp" 的行替换成 ".cc"，且只打印出这些行：
```bash
    sed -n 's/\.cpp$/\.cc/p'
```
对该sed命令的各个参数说明如下：
- "-n" 指定不自动打印pattern space的内容
- 用 s 命令来进行替换
- `\.cpp$` 表示匹配 ".cpp" 后缀名
- `\.cc` 是替换后的内容，也就是 ".cc"
- 最后用 p 命令打印处理后的结果。例如输入 `main.cpp`，会打印出 `main.cc`

**注意**：在 *cc* 后面不用加 *$* 字符。在 *cpp* 后面加 *$* 是为了匹配行末，*$* 在这里是正则表达式的元字符。如果在 *cc* 后面加 *$*，*$* 会被当作普通字符，成为替换后的内容的一部分，也就是替换成 *.cc$*，这是不预期的。

上面的帮助链接对 sed 的 p 命令说明如下：
> **p**  
> Print the pattern space.

从字面上看，p 命令就是打印 pattern space。**关键是，pattern space具体是什么**。

上面帮助链接的 "[6.1 How sed Works](https://www.gnu.org/software/sed/manual/sed.html#index-Pattern-space_002c-definition)" 小节具体描述了 "pattern space" 的含义。
> sed maintains two data buffers: the active pattern space, and the auxiliary hold space. Both are initially empty.
>
> sed operates by performing the following cycle on each line of input: first, sed reads one line from the input stream, removes any trailing newline, and places it in the pattern space. Then commands are executed; each command can have an address associated to it: addresses are a kind of condition code, and a command is only executed if the condition is verified before the command is to be executed.
>
> When the end of the script is reached, unless the -n option is in use, the contents of pattern space are printed out to the output stream, adding back the trailing newline if it was removed. Then the next cycle starts for the next input line.

基于这部分说明，*pattern space* 是一块buffer，存放要处理的输入行，sed 命令会对这一行进行处理，有些命令还会修改这一行的内容，处理结束后，可以用 p 命令打印 pattern space 里面的内容。由于这个内容可能会被修改，跟原始输入行的内容不一定完全一样。  
例如，查看上面帮助链接对 s 命令的说明，就能看到 s 命令会修改pattern space的内容：
> **s/regexp/replacement/[flags]**  
> (substitute) Match the regular-expression against the content of the pattern space. If found, replace matched string with replacement.

# 同时匹配多个模式
在 sed 命令中可以使用多个 -e 选项来指定匹配多个模式：
```bash
    sed -e '3,$d' -e 's/foo/bar/g'
```
也可以使用 分号(;) 来分隔多个匹配项：
```bash
    sed '3,$d; s/foo/bar/g'
```
下面举例说明这个方法的一个应用场景。  
我们先用 find 命令查找当前目录底下的所有文件名，现在想要从这些文件名中删除后缀名为 ".rc"、".xml" 的文件名，具体写法如下：
```bash
    sed '/\.rc$/d; /\.xml$/d' filenames
```
使用 `\.` 来匹配后缀名前面的 '.' 字符，`$` 表示匹配行末。  
所以 `\.rc$` 对应 *.rc* 后缀名, `\.xml$` 对应 *.xml* 后缀名。  
最后的 filenames 里面保存查找到的所有文件名，作为 sed 要处理的输入内容。

使用 man sed 查看 -e 选项的说明如下：
> **-e script, --expression=script**  
> add the script to the commands to be executed

即，-e 指定执行后面跟着的命令，多个 -e 可以指定执行多个不同的命令。

在 man sed 中，没有说明可以用分号(;)来分割多个匹配项，要查看 info sed 里面的完整帮助手册，才有相关描述。

如果不习惯查看info命令的内容格式，可以在网上在线查看帮助手册，GNU sed home page: <http://www.gnu.org/software/sed/>

其中，HTML 版本的帮助手册链接是：<https://www.gnu.org/software/sed/manual/sed.html>  
该帮助链接对用分号(;)分割多个匹配项的说明如下，里面还提到可以用换行符来分割。
> Commands within a script or script-file can be separated by semicolons (;) or newlines (ASCII 10). Multiple scripts can be specified with -e or -f ptions.
>
> Commands a, c, i, due to their syntax, cannot be followed by semicolons working as command separators and thus should be terminated with newlines or be placed at the end of a script or script-file.
