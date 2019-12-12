# 记录一些杂项的使用笔记

# 把变量赋值为换行符
在 bash 中，如果要把变量赋值为换行符，写为 '\n' 没有效果，需要写为 $'\n'。具体举例如下：
```bash
$ newline='\n'
$ echo $newline
\n
$ newline=$'\n'
$ echo $newline

```
可以看到，把 *newline* 变量赋值为 '\n'，得到的是 *\n* 这个字符串，而不是换行符自身。

这是 bash 和 C 语言不一样的地方。  
在 C 语言中，'\n' 对应换行符自身，只有一个字符；而 "\n" 对应一个字符串。  
但是在 bash 中，'\n' 也是对应一个字符串。

把 *newline* 赋值为 $'\n'，就能获取到换行符自身。查看 man bash 对这个写法的说明如下：
> Words of the form $'string' are treated specially. The word expands to string, with backslash-escaped characters replaced as specified by the ANSI C standard. Backslash escape sequences, if present, are decoded as follows:
```
    \n     new line
    \r     carriage return
    \t     horizontal tab
    \'     single quote
```
> The expanded result is single-quoted, as if the dollar sign had not been present.

即，$'string' 这个写法可以使用 C 语言的转义字符来获取到对应的字符自身。

# 判断文件的最后一行是否以换行符结尾
在 Linux 中，可以使用下面命令来判断文件的最后一行是否以换行符结尾：
```bash
test -n "$(tail filename -c 1)"
```

这里使用 `tail filename -c 1` 命令获取到 *filename* 文件的最后一个字符。

实际使用时，需要把 *filename* 换成具体要判断的文件名。

`tail` 命令可以获取文件末尾的内容。它的 `-c` 选项指定要获取文件末尾的多少个字节。

查看 man tail 对 `-c` 选项的说明如下：
> **-c, --bytes=K**  
output the last K bytes; alternatively, use -c +K to output bytes starting with the Kth of each file.

即，`tail -c 1` 命令指定获取所给文件的最后一个字符。

获取到文件的最后一个字符后，要判断该字符是不是换行符。这里不能直接判断该字符是否等于换行符，而是要判断该字符是否为空。

原因在于，使用 `$(tail filename -c 1)` 命令替换来获取内部命令的输出结果时，bash 会去掉末尾的换行符。

所以当文件的最后一行以换行符结尾时，`$(tail filename -c 1)` 命令替换会去掉获取到的换行符，最终结果为空，并不会返回换行符自身。

查看 man bash 对命令替换（command substitution）的说明如下：
> Command substitution allows the output of a command to replace the command name.  There are two forms:
```
        $(command)
    or
        `command`
```
> Bash performs the expansion by executing command and replacing the command substitution with the standard output of the command, with any trailing newlines deleted.  Embedded newlines are not deleted, but they may be removed during word splitting.

可以看到，经过命令替换后，会去掉末尾的换行符。

由于 `$(tail filename -c 1)` 命令替换会去掉末尾的换行符，这里使用 `test -n` 来判断最终结果是否为空字符串。

如果文件最后一行以换行符结尾，那么 `$(tail filename -c 1)` 的结果为空，`test -n` 命令会返回 1，也就是 false。

如果文件最后一行没有以换行符结尾，那么 `$(tail filename -c 1)` 的结果不为空，`test -n` 命令会返回 0，也就是 true。

可以根据实际需要，改用 `test -z` 来判断。如果文件最后一行以换行符结尾，`$(tail filename -c 1)` 的结果为空，`test -z` 命令会返回 0，也就是 true。
