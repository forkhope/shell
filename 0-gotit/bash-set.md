# 记录 bash set 内置命令的使用笔记

在 bash 中，可以使用 `set` 内置命令设置和查看 shell 的属性。  
这些属性会影响 shell 的不同行为。  
下面对一些常用的属性进行说明。

# set 命令
查看 help set 对 `set` 命令的说明如下：
> **set: set [-abefhkmnptuvxBCHP] [-o option-name] [--] [arg ...]**  
> Change the value of shell attributes and positional parameters, or display the names and values of shell variables.
> 
> Using + rather than - causes these flags to be turned off.

即，`set` 命令后面可以跟着要设置的 shell 属性选项。  
如果选项以 `-` 开头，则是设置为打开该选项。  
如果选项以 `+` 开头，则是设置为关闭该选项。

# 使用 set -e 选项在遇到报错后停止执行
查看 help set 命令，对 `-e` 选项说明如下：
> **-e**  
Exit immediately if a command exits with a non-zero status.

即，`set -e` 会在遇到任何非 0 的命令返回值时，退出所在的 shell。

在脚本开头 `#!/bin/bash` 语句的下一行添加 `set -e` 语句，那么执行该脚本时，执行过程中遇到的任何错误都会终止脚本，可以避免执行后续的脚本语句。

具体举例说明如下：
```bash
#!/bin/bash
set -e
```

从编程的角度来说，`set -e` 选项的作用跟C语言的 assert() 函数类似，遇到错误就停止。  
在调试 shell 脚本时，如果遇到某个不预期的错误，就可以使用这个选项让脚本及时停止运行，以便找到最接近出错位置的语句。

# 使用 set -x 选项打开调试开关
查看 help set 命令，对 `-x` 选项说明如下：
> **-x**  
Print commands and their arguments as they are executed.

即，`set -x` 会打印具体执行的命令、以及命令的参数。  
这些参数是经过 bash 扩展后的参数，可以方便看到的各个变量值扩展后的结果是什么、某个变量是否扩展为空导致参数个数发生变化，等等。

如前面说明，把选项开头的 `-` 改成 `+` 会关闭选项，`set +x` 命令关闭调试开关。

具体举例如下：
```bash
$ set -x
$ ls test*
+ ls --color=auto testcase.sh testfile
$ set +x
```
这里先执行 `set -x` 命令打开调试开关。  
然后执行 `ls test*` 命令，可以看到扩展后的命令为 `ls --color=auto testfile testcase.sh`。  
从扩展后的结果可以看到 `test*` 被扩展为当前目录下以 "test" 开头的文件名，有助于理解 `*` 通配符的扩展结果。

可以使用类似于下面的语句在 shell 脚本中设置该选项：
```bash
#!/bin/bash
set -x
```

在学习 bash 通配符、各个扩展表达式时，`set -x` 可以打印出具体的扩展结果，便于理解。

# 使用 set -v 回显所输入的命令
查看 help set 命令，对 `-v` 选项说明如下：
> **-v**  
Print shell input lines as they are read.

即，`set -v` 选项会回显所输入的命令。

跟 `set -x` 的区别在于，`set -x` 显示的是扩展后的结果，而 `set -v` 显示的是所输入的命令自身。

具体举例如下：
```bash
$ set -v
$ ls test*
ls test*
testcase.sh  testfile
```
可以看到，设置 `set -v` 选项后，执行 `ls test*` 命令，回显的内容就是 "ls test*"。  
而不是回显 `test*` 扩展之后、以 "test" 开头的文件名。
