# 记录 bash string 的相关笔记

# 用 expr 命令操作字符串
我们可以使用 `expr` 命令对字符串做一些处理。例如：
- `expr index STRING CHARS` 获取指定字符在字符串中的位置
- `expr substr STRING POS LENGTH` 从字符串中获取到子字符串
- `expr length STRING` 获取字符串的长度

## expr index STRING CHARS
查看 man expr 对 `index STRING CHARS` 表达式说明如下：
> **index STRING CHARS**  
index in STRING where any CHARS is found, or 0

即，`expr index STRING CHARS` 命令可以获取 *CHARS* 包含的任意字符在 *STRING* 字符串中第一次出现的位置，位置偏移是从 1 开始数起，不是从 0 开始。如果 *CHARS* 包含的所有字符都没有找到，返回为 0。当 *STRING* 字符串的内容包含空格时，要用双引号括起来，否则会报错。

**注意**：`expr index STRING CHARS` 命令并不是查找 *CHARS* 子字符串在 *STRING* 字符串中的位置，它只能查找单个字符在 *STRING* 字符串中的位置，只是 *CHARS* 可以指定要查找哪几个字符，并以第一个查找到的字符为准。具体举例说明如下：
```bash
$ value="This is a test string."
$ expr index $value a
expr: syntax error
$ expr index "$value" a
9
$ expr index "$value" p
0
$ expr index "$value" "test"
4
$ expr index "$value" "est"
4
```
可以看到，由于 *value* 变量值包含空格，当使用 `$value`、没有加双引号时，命令执行报错。使用 `"$value"`、加了双引号后，没有报错。`expr index "$value" a` 命令返回 `a` 字符在 *value* 变量值中的位置是 9，位置偏移从 1 开始。由于 `p` 字符在 *value* 变量值中不存在，`expr index "$value" p` 返回为 0。

`expr index "$value" "test"` 命令并不是返回 "test" 子字符串在 *value* 变量值中的位置，而不是返回 `t` 、`e` 、`s` 这三个字符的任意一个在 *value* 变量值中第一次出现的位置，那么第一次出现的字符是 `s`，位于开头的 "This" 子字符串，从 1 开始数起，是第 4 个字符，所以该命令返回为 4。

由于是查找多个字符中的任意一个字符，跟提供的字符先后顺序无关，所以 `expr index "$value" "est"` 命令也是返回 4，并不因为 "est" 参数的 `e` 字符在 `s` 字符前面就优先查找 `e` 字符。

## expr substr STRING POS LENGTH
查看 man expr 对 `substr STRING POS LENGTH` 表达式说明如下：
> **substr STRING POS LENGTH**  
substring of STRING, POS counted from 1

即，`expr substr STRING POS LENGTH` 命令从 *STRING* 字符串的第 *POS* 个字符开始，一直获取 *LENGTH* 个字符，得到一个子字符串。位置偏移从 1 开始，不是从 0 开始。当 *STRING* 字符串的内容包含空格时，要用双引号括起来，否则会报错。具体举例说明如下：
```bash
$ value="This is a test string."
$ expr substr "$value" 6 2
is
$ expr substr "$value" 11 4
test
```
可以看到，`expr substr "$value" 6 2` 命令从 *value* 变量值的第 6 个字符开始，获取包括该字符在内的两个字符，得到 "is" 子字符串。`expr substr "$value" 11 4` 命令的执行结果类似。

## expr length STRING
查看 man bash 对 `length STRING` 表达式说明如下：
> **length STRING**  
length of STRING

即，`expr length STRING` 获取 *STRING* 字符串的长度。长度从 1 开始。当 *STRING* 字符串的内容包含空格时，要用双引号括起来，否则会报错。具体举例说明如下：
```bash
$ value="come on"
$ expr length "$value"
7
```

# Bash 进行大小写转换的几种方法
在 bash 中，可以使用下面几种方法进行字符串大小写转换：
- 使用 declare 命令转换大小写
- 使用 tr 命令转换大小写
- `${parameter^^}` 表达式基于 *parameter* 变量值，把所有字符转成大写，得到新的值
- `${parameter,,}` 表达式基于 *parameter* 变量值，把所有字符转成小写，得到新的值

