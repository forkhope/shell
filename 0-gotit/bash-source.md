# 记录 bash source 内置命令的使用笔记

介绍在 bash shell 脚本中如何执行外部脚本文件，以及如何调用其他脚本里面的函数。

# 在 shell 脚本中执行外部脚本文件
在 bash shell 脚本文件中，如果需要执行外部脚本文件，跟执行外部命令是一样的，直接通过外部脚本文件名来执行即可，可能需要提供寻址路径。

例如，要在 `a.sh` 脚本文件中执行当前目录下的 `b.sh` 脚本文件，直接在 `a.sh` 文件里面写上 `./b.sh` 语句，就可以执行  `b.sh` 脚本文件。

如果需要提供参数，在 `./b.sh` 后面写上参数即可，不同参数之间用空格隔开，如果参数自身带有空格，要用引号把该参数括起来。例如，写为 `./b.sh arg1 arg2`。

在执行 `a.sh` 脚本文件时，`a.sh` 会运行在一个子 shell 里面，这个子 shell 会再启动一个子 shell 来执行 `b.sh` 脚本文件。在 `b.sh` 里面执行 `exit` 命令，只会退出 `b.sh` 的执行，不会退出 `a.sh` 的执行。

**注意**：在 `a.sh` 脚本中执行 `b.sh` 脚本文件时，如果 `b.sh` 脚本文件没有放在 PATH 环境变量可以寻址的目录里面，那么需要在 `a.sh` 里面提供 `b.sh` 脚本文件的寻址路径，建议写为绝对路径，以保证总是能寻址到 `b.sh` 脚本文件。

如果写为相对路径，会被执行 `a.sh` 的工作目录所影响，基于所给的相对路径，可能会寻址不到 `b.sh` 脚本文件。具体说明如下。

假设有一个 `a.sh` 脚本文件，其内容如下
```bash
#!/bin/bash

echo "$0: this is a.sh"
./b.sh
```

有一个 `b.sh` 脚本文件，其内容如下：
```bash
#!/bin/bash

echo "    $0: this is b.sh"
```

把 `a.sh` 和 `b.sh` 放到同一个目录下，都添加可执行权限。在这两个脚本文件所在的目录开始测试：
```bash
$ ./a.sh
./a.sh: this is a.sh
    ./b.sh: this is b.sh
$ mkdir subdir
$ cd subdir
$ ../a.sh
../a.sh: this is a.sh
../a.sh: line 4: ./b.sh: No such file or directory
```
可以看到，在这两个脚本文件所在的目录，执行 `./a.sh`，可以正常寻址到 `b.sh`，并执行 `b.sh`。

但是进入到该目录下的 *subdir* 目录，通过 `../a.sh` 执行父目录的 `a.sh` 脚本文件，会提示找不到 `./b.sh` 脚本文件，无法执行 `b.sh`。

即，在 `a.sh` 脚本里面执行 `b.sh` 脚本时，是基于当前工作目录来寻址到 `b.sh`，而不是基于 `a.sh` 脚本文件所在的目录来寻址 `b.sh`。

当前工作目录可能不固定，在 `a.sh` 里面写为相对路径来寻址 `b.sh`，后续执行可能导致找不到 `b.sh`。写为绝对路径，就不会受到工作目录的影响。

# 用 source 命令执行其他脚本
在 bash 中，可以使用 `source` 内置命令、或者 `.` 内置命令来在当前脚本进程中执行其他脚本文件。

`source` 命令和 `.` 命令相互等价，查看 help source 的帮助信息和 help . 的帮助信息完全一样。后面会以 `source` 命令作为例子，统一说明。

查看 help source 的说明如下：
> **source filename [arguments]**  
Execute commands from a file in the current shell.  
Read and execute commands from FILENAME in the current shell. The entries in $PATH are used to find the directory containing FILENAME. If any ARGUMENTS are supplied, they become the positional parameters
when FILENAME is executed.

> Exit Status:  
Returns the status of the last command executed in FILENAME; fails if FILENAME cannot be read.

即，bash 在执行脚本文件时，默认会启动子 shell 来执行该脚本，运行在子进程下。而通过 `source` 命令执行脚本文件时，直接运行在当前 shell 下。所提供的参数会作为被执行脚本文件的位置参数。

