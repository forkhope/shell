# 描述 bash shift 内置命令的使用笔记

# 使用 shift 命令重命名各个位置参数的值
在 bash 中，可以使用位置参数（positional parameters）来获取传入脚本、或者传入函数的各个参数值。  
例如，`$1` 对应传入的第一个参数，`$2` 对应传入的第二个参数。依次类推。

我们可以使用 `shift` 内置命令来重命名位置参数。  
例如，执行 `shift 1` 命令后，`$1` 会对应传入的第二个参数，`$2` 会对应传入的第三个参数。依次类推。

查看 man bash 对 `shift` 命令的说明如下：
> **shift [n]**  
> The positional parameters from n+1 ... are renamed to $1 ....  Parameters represented by the numbers $# down to $#-n+1 are unset.  
> n must be a non-negative number less than or equal to $#. If n is 0, no parameters are changed.  
> If n is not given, it is assumed to be 1. If n is greater than $#, the positional parameters are not changed.  
> The return status is greater than zero if n is greater than $# or less than zero; otherwise 0.

即，`shift` 命令基于所给的 *n* 参数值来重命名位置参数。  
把 `$1` 重命名为 `$n+1`、`$2` 重命名为 `$n+2`，依此类推。  
类似于向左移动 *n* 个位置参数。

如果没有提供 *n* 参数，默认值为 1。  
所给的 *n* 必须是大于或等于 0 的整数。

由于 `shift` 命令的参数不能是负数，当执行该命令重命名位置参数后，无法使用这个命令恢复成原来的位置参数。

执行 `shift` 命令后，`$#` 的值会被更新为剩余的参数个数，`$@` 只会获取到剩余的参数列表。

当需要把传入脚本的某个参数之后的所有参数都传递给脚本函数时，就可以使用 `shift` 命令来重命名位置参数，方便引用。

下面以一个 `testshift.sh` 脚本来举例说明该命令的用法，脚本内容如下：
```bash
#!/bin/bash

reverse=0

function print_params()
{
    local string="$@"
    if [ $reverse -eq 1 ]; then
        echo $string | rev
    else
        echo $string
    fi
}

while getopts "r" opt; do
    case $opt in
        r) reverse=1 ;;
    esac
done

shift $((OPTIND-1))
print_params "$@"
```
这个脚本可以接收一个 `-r` 选项，提供该选项，则使用 `rev` 命令反序输出所给的字符串参数。  
如果没有提供该选项，则正序输出所给的字符串参数。

当 `getopts` 命令处理选项参数后，*OPTIND* 全局变量会被加上选项参数的个数，其值从 1 开始，则 `$((OPTIND-1))` 获取到选项参数个数。  
例如执行 `./testshift.sh -r` 命令，提供了一个 `-r` 选项参数，则 `getopts` 处理这个选项参数后，*OPTIND* 的值是 2，减去 1 就是选项参数的个数。

使用 `shift $((OPTIND-1))` 命令跳过所给的选项参数，之后使用 `$@` 获取到的参数列表不包含选项参数。  
这些选项参数不需要传递给 *print_params* 函数。

如果这里不使用 `shift` 命令，直接写为 `print_params "$@"` 语句，那么 *print_params* 函数会收到传入的 `-r` 选项，且 `$1` 就是 `-r` 选项。  
那么函数就需要对这个选项做特殊处理，代码不够简练。

即，如果想要跳过命令行参数的前面几个参数，把之后的所有参数都统一传递给其他地方使用，使用 `shift` 命令非常方便。  
否则需要遍历命令行参数来获取后面的所有参数值，单独保存起来，然后再传递，这样比较麻烦。

执行 `testshift.sh` 脚本，结果如下：
```bash
$ ./testshift.sh 客上天然居 人过大佛寺
客上天然居 人过大佛寺
$ ./testshift.sh -r 客上天然居 人过大佛寺
寺佛大过人 居然天上客
```
可以看到，`./testshift.sh -r 客上天然居 人过大佛寺` 命令提供了 `-r` 选项，会反序打印所给的字符串参数。  
由于使用了 `shift` 命令，这个 `-r` 选项没有传递给 *print_params* 函数，打印的内容不包含这个选项。