## 使用 declare 命令转换大小写
我们可以使用 declare 命令的 `-l`、`-u` 选项来指定变量值一直保持为小写、或者大写。查看 man bash 对 declare 命令的 `-l`、`-u` 选项说明如下：
- **-l**  
When the variable is assigned a value, all upper-case characters are converted to lower-case.  
- **-u**  
When the variable is assigned a value, all lower-case characters are converted to upper-case.

即，用 `declare -l` 声明的变量，它的字符串值会一直保持小写，赋值内容包含的大写字母，会自动转换为小写。当需要把某个字符串的内容全部转为小写时，就可以把字符串赋值给 `declare -l` 声明的变量。举例如下：
```bash
$ declare -l lower="Turn ON"
$ echo $lower
turn on
```
可以看到，用 `declare -l` 将 *lower* 声明为小写变量，赋值内容包含大写字母，打印该变量的值，全是小写。

用 `declare -u` 声明的变量值则一直保持大写，赋值内容包含的小写字母，会自动转换为大写。举例如下：
```bash
$ declare -u upper="happy new year"
$ echo $upper
HAPPY NEW YEAR
```

**注意**：在 bash 里面有一个 `typeset` 命令也支持 `-l`、`-u` 选项，可用于转换大小写。这个命令已经废弃，被 `declare` 命令所取代。建议使用 `declare` 命令即可。查看 help typeset 的说明如下：
```bash
typeset: typeset [-aAfFgilrtux] [-p] name[=value] ...
    Set variable values and attributes.

    Obsolete.  See 'help declare'.
```

## 使用 tr 命令转换大小写
上面使用 declare 命令转换大小写的方法会转换整个字符串，如果要转换字符串中的特定字符，可以使用 `tr` 命令。可以查看 man tr 的说明，关于大小写转换的关键信息如下：
```bash
tr [OPTION]... SET1 [SET2]
    Translate, squeeze, and/or delete characters 
    from standard input, writing to standard output.

SETs are specified as strings of characters. Most represent themselves. 
Interpreted sequences are:
    CHAR1-CHAR2
        all characters from CHAR1 to CHAR2 in ascending order
    [:lower:]
        ll lower case letters
    [:upper:]
        all upper case letters
```

即，`tr` 命令读取标准输入，把 *SET1* 所指定的字符转换为 *SET2* 指定的字符，可以用 `CHAR1-CHAR2` 的形式来按照字母升序指定多个字符，其实并不限于转换大小写。举例说明如下：
```bash
$ echo "Come ON" | tr A-Z a-z
come on
$ echo "Come ON" | tr A-Z 5
5ome 55
$ echo "happy new year" | tr a-z A-Z
HAPPY NEW YEAR
$ echo "happy new year" | tr [:lower:] [:upper:]
HAPPY NEW YEAR
$ echo "happy new year" | tr hn HN
Happy New year
$ echo "happy new year" | tr hnwr HN
Happy NeN yeaN
```
可以看到，`tr A-Z a-z` 命令把大写字母 `A` 到大写字母 `Z` 之间的所有字符都转换为对应的小写字母。`tr A-Z 5` 命令则是把输入的所有大写字母都转为数字 `5`。`tr a-z A-Z` 命令把输入的所有小写字母转换为对应的大写字母。可以用 `[:lower:]` 来指定所有小写字母，用 `[:upper:]` 来指定所有大写字母。

`tr hn HN` 命令把小写字母 `h` 转换为大写字母 `H`，把小写字母 `n` 转换为大写字母 `N`。当 *SET1* 参数提供的字符个数大于 *SET2* 参数提供的字符个数时，会把 *SET1* 多出来的字符都转换为 *SET2* 的最后一个字符，`tr hnwr HN` 命令演示了这一点，小写的 `w` 和 `r` 都转换为第二个参数最后的大写 `N`。

## 用 ${parameter^^} 表达式转换为大写
Bash 的 `${parameter^^}` 参数扩展表达式，基于 *parameter* 变量值，把所有字符转成大写，得到新的值。这个表达式只能用于变量，*parameter* 必须是一个变量名。举例如下：
```bash
$ value="Come ON"
$ echo ${value^^}
COME ON
$ echo $value
Come ON
```
可以看到，`${value^^}` 把 *value* 变量值里面的小写字母都转成了大写字母，这会得到一个新的字符串，不会修改 *value* 变量值，该变量值还是保持不变。如果需要保存转换后的字符串，可以赋值给具体的变量。