**在 `a.sh` 脚本文件中，通过 `source` 命令执行 `b.sh` 脚本文件，有一个好处是可以在 `a.sh` 中通过函数名单独调用到 `b.sh` 中的函数**。这有助于 shell 脚本的代码复用。具体举例如下。

假设有一个 `testsource.sh` 脚本文件，其内容如下：
```bash
#!/bin/bash

echo "$0: this is a.sh"
./utils.sh
utils_print

source ./utils.sh
utils_print
```

有一个 `utils.sh` 脚本文件，其内容如下：
```bash
#!/bin/bash

utils_print()
{
    echo -e "    b.sh: this is utils_print"
}
```

把这两个脚本文件放到同一个目录下，执行 `testsource.sh` 脚本文件，结果如下：
```bash
$ ./testsource.sh
./testsource.sh: this is a.sh
./testsource.sh: line 5: utils_print: command not found
    b.sh: this is utils_print
```
可以看到，在 `testsource.sh` 中执行 `./utils.sh` 语句后，执行 *utils_print* 报错，提示找不到这个命令。这种方式不能通过函数名调用到外部脚本文件里面的函数。

而在 `testsource.sh` 中执行 `source ./utils.sh` 语句后，执行 *utils_print* 没有报错，且确实调用到 `utils.sh` 里面的函数。

即，通过 `source` 命令执行外部脚本后，被执行脚本的全局变量名、函数名会被导出到当前 shell 中，可以通过函数名调用外部脚本里面的函数，也可以通过变量名来引用外部脚本里面的全局变量。

**注意**：假设 `a.sh` 脚本通过 `source` 命令执行了 `b.sh` 脚本，在实际使用时有一些需要注意的地方。具体说明如下：
- 由于 `source` 命令执行的脚本文件会运行在当前 shell 下，如果 `b.sh` 脚本执行了 `exit` 语句，不但该脚本会退出，调用它的 `a.sh` 脚本也会退出。如果不想 `b.sh` 脚本的执行状态影响到 `a.sh` 脚本的执行状态，那么 `b.sh` 脚本要慎重使用 `exit` 语句。
- 在 `a.sh` 脚本里面要通过绝对路径来寻址 `b.sh` 脚本，或者把 `b.sh` 脚本文件放在 PATH 环境变量可以寻址的目录里面，以保证在任意工作目录下执行 `a.sh` 脚本时，都能寻址到 `b.sh` 脚本。
- 在 `a.sh` 脚本通过 `source` 命令执行 `b.sh` 脚本，那么 `b.sh` 脚本代码里面的 `$#` 对应的是 `a.sh` 的参数个数，还是执行 `b.sh` 脚本时的参数个数？答案是视情况而定。描述如下：
    - 如果 `a.sh` 脚本没有传递参数给 `b.sh` 脚本，那么在 `b.sh` 脚本中获取 `$#` 的值，对应传递给 `a.sh` 的参数个数。例如执行 `source ./b.sh`，那么 `b.sh` 打印 `$#` 的值跟 `a.sh` 打印的值相等。
    - 如果 `a.sh` 脚本传递了参数给 `b.sh` 脚本，那么 `b.sh` 脚本里面的 `$#` 对应传递给 `b.sh` 的参数个数。例如执行 `source ./b.sh 1 2 3`，那么 `b.sh` 打印 `$#` 的值会是 3。
- 用 `source` 命令执行 `b.sh` 脚本，`b.sh` 脚本的全局变量会导出到当前 shell 下。在当前 shell 没有退出之前，这个全局变量值会一直存在。即使 `b.sh` 脚本执行结束，它里面的全局变量值还是存在。再次使用 `source` 命令调用 `b.sh`，如果没有重新为全局变量赋值，它的值不会变。具体举例说明如下。

修改前面的 `utils.sh` 脚本为下面的内容：
```bash
#!/bin/bash

declare value

if [ $# -eq 1 ]; then
    value="$1"
fi

echo $value
```
这里使用 `declare value` 声明一个 *value* 变量，但是没有为它赋予初值。