## 用 ${parameter,,} 表达式转换为小写
Bash 的 `${parameter,,}` 参数扩展表达式，基于 *parameter* 变量值，把所有字符转成小写，得到新的值。这个表达式只能用于变量，*parameter* 必须是一个变量名。举例如下：
```bash
$ value="Come ON"
$ echo ${value,,}
come on
```
可以看到，打印 `${value,,}` 的值，全是小写字母。这个表达式也不会修改 *value* 变量自身的值。

# Bash使用 =~ 操作符判断字符串是否包含指定模式
查看 man bash 对 `=~` 操作符说明如下：
> An additional binary operator, =~, is available, with the same precedence as == and !=. When it is used, the string to the right of the operator is considered an extended regular expression and matched accordingly. The return value is 0 if the string matches the pattern, and 1 otherwise. If the regular expression is syntactically incorrect, the conditional expression's return value is 2. Any part of the pattern may be quoted to force the quoted portion to be matched as a string.

即，使用 `=~` 操作符时，其右边的字符串被认为是一个扩展正则表达式，扩展之后跟左边字符串进行比较，看左边字符串是否包含指定模式。注意是包含关系，不是完整匹配，也就是判断右边的模式是否为左边字符串的子字符串，而不是判断右边的模式是否完全等于左边字符串。

这里面提到一个非常关键的点，在所给的扩展正则表达式中，用双引号括起来的部分会被当成字符串，不再被当成正则表达式。如果 `=~` 操作符右边的字符串都用双引号括起来，那么表示匹配这个字符串自身的内容，不再解析成正则表达式。

如果想要 `=~` 操作符右边的字符串被当成正则表达式来处理，一定不要加双引号。这是常见的使用误区，后面会举例说明。

**注意**：只有 `[[` 命令支持 `=~` 操作符，`test` 命令和 `[` 命令都不支持 `=~` 操作符。

## 判断字符串是否全是数字
下面用 `=~` 操作符来判断一个字符串是否全是数字。假设有一个 `checkdigits.sh` 脚本，内容如下：
```bash
#!/bin/bash

function check_digits()
{
    local count=${#1}
    if [[ "$1" =~ [0-9]{$count} ]]; then
        echo "All digits."
    else
        echo "Not all digits."
    fi
}

check_digits "$1"
```
该脚本定义了一个 *check_digits* 函数，这个函数使用 `${#1}` 参数扩展表达式获取所传入第一个参数的字符串长度，并赋值给 *count* 变量。

在正则表达式中，`[0-9]` 表示匹配 0 到 9 之间的任意一个数字，但是只匹配一个数字，而 `[0-9]{n}` 表示匹配 n 个连续的数字。在 `[[ "$1" =~ [0-9]{$count} ]]` 表达式中，用 `=~` 操作符判断第一个参数值是否精确匹配 *count* 个连续的数字。如果是，就说明第一个参数对应的字符串全是数字，否则不全是数字。

执行 checkdigits.sh` 脚本的结果如下：
```bash
$ ./checkdigits.sh 12345
All digits.
$ ./checkdigits.sh abcd
Not all digits.
$ ./checkdigits.sh a2c
Not all digits.
$ ./checkdigits.sh 1b3
Not all digits.
```
可以看到，传入的参数全是数字时，才会打印 "All digits."。传入全字母、或者字母和数字的组合，能够正确判断到不全是数字，会打印 "Not all digits."。

由于 `=~` 操作符右边的参数是扩展正则表达式，如果不熟悉正则表达式的话，在使用时会遇到一些不预期的异常。下面举例说明判断字符串是否全是数字的一些错误写法，注意避免出现这类错误。
#### 错误写法一
假设有一个 `checkdigits_fake.sh` 脚本，内容如下：
```bash
#!/bin/bash

function check_digits()
{
    if [[ "$1" =~ [0-9] ]]; then
        echo "All digits."
    else
        echo "Not all digits."
    fi
}

check_digits "$1"
```
这个脚本在 `=~` 操作符右边提供的正则表达式是 `[0-9]`，对应 0 到 9 之间任意一个数字，但是只对应一个数字，那么 `[[ "$1" =~ [0-9] ]]` 是判断传入的第一个参数是否包含一个数字，只要有一个数字，就会返回为 true，它并不能判断出所有字符是否都是数字。具体执行结果如下：
```bash
$ ./checkdigits_fake.sh 12345
All digits.
$ ./checkdigits_fake.sh abcd
Not all digits.
$ ./checkdigits_fake.sh 1b3d
All digits.
$ ./checkdigits_fake.sh a2
All digits.
```
可以看到，只有当传入的参数全是字母时，才会打印 "Not all digits."。传入全数字、或者数字和字母的组合，都会打印 "All digits."。这个脚本不能准确地判断字符是否全是数字。

#### 错误写法二
把 `checkdigits_fake.sh` 脚本修改成下面的内容：
```bash
#!/bin/bash

function check_digits()
{
    if [[ "$1" =~ [0-9]* ]]; then
        echo "All digits."
    else
        echo "Not all digits."
    fi
}

check_digits "$1"
```
即，用 `[0-9]*` 来表示匹配零个或多个连续的数字。从字面上看像是可以匹配到全是数字的情况。但实际上，它还是会匹配一个数字的情况，只要有一个数字就会认为匹配，甚至还会匹配没有数字的情况。具体的执行结果如下：
```bash
$ ./checkdigits_fake.sh 12345
All digits.
$ ./checkdigits_fake.sh abcd
All digits.
$ ./checkdigits_fake.sh 1b3d
All digits.
$ ./checkdigits_fake.sh a2
All digits.
```
可以看到，无论传入的参数是全数字、全字母、还是数字和字母的组合，都是打印 "All digits."，都符合所给的 `[0-9]*` 这个模式，达不到判断字符串是否全是数字的效果。

类似的，`[0-9]+` 表示匹配一个或多个连续的数字，使用这个模式也不能判断字符串是否全是数字。

#### 错误写法三
前面提到，如果把 `=~` 操作符右边的字符串都用双引号括起来，那么表示匹配这个字符串自身的内容，不再解析成正则表达式。例如 `[0-9]` 在正则表达式中对应一个数字，但是 `"[0-9]"` 对应的是 "[0-9]" 这个字符串，不再对应一个数字。

虽然上面的 `[[ "$1" =~ [0-9]{$count} ]]` 表达式可以正确判断出字符串是否都是数字，一旦用双引号把 `[0-9]{$count}` 括起来，写成 `[[ "$1" =~ "[0-9]{$count}" ]]`，就会判断出错，可以自行修改 `checkdigits.sh` 脚本代码进行验证。下面用其他例子进行说明：
```bash
$ [[ "123" =~ [0-9]{3} ]]; echo $?
0
$ [[ "123" =~ "[0-9]{3}" ]]; echo $?
1
$ [[ "[0-9]{3}" =~ [0-9]{3} ]]; echo $?
1
$ [[ "[0-9]{3}" =~ "[0-9]{3}" ]]; echo $?
0
```
可以看到，`[[ "123" =~ [0-9]{3} ]]` 正确地判断出 "123" 字符串包含三个连续的数字，用 `echo $?` 打印命令返回值是 0，也就是 true。而 `[[ "123" =~ "[0-9]{3}" ]]` 命令的返回值是 1，对应 false，认为要比较的两个字符串不匹配。`"[0-9]{3}"` 此时不再表示匹配三个连续的数字，而是匹配 "[0-9]{3}" 这个字符串自身。

在 `[[ "[0-9]{3}" =~ [0-9]{3} ]]` 命令中，右边的 `[0-9]{3}` 没加双引号，按照正则表达式来解析，表示匹配三个连续的数字，而左边字符串并没有三个连续的数字，所以返回 1，不匹配。在 `[[ "[0-9]{3}" =~ "[0-9]{3}" ]]` 命令中，右边的 `"[0-9]{3}"` 加了双引号，不再当成正则表达式处理，只会比较字符串自身，所以返回 0，是匹配的。

在 bash 中，为了避免单词拆分导致不预期的行为，一般都会用双引号把字符串、或者变量值括起来，但是在使用 `=~` 操作符时，注意检查右边字符串是否要当成正则表达式来处理，如果是，不要加双引号。

## 判断某个字符串是否为另一个字符串的子字符串
我们可以使用 `=~` 操作来判断某个字符串是否为另一个字符串的子字符串，要判断的字符串要写在操作符右边，被判断的字符串要写在操作符的左边。假设有一个 `check_substr.sh` 脚本，内容如下：
```bash
#!/bin/bash