用 `source` 命令多次执行该脚本，结果如下：
```bash
$ source ./utils.sh init_value
init_value
$ source ./utils.sh
init_value
```
执行 `source ./utils.sh init_value` 命令，`utils.sh` 脚本会把 *value* 变量赋值为 "init_value"，并打印出这个值。

接着执行 `source ./utils.sh` 命令，没有传参，没有为 *value* 变量赋值，但是打印出 *value* 变量值为 "init_value"，保持为之前的值。

即，当多次通过 `source` 命令执行某个脚本时，如果这个脚本里面使用到全局变量，需要基于实际需求来确认是否需要为全局变量赋予初值，避免之前保存的值带来干扰。

# 一个可以通过函数名调用内部函数的脚本模板
前面介绍通过 `source` 命令执行外部脚本后，可以通过函数名单独调用外部脚本里面的函数。由于该脚本会运行在当前 shell 下，会对当前 shell 造成影响，编写脚本代码有不少需要注意的地方，否则会引入一些不预期的问题。

其实，不使用 `source` 命令执行外部脚本，也可以通过函数名来调用该脚本里面的函数，只需要调整一下脚本代码的写法。

假设要调用 `utils.sh` 脚本里面的函数，可以让该脚本接收一个或多个参数，指定要调用的函数名，以及要传递给该函数的参数，然后 `utils.sh` 脚本自己执行这个函数即可。调用该脚本的格式类似如下：
```bash
utils.sh function_name [arguments]
```
此时，当前 shell 会启动一个子 shell 来运行 `utils.sh` 脚本。

这个格式类似于 `source` 命令的格式，只是 `source` 命令指定要执行的脚本文件名，而这里指定要调用的函数名。

为了满足这个需求，修改 `utils.sh` 脚本为下面的内容：
```bash
#!/bin/bash

function show_args()
{
    echo "Enter show_args(): FUNCNAME: $FUNCNAME"
    echo "Enter show_args(): \$1: $1"
    echo "The arguments are: $@"
}

if [ $# -ne 0 ]; then
    funcname="$1"
    shift 1
    $funcname "$@"
fi
```
当 `$#` 不等于 0 时，说明提供了参数，那么第一个参数预期是想要调用的函数名，保存给 *funcname* 变量。

然后执行 `shift 1` 命令，向左移动一个位置参数。原来的 `$2` 会变成 `$1`，`$3` 会变成 `$2`，依此类推。这样做可以跳过传入脚本的第一个参数。这个参数是想要调用的函数名，不需要传递给被调用的函数。

最后执行 `$funcname "$@"` 语句，也就是调用 *funcname* 变量保存的函数，并把移动后的位置参数都传给该函数。

这里实现了一个 *show_args* 函数，里面打印了当前函数名、传入的第一个参数、以及所有参数。

具体测试结果如下：
```bash
$ ./utils.sh show_args 1 2 3
Enter show_args(): FUNCNAME: show_args
Enter show_args(): $1: 1
The arguments are: 1 2 3
$ value=$(./utils.sh show_args 1 2 3)
$ echo $value
Enter show_args(): FUNCNAME: show_args Enter show_args(): $1: 1 The arguments are: 1 2 3
```
可以看到，`./utils.sh show_args 1 2 3` 命令确实调用到 `utils.sh` 脚本里面的 *show_args* 函数，并把 `1 2 3` 作为参数传递给该函数。

如果上面不执行 `shift 1` 命令，那么 *show_args* 函数收到的 `$1` 参数会是 show_args，`$2` 会是 1。而预期是把 1 作为该函数的第一个参数，对应 `$1`。执行  `shift 1` 命令可以达到这个效果。

如果想要获取函数输出的字符串，那么在函数里面用 `echo` 命令打印对应的字符串，然后用 `$()` 就能获取这个值。如上面的 `value=$(./utils.sh show_args 1 2 3)` 命令所示。

这种情况下，函数里面不能再用 `echo` 命令打印调试信息，否则调试信息也会被调用者获取到，影响调用者对这个字符串的解析。

这段 `utils.sh` 脚本代码就是一个可以通过函数名调用内部函数的脚本模板。基于实际需求添加相应的函数，这些函数就可以被复用，方便其他脚本进行调用。