function check_substr()
{
    if [[ "$1" =~ "$2" ]]; then
        echo \"$1\" contains \"$2\"
    else
        echo \"$1\" does not contain \"$2\"
    fi
}

check_substr "$1" "$2"
```
这个脚本判断传入的第二个参数是否为第一个参数的子字符串。具体执行结果如下：
```bash
$ ./check_substr.sh "This is a test string"  "test string"
"This is a test string" contains "test string"
$ ./check_substr.sh "This is a test string"  "is a test"
"This is a test string" contains "is a test"
$ ./check_substr.sh "This is a test string"  "isa test"
"This is a test string" does not contain "isa test"
$ ./check_substr.sh "This is a test string"  "new string"
"This is a test string" does not contain "new string"
```
测试的时候，如果传入的字符串参数包含空格，要用双引号括起来。注意 `=~` 右边的 `"$2"` 加了双引号，不再当成正则表达式处理，只会比较字符串自身的内容。

# 详解 bash 的 test、[、[[ 命令判断字符串是否为空
在 bash 中，`test` 命令、`[` 命令、`[[` 命令都可以用于进行一些判断，例如判断字符串是否为空。这几个命令的用法有一些异同和一些注意事项，具体说明如下。

## test 命令 和 [ 命令的关系
在 bash 中，`[` 关键字本身是一个命令，它不是 `if` 命令的一部分。执行 `help [` 命令，有如下说明：
> **[: [ arg... ]**  
Evaluate conditional expression.  
This is a synonym for the "test" builtin, but the last argument must be a literal `]`, to match the opening `[`.

即，`[` 命令是 `test` 命令的同义词，它对条件表达式的判断结果和 `test` 命令完全一样。但是 `[` 命令要求该命令的最后一个参数必须是 `]`，看起来是闭合的方括号效果。

在实际使用中，`test` 命令 和 `[` 命令常常跟 `if` 命令、`while` 命令结合使用，但这并不是必须的，`test` 命令 和 `[` 命令本身是独立的，可以单独执行。

后面会统一用 `test` 命令来说明它的用法，这些说明都适用于 `[` 命令。

**注意**：`]` 自身不是 bash 的命令，它只是 `[` 命令要求的参数，且必须是最后一个参数。

**注意**：在使用 `[` 命令时，最大的误区是在这个命令之后没有加空格。例如 `[string1 != string2]` 这种写法是错误的。要时刻注意 `[` 本身是一个命令，这个命令名就是 `[`，在这个命令之后会跟着一些参数，要用空格把命令名和参数隔开。`[string1` 这个写法实际上会执行名为 `[string1` 的命令，不是执行 `[` 命令。类似的，`]` 本身是一个参数，它也要用空格来隔开其他参数，`string2]` 这个写法实际上是一个名为 "string2]" 的参数，而不是 `string2` 和 `]` 两个参数。

## 用 test 命令判断字符串是否为空
执行 `help test` 命令，有如下说明：
```bash
test: test [expr]
    Evaluate conditional expression.
    Exits with a status of 0 (true) or 1 (false) depending on
    the evaluation of EXPR.

    The behavior of test depends on the number of arguments.
    Read the  bash manual page for the complete specification.

    String operators:
      -z STRING      True if string is empty.

      -n STRING
         STRING      True if string is not empty.
```
即，`test` 命令使用 `-z STRING` 操作符来判断 *STRING* 字符串的长度是否为 0，如果为 0，就是空字符串，会返回 true。具体写法是 `test -z STRING`，使用 `[` 命令则写为 `[ -z STRING ]`。

`-n STRING` 操作符判断 *STRING* 字符串的长度是否为 0，如果不为 0，就不是空字符串，会返回 true。具体写法是 `test -n STRING`，使用 `[` 命令则写为 `[ -n STRING ]`。可以省略 `-n` 操作符，直接写为 `test STRING`、或者 `[ STRING ]`。

**注意**：在实际使用时，要注意下面几点：
- 当判断变量值对应的字符串是否为空时，一定要用双引号把变量值括起来，否则变量值为空、或者带有空格时，会返回异常的结果。例如，要写为 `test -n "$string"`，不建议写为 `test -n $string`。
- bash 是以 0 作为 true，以 1 作为 false，上面 `test` 命令的说明也是如此。而大部分编程语言是以 1 作为 true，0 作为 false，要注意区分，避免搞错判断条件的执行关系。
- 上面 `help test` 的说明提到，test 命令的参数个数会影响它的行为，具体要参考 man bash 的说明。不同的参数个数会导致 `test` 命令返回很多不预期的结果，这是非常关键的点，后面会具体说明。

下面用一个 `empty_string.sh` 脚本来举例说明 `test` 命令和 `[` 命令判断字符串是否为空的方法，其内容如下：
```bash
#!/bin/bash

function empty_string()
{
    if test -n $1; then
        echo '(1) -n $1  :' "No quote: not empty."
    fi

    if [ -z $1 ]; then
        echo '(2) -z $1  :' "No quote: empty."
    fi

    if test -n "$1"; then
        echo '(3) -n "$1":' "Quote   : not empty."
    fi

    if [ -z "$1" ]; then
        echo '(4) -z "$1":' "Quote   : empty."
    fi
}

empty_string "$1"
```
这个脚本使用 `test` 命令的 `-n`、`-z` 操作符来判断传入脚本的第一个参数是否为空字符串，并对比加双引号和不加双引号把变量值括起来的测试结果。具体执行结果如下：
```bash
$ ./empty_string.sh go
(1) -n $1  : No quote: not empty.
(3) -n "$1": Quote   : not empty.
$ ./empty_string.sh "go on"
./empty_string.sh: line 5: test: go: binary operator expected
./empty_string.sh: line 9: [: go: binary operator expected
(3) -n "$1": Quote   : not empty.
$ ./empty_string.sh
(1) -n $1  : No quote: not empty.
(2) -z $1  : No quote: empty.
(4) -z "$1": Quote   : empty.
```
可以看到，执行 `./empty_string.sh go` 命令，传入的第一个参数值没有包含空格，`$1` 变量值加不加双引号的判断结果都正确。

执行 `./empty_string.sh "go on"` 命令，传入的第一个参数值包含空格，`$1` 变量值不加双引号的语句执行报错，提示 "binary operator expected"，`test` 命令在 `-n`、`-z` 操作符后面预期只有一个参数，而 `test -n $1` 扩展为 `test -n test string`，在 `-n` 后面提供了两个参数，加上 `-n` 总共是三个参数，执行报错。使用双引号把 `$1` 变量值括起来，整个变量值就会被当成一个参数，执行 `test -n "$1"` 命令不会报错。

执行 `./empty_string.sh` 命令，没有提供第一个参数，测试结果比较奇怪，`-n $1` 认为 `$1` 不为空，而 `-z $1` 又认为 `$1` 为空，只有 `-z "$1"` 正确地判断出第一个参数值为空。原因在于，没有提供第一个参数时，`$1` 的值是空，相当于什么都没有，`test -n $1` 语句经过 bash 处理后，得到的是 `test -n`，`[ -z $1 ]` 语句经过 bash 处理后，得到的是 `[ -z ]`，相当于 `test -z`。`test -n` 和 `test -z` 的返回结果都是 true，所以才打印出来 `$1` 即为空，又不为空，判断结果不符合预期。

可以再次看到，`-z "$1"` 用双引号把变量值括起来，得到了预期的判断结果。添加双引号可以避免很多异常的现象。使用 `bash -x ./empty_string.sh` 打印执行脚本时的调试信息，可以看到 `[ -z $1 ]` 和 `[ -z "$1" ]` 扩展结果的区别：
```bash
$ bash -x ./empty_string.sh
+ empty_string ''
+ test -n
+ echo '(1) -n $1  :' 'No quote: not empty.'
(1) -n $1  : No quote: not empty.
+ '[' -z ']'
+ echo '(2) -z $1  :' 'No quote: empty.'
(2) -z $1  : No quote: empty.
+ test -n ''
+ '[' -z '' ']'
+ echo '(4) -z "$1":' 'Quote   : empty.'
(4) -z "$1": Quote   : empty.
```
结合上面的代码，可以看到 `[ -z $1 ]` 扩展得到的调试信息是 `'[' -z ']'`，在 `-z` 后面没有任何参数。而 `[ -z "$1" ]` 扩展得到的结果是 `'[' -z '' ']'`，在 `-z` 后有一个参数 `''`，这个参数的值是空字符串。

## test 命令的参数个数影响判断结果
上面提到，`test` 命令的参数个数会影响判断结果，具体可以查看 man bash 的说明，部分关键信息如下：
```bash
test and [ evaluate conditional expressions using a set of rules
based on the number of arguments.

0 arguments
    The expression is false.
1 argument
    The expression is true if and only if the argument is not null.
2 arguments
    If the first argument is !, the expression is true if and only if
    the second argument is null. If the first argument is one of the
    unary conditional operators listed above under CONDITIONAL EXPRESSIONS,
    the expression is true if the unary test is true. If the first argument
    is not a valid unary conditional operator, the expression is false.
3 arguments
    The following conditions are applied in the order listed. If the second
    argument is one of the binary conditional operators listed above under
    CONDITIONAL EXPRESSIONS, the result of the expression is the result of
    the binary test using the first and third arguments as operands. If the
    first argument is !, the value is thenegation of the two-argument test
    using the second and third arguments.
```
针对不同的参数个数，具体举例说明如下：
- 0 arguments
```bash
$ test; echo $?
1
```
执行 `test` 命令，不提供任何参数，参考上面 "0 arguments" 的说明，这种情况下的返回值总是 false，用 `echo $?` 打印返回值为 1。注意 `test` 命令把 1 作为 false。

- 1 argument
```bash
$ test -n; echo $?
0
$ test -z; echo $?
0
$ test -y; echo $?
0
$ set -x
$ test ""; echo $?;
+ test ''
+ echo 1
1
$ test $dummy; echo $?
+ test
+ echo 1
1
$ set +x
```
上面例子提到，执行 `test -n` 和 `test -z` 的返回结果都是 true。这里单独执行这两个命令，用 `echo $?` 打印返回值为 0，确实是返回 true。注意 `test` 命令把 0 作为 true。参考上面 "1 argument" 的说明，只提供一个参数时，只要该参数不为空，就会返回 true。此时的 `-n` 和 `-z` 被当作普通的字符串参数，没被当作 `test` 命令的操作符，可以看到执行 `test -y` 也是返回 true，但是 `test` 命令并不支持 `-y` 操作符。

上面的 help test 说明提到，`test STRING` 命令在 *STRING* 不为空时会返回 true，使用的就是只提供一个参数时的判断规则。

注意区分上面 `test ""` 和 `test $dummy` 的区别。查看上面打印的调试信息，`test ""` 经过 bash 扩展，得到的结果是 `test ''`，也就是确实有一个参数，这个参数是空字符串，按照 "1 argument" 的说明，此时返回结果是 false。由于没有定义 *dummy* 变量，`test $dummy` 经过 bash 扩展，得到的结果只有 `test`，没有提供参数，按照 "0 arguments" 的说明，返回值为 false。即，虽然 `test ""` 和 `test $dummy` 都返回 false，但是它们的参数个数不同，得出结果的原因也不同。

- 2 arguments
```bash
$ test -y go; echo $?
-bash: test: -y: unary operator expected
2
$ test -n go; echo $?
0
$ value=""; set -x
$ test ! -n $value; echo $?
+ test '!' -n
+ echo 1
1
$ test ! -n "$value"; echo $?
+ test '!' -n ''
+ echo 0
0
$ set +x
```
参考上面 "2 arguments" 的说明，提供两个参数时，如果第一个参数不是 *unary conditional operator*，返回结果是 false。由于 `test` 命令不支持 `-y` 操作符，执行 `test -y go` 命令报错。执行 `test -n go` 命令则会返回 `-n` 操作符对后面参数的判断结果。

注意区分上面 `test ! -n $value` 和 `test ! -n "$value"` 的区别。上面将 *value* 变量设成空字符串，`test ! -n $value` 经过 bash 扩展，得到的结果是 `test '!' -n`，提供了两个参数，按照 "2 arguments" 的说明，当第一个参数是 `!` 时，只有第二个参数是空，才会返回 true，这里的第二个参数不是空，所以返回 false。而 `test ! -n "$value"` 扩展后的结果是 `test '!' -n ''`，提供了三个参数，按照 "3 arguments" 说明的规则来进行判断，会对后面两个参数的判断结果进行取反，这里最终返回 true。

- 3 arguments
```bash
$ test -n go on
-bash: test: go: binary operator expected
```
这是上面提到的一个例子，在 `test -n` 后面的字符串包含空格，又没有用双引号把字符串括起来，那么参数个数会变多，这里是三个参数，`-n` 也是一个参数，参考上面 "3 arguments" 的说明，提供三个参数时，预期第二个参数是 *binary conditional operators*，由于没有提供，执行报错，提示 "go: binary operator expected"，也就是所给的第二个参数 "go" 预期是一个 "binary operator"，但它不是。

总的来说，不加双引号来引用变量值，当参数值为空、或者包含空格时，会导致 `test` 命令的参数个数发生变化，按照不同参数个数的判断规则进行处理，导致不预期的结果。结合上面几个例子可以看到，用双引号把变量值括起来，只会得到一个参数，保持参数个数不变，可以避免很多异常。

## 用 [[ 命令判断字符串是否为空
查看 help [[ 对 `[[` 命令说明如下：
```bash 
[[ ... ]]: [[ expression ]]
    Execute conditional command.

Returns a status of 0 or 1 depending on the evaluation of the conditional
expression EXPRESSION. Expressions are composed of the same primaries used
by the 'test' builtin, and may be combined using the following operators:
    ( EXPRESSION )    Returns the value of EXPRESSION
    ! EXPRESSION      True if EXPRESSION is false; else false
    EXPR1 && EXPR2    True if both EXPR1 and EXPR2 are true; else false
    EXPR1 || EXPR2    True if either EXPR1 or EXPR2 is true; else false
```
即，`[[` 命令可以使用 `test` 命令的操作符来进行判断。它们之间的一些区别说明如下：
- 上面提到，`[` 命令要求最后一个参数必须是 `]`，`]` 本身不是一个命令。类似的，`[[` 命令也要求跟 `]]` 同时出现，但是 `]]` 本身也是一个命令，而不是一个参数。所以 `[[ expression ]]` 被称为复合命令 (compound command)。如下面例子所示：
```bash
$ ]
]: command not found
$ ]]
-bash: syntax error near unexpected token `]]'
```
可以看到，试图执行 `]` 命令，提示命令没有找到，说明没有这个命令。而执行 `]]` 命令，没有提示找不到命令，只是提示语法错误，预期在该命令之前要有 `[[` 命令。

由于 `[[` 和 `]]` 都是命令，需要用空格把它们和其他参数隔开。
- 查看 man bash 里面对 `[[` 有如下说明：
> Word splitting and pathname expansion are not performed on the words between the [[ and ]]; tilde expansion, parameter and variable expansion, arithmetic expansion, command substitution, process substitution, and quote removal are performed.

即，在 `[[` 和 `]]` 里面引用变量值时，不会对变量值进行单词拆分 (Word splitting)，即使变量值带有空格，不用双引号括起来也不会被拆分成多个参数。而 `test` 命令 和 `[` 命令会进行单词拆分，可能会导致参数个数发生变化，可以参考前面几个例子的说明。

使用 `[[` 判断字符串是否为空的一些例子如下所示：
```bash
$ value=
$ [[ -n $value ]]; echo $?
1
$ [[ -z $value ]]; echo $?
0
$ value="go on"
$ [[ -n $value ]]; echo $?
0
$ [[ -n go on ]]; echo $?
-bash: syntax error in conditional expression
-bash: syntax error near 'on'
```
可以看到，将 *value* 变量值设成空，`[[ -n $value ]]` 返回为 1，确认该变量值不为空是 false。`[[ -z $value ]]` 返回为 0，确认该变量值为空是 true，虽然 `$value` 不加双引号，也能正确判断。如果是用 `[` 命令就会判断异常。

当 *value* 变量值包含空格时，`[[ -n $value ]]` 可以正确判断，但是如果直接写为 `[[ -n go on ]]` 会执行报错。
