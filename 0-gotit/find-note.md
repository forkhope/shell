# 描述 find 命令的使用

在 Linux 命令中，`find` 是比较复杂难用的命令。使用该命令搜索文件时，常常会发现找了一些例子能用，但自己稍微修改一些条件，就搜不到想要的结果。下面会以一些实例来说明使用 `find` 命令时的关键要点和注意事项，解释清楚各个条件能够工作、或者不能工作的原因。

# find 命令格式
要使用一个命令，首先要了解命令的格式，知道要提供什么参数、参数作用是什么。查看 man find 对该命令的说明如下：
- find - search for files in a directory hierarchy  
find [-H] [-L] [-P] [-D debugopts] [-Olevel] [path...] [expression]
- GNU find searches the directory tree rooted at each given file name by evaluating the given expression from left to right, according to the rules of precedence, until the outcome is known (the left hand side is false for and operations, true for or), at which point find moves on to the next file name.
- The -H, -L and -P options control the treatment of symbolic links. Command-line arguments following these are taken to be names of files or directories to be examined, up to the first argument that begins with `-`, or the argument `(` or `!`.
- If no paths are given, the current directory is used. If no expression is given, the expression -print is used (but you should probably consider using -print0 instead, anyway).
- The expression is made up of options (which affect overall operation rather than the processing of a specific file, and always return true), tests (which return a true or false value), and actions (which have side effects and return a true or false value), all separated by operators.  -and is assumed where the operator is omitted.
- If the expression contains no actions other than -prune, -print is performed on all files for which the expression is true.

即，`find` 命令的作用是在目录层次结构下搜索文件，默认会递归搜索所给目录的子目录，对查找到的每一个文件名（目录名也属于文件名）依次进行后面表达式的判断，来决定是否打印搜索到的文件名、或者进行其他的操作。

**注意**：对每一个搜索到的文件名都依次进行表达式评估是非常关键的点，`find` 命令会把搜索到的每一个文件名都依次作为参数传递给后面的表达式进行评估，来决定如何处理这个文件，某个文件的表达式评估为 false，还是会继续评估下一个文件，除非主动执行了结束的操作。理解这一点，就会清楚为什么有些文件名会打印出来，而有些文件名不会打印出来，因为它们本身就相互不关联。

下面具体说明 `find` 命令格式各个部分的含义：
- `[-H] [-L] [-P] [-D debugopts] [-Olevel]` 这部分属于命令选项，比较少用到，这里不做说明。
- `[path...]` 该参数指定要查找哪个目录，可以同时提供多个目录名，用空格隔开，如果没有提供该参数，默认查找当前目录、及其子目录。也可以提供文件名，只会在当前目录下查找该文件，不在子目录中查找。
- `[expression]` 该参数指定评估表达式，可以提供多个表达式，不同表达式之间要用 *operator* 操作符来分割开，如果表达式之间没有提供操作符，默认会用 -and 操作符。表达式有 *options*、*tests*、*actions* 三种类型。如果不提供该参数，默认使用 `-print` 表达式，也就是打印出所给的文件名。参考上面说明，表达式参数要求以 `-`、`(`、或者 `!` 开头，以便区分开前面的目录参数。

关于 `find` 命令的说明，也可以查看 GNU find 的在线帮助手册 <https://www.gnu.org/software/findutils/manual/html_mono/find.html>，这里面的说明比 man find 详细，并提供了不少例子，可供参考。

在 Linux 中，目录也属于文件，`find` 在查找时，把目录也当成文件处理，会查找并处理目录名，并不是只处理文件名。后面在说明时，如无特别备注，所说的文件名包含了目录名。

# 查找指定目录下的所有文件
`find` 命令最简单的用法就是直接执行这个命令，不提供任何参数，默认会查找当前目录、及其子目录下的所有文件，并打印出所有文件名。举例如下：
```bash
$ ls
Makefile.am  src  tests
$ find
.
./src
./src/main.c
./tests
./tests/bre.tests
./Makefile.am
```
可以看到，在 shell 的当前工作目录下执行 `find` 命令，不提供任何参数，会打印出当前目录、及其子目录下的所有文件名，包括了目录名。

可以在 `find` 命令后面提供目录名，指定要查找哪个目录：
```bash
$ find .
.
./src
./src/main.c
./tests
./tests/bre.tests
./Makefile.am
$ find src
src
src/main.c
$ find src tests
src
src/main.c
tests
tests/bre.tests
```
在 Linux 下，点号 `.` 对应当前目录，所以 `find .` 就是查找当前目录下的所有文件，当没有提供目录参数时，默认就是使用 `.` 这个参数。`find src` 命令指定只查找 *src* 这个目录下的所有文件。`find src tests` 命令指定查找 *src*、*tests* 这两个目录下的所有文件，可以同时提供多个目录名来指定查找这些目录。`find src tests` 命令也可以写为 `find ./src ./tests`。

如果在 `find` 命令后面提供文件名，则只在当前目录下查找该文件，不会在子目录下查找：
```bash
$ find Makefile.am
Makefile.am
$ find main.c
find: `main.c': No such file or directory
```
结合上面打印的文件信息，可以看到当前目录下有一个 `Makefile.am` 文件，`find Makefile.am` 命令可以找到这个文件，不会报错。而 *main.c* 文件是在 *src* 子目录下，`find main.c` 命令执行报错，提示找不到这个文件，它不会进入 *src* 子目录进行查找。

**注意**：前面提到，查找条件要求以 `-`、`(`、或者 `!` 开头，在遇到以这几个字符开头的任意参数之前，前面的参数都会被当作目录参数，指定查找多个目录时，直接在 `find` 命令后面写上这些目录的路径，用空格隔开即可，不用加上 -o、-path 等选项，加上反而有异常。

刚接触 `find` 命令，常见的误区之一就是认为要用 `-o` 选项来指定查找多个目录，例如认为 `find src -o tests` 是同时查找 *src*、*tests* 这两个目录，这是错误的写法，执行会报错：
```bash
$ find src -o tests
find: paths must precede expression: tests
```
可以看到，执行报错，提示目录路径参数必须在表达式参数之前提供。`-o` 参数以 `-` 开头，会被认为是表达式参数，它自身、以及在它之后的所有参数都会认为是表达式参数，之后提供的目录名不会被当作要查找的目录。某些表达式参数的后面可以提供目录名，但是这些目录名并不是用于指定查找该目录下的文件，而是另有含义。

另一个误区是，执行 `find src -o tests` 命令报错后还不知道错在哪里，望文生义，又加上 `-path` 选项，误写为 `find src -o -path tests`、或者 `find src -path -o tests`，这两个命令都会报错，自行测试即知。

虽然写为 `find src -path tests` 不会报错，但是它并不会打印出 *src*、*tests* 这两个目录下的文件名。后面会具体说明 `-path` 参数的用法。

# 查找时指定忽略一个或多个目录
基于上面例子的目录结构，如果想查找当前目录下的文件，且忽略 *tests* 目录，可以执行下面的命令：
```bash
$ find . -path ./tests -prune -o -print
.
./src
./src/main.c
./Makefile.am
```
可以看到，打印的文件名里面没有 *tests* 目录名、以及它底下的文件名。但是如果把上面 `-path` 后面的 `./tests` 改成 `tests`，还是会查找 *tests* 目录下的文件：
```bash
$ find . -path tests -prune -o -print
.
./src
./src/main.c
./tests
./tests/bre.tests
./Makefile.am
```
这个结果比较奇怪，查找时想要忽略 *tests* 目录，写为 `-path ./tests` 可以忽略，写为 `-path tests` 就不能忽略。这是使用 `find` 命令的 `-path` 参数时常见的错误，别人的例子可以生效，自己写的时候就不生效，需要理解 `-path` 参数的含义才能正确使用它。

前面提到，不同的表达式之间要用操作符分隔开，如果没有提供操作符，默认使用 `-and` 操作符。所以 `find . -path ./tests -prune -o -print` 命令的完整格式其实是 `find . -path ./tests -and -prune -o -print`，下面对这个完整命令格式的各个参数进行详细说明，以便理解它的工作原理，就能知道为什么写为 `-path ./tests` 可以忽略，写为 `-path tests` 不能忽略。

## -path pattern
这是一个 *test* 类型表达式，GNU find 在线帮助手册对该表达式的说明如下：
> **Test: -path pattern**  
True if the entire file name, starting with the command line argument under which the file was found, matches shell pattern pattern. To ignore a whole directory tree, use ‘-prune’ rather than checking every file in the tree. The “entire file name” as used by find starts with the starting-point specified on the command line, and is not converted to an absolute pathname.

即，当 `find` 命令查找到的文件名完全匹配所给的 *pattern* 模式时，该表达式返回 true。这里面最关键的点是要完全匹配 `find` 命令查找到的名称，而不是部分匹配，也不是匹配文件的绝对路径名，举例说明如下：
```bash
$ find . -path ./tests
./tests
$ find . -path tests
$ find . -path ./tests/
$ find tests
tests
tests/bre.tests
$ find tests -path tests
tests
$ find tests -path ./tests
```
可以看到，`find . -path ./tests` 命令打印了 `./tests` 目录名，但是 `find . -path tests` 命令什么都没有打印。查看上面 `find .` 命令打印的信息，可以看到该命令打印的 *tests* 目录名是 `./tests`，`-path` 参数要求是完全匹配才会返回 true，所以基于打印结果，就是要写为 `-path ./tests` 才会返回 true。前面贴出的 man find 说明提到，没有提供除了 `-prune` 表达式之外的其他 *action* 类型表达式时，默认会对所有返回 true 的文件名执行 `-print` 表达式，打印该文件名，所以打印结果里面只有匹配到的 `./tests` 目录名，那些没有完全匹配 `./tests` 的文件名会返回 false，没有被打印。

由于 `find .` 命令打印的目录名后面没有加上 `/` 字符，所以 `find . -path ./tests/` 也匹配不到任何文件名，没有打印任何信息。

类似的，执行 `find tests` 命令，打印的 *tests* 目录名是 `tests`，那么 `find tests -path tests` 命令可以完全匹配 `tests` 模式，打印出这个目录名，而 `find tests -path ./tests` 就匹配不到，没有打印。即，根据传入的目录参数不同，`find` 打印的目录名不同，`-path` 后面要提供的目录名也不同。

**总的来说，在 `-path` 后面跟着的目录名，需要完全匹配 `find` 命令打印的目录名，而不是部分匹配。如果不确定 `find` 命令打印的目录名是什么，可以先不加 `-path` 参数执行一次 `find` 命令，看打印的文件名是什么，再把对应的文件名写到 `-path` 参数后面**。

在 `-path` 后面的 *pattern* 模式可以用通配符匹配特定模式的文件名，常见的通配符是用 `*` 来匹配零个或多个字符。在 `find` 中使用时有一些需要注意的地方，举例说明如下：
```bash
$ find . -path *test*
$ find . -path ./test*
./tests
$ find . -path \*test\*
./tests
./tests/bre.tests
$ find . -path "*test*"
./tests
./tests/bre.tests
```
可以看到，`find . -path *test*` 什么都没有打印，`*test*` 没有匹配到 `./tests` 这个名称，原因是这里的 `*` 通配符是由 bash 来处理，通过文件名扩展来得到当前目录下的子目录名或者文件名，但是不会在目录名前面加上 `./`。即，这里的 `find . -path *test*` 相当于 `find . -path tests`，前面已经说明这是不匹配的。

`find . -path ./test*` 可以打印出匹配到的目录名，经过 bash 扩展后，这个命令相当于 `find . -path ./tests`。

`find . -path \*test\*` 命令不但匹配到了 `./tests` 目录，还匹配到了该目录下的 `./tests/bre.tests` 文件。这里用 `\*` 对 `*` 进行转义，对 bash 来说它不再是通配符，不做扩展处理，而是把 `*` 这个字符传递给 `find` 命令，由 `find` 命令自身进行通配符处理，可以匹配到更多的文件。

这里面涉及到 bash 和 find 对 `*` 通配符扩展的区别，bash 在文件名扩展 `*` 时，遇到斜线字符 `/` 则停止，不会扩展到目录底下的文件名。而 find 没有把 `/` 当成特殊字符，会继续扩展到目录底下的文件名。查看 GNU find 在线帮助手册 <https://www.gnu.org/software/findutils/manual/html_mono/find.html#Shell-Pattern-Matching> 的说明如下：
> Slash characters have no special significance in the shell pattern matching that find and locate do, unlike in the shell, in which wildcards do not match them.

`find . -path "*test*"` 命令的打印结果跟 `find . -path \*test\*` 相同。原因是，bash 没有把双引号内的 `*` 当成通配符，会传递这个字符给 find，由 find 来处理通配符扩展。如果不想用 `\*` 来转义，可以用双引号把模式字符串括起来。

**注意**：虽然 `-path` 表达式的名字看起来是对应目录路径，但是也能用于匹配文件名，并不只限于目录。在 man find 里面提到，有一个 `-wholename` 表达式和 `-path` 表达式是等效的，但是只有 GNU find 命令支持 `-wholename` 表达式，其他版本的 find 命令不支持该表达式。从名字上来说，`-wholename` 表达式比较准确地表达出要完全匹配文件名称。

## -and
这是一个 *operator* 操作符，GNU find 在线帮助手册对该操作符的说明如下：
> **expr1 expr2**  
**expr1 -a expr2**  
**expr1 -and expr2**  
And; expr2 is not evaluated if expr1 is false.

可以看到，`-and` 操作符有三个不同的写法，都是等效的。`find` 命令的操作符把多个表达式组合到一起，成为一个新的组合表达式，组合表达式也会有自身的返回值，使用 `-and` 操作符组合的表达式要求两个表达式都是 true，该组合表达式才是 true。左边的 *expr1* 表达式为 false 时，不再评估右边的 *expr2* 表达式，该组合表达式会返回 false。

上面例子的 `find . -path tests` 命令什么都没有打印，就跟 `-and` 操作符的特性有关。由于该命令没有提供 *action* 类型表达式，默认会加上 `-print` 表达式，也就是 `find . -path tests -print`。由于在 `-path tests` 和 `-print` 之间没有提供操作符，默认会加上 `-and` 操作符，也就是 `find . -path tests -and -print`。

而 `find .` 命令搜索到的所有文件名都不匹配 `-path tests` 模式，都返回 false，基于 `-and` 操作符的特性，不往下执行 `-print` 表达式，也就不会打印任何文件名。

## -prune
这是一个 *action* 类型表达式，GNU find 在线帮助手册对该表达式的说明如下：
> **Action: -prune**  
If the file is a directory, do not descend into it. The result is true. For example, to skip the directory src/emacs and all files and directories under it, and print the names of the other files found:  
`find . -wholename './src/emacs' -prune -o -print`  
The above command will not print ./src/emacs among its list of results. This however is not due to the effect of the ‘-prune’ action (which only prevents further descent, it doesn’t make sure we ignore that item). Instead, this effect is due to the use of ‘-o’. Since the left hand side of the “or” condition has succeeded for ./src/emacs, it is not necessary to evaluate the right-hand-side (‘-print’) at all for this particular file.

这里举的例子就类似于我们现在讨论的例子，里面也解释了查找时能够忽略目录的原因，可供参考。

前面提到，`find` 命令会把搜索到的每一个文件名都依次作为参数传递给后面的表达式进行评估，如果传递到`-prune` 表达式的文件名是一个目录，那么不会进入该目录进行查找。这个表达式的返回值总是 true。举例说明如下：
```bash
$ find . -path \*test\* -prune
./tests
$ find . -path \*test\* -o -prune
.
```
前面例子提到，`find . -path \*test\*` 会匹配到 `./tests` 目录和该目录下的 `./tests/bre.tests` 文件。而这里的 `find . -path \*test\* -prune` 只匹配到 `./tests` 目录，没有进入该目录下进行查找，就是受到了 `-prune` 表达式的影响。

基于前面的说明，`find . -path \*test\* -prune` 相当于 `find . -path \*test\* -and -prune -and print`。对于不匹配 `\*test\*` 模式的文件名，`-path \*test\*` 表达式返回 false，不往下处理，不打印不匹配的文件名。对于匹配 `\*test\*` 模式的文件名，`-path \*test\*` 表达式返回 true，会往下处理，遇到 `-prune` 表达式，该表达式总是返回 true，继续往下处理 `-print` 表达式，打印出该目录名，由于 `-prune` 表达式指定不进入对应的目录，所以没有查找该目录下的文件，没有查找到 `./tests/bre.tests` 文件。

## -o
这是一个 *operator* 操作符，GNU find 在线帮助手册对该操作符的说明如下：
> **expr1 -o expr2**  
**expr1 -or expr2**  
Or; expr2 is not evaluated if expr1 is true.

使用 `-o` 操作符组合的表达式要求两个表达式都是 false，该组合表达式才是 false。左边的 *expr1* 表达式为 true 时，不再评估右边的 *expr2* 表达式，该组合表达式会返回 true。

前面提到， `find . -path tests` 命令什么都没有打印，跟使用了 `-and` 操作符有关，如果改成 `-o` 操作符，结果就会不一样，举例如下：
```bash
$ find . -path tests -o -print
.
./src
./src/main.c
./tests
./tests/bre.tests
./Makefile.am
$ find . -path ./tests -o -print
.
./src
./src/main.c
./tests/bre.tests
./Makefile.am
```
可以看到，`find . -path tests -o -print` 命令打印了当前目录下的所有文件名。由于 `-path tests` 什么都匹配不到，都返回 false，基于 `-o` 操作符的特性，全都执行后面的 `-print` 表达式，打印所有文件名。这个结果跟 `find . -path tests` 命令完全相反。

类似的，`find . -path ./tests -o -print` 命令的打印结果跟 `find . -path ./tests` 命令也相反。前者的打印结果不包含 `./tests` 目录名，后者的打印结果只包含 `./tests` 目录名。对于匹配 `-path ./tests` 模式的目录名，该表达式返回 true，基于 `-o` 操作符的特性，不往下执行 `-print` 表达式，所以不打印该目录名。

## -print
这是一个 *action* 类型表达式，GNU find 在线帮助手册对该表达式的说明如下：
> **Action: -print**  
True; print the entire file name on the standard output, followed by a newline.

前面例子已经说明过 `-print` 表达式的作用，它会打印传递下来的完整文件路径名，会自动添加换行符。

如果没有提供除了 `-prune` 之外的其他 *action* 类型表达式，`find` 默认会加上 `-print` 表达式，并用 `-and` 来连接前面的表达式。这个行为可能会带来一些误解，认为 `find` 命令总是会打印搜索到、或者匹配到的文件名，但有时候搜索到、或者匹配到的文件名反而不打印，例如上面 `find . -path ./tests -o -print` 的例子。

要消除这个误解，就一定要清楚地认识到，`find` 命令想要打印文件名，就必须执行到 `-print` 表达式、或者其他可以打印文件名的表达式。即，要执行可以打印文件名的表达式才会打印文件名，否则不会打印。至于是匹配特定模式的文件名才会打印，还是不匹配特定模式的文件名才会打印，取决于各个表达式、包括操作符组合表达式的判断结果，看是否会执行到可以打印文件名的表达式。

## 总结
结合上面的说明，对 `find . -path ./tests -and -prune -o -print` 命令在查找时能够忽略 `./tests` 目录底下文件的原因总结如下：
- `find .` 指定查找当前目录、及其子目录下的所有文件，每查找到一个文件名，就把这个文件名传递到后面的表达式进行评估，进行相应处理。
- `-path ./tests` 指定传递下来的文件名要完全匹配 `./tests` 这个字符串。对于不匹配的文件名，该表达式返回 false，那么 `-path ./tests -and -prune` 这个组合表达式会返回 false，且没有评估后面的 `-prune` 表达式。由于 `-and` 操作符优先级高于 `-o` 操作符，该组合表达式再跟后面的 `-o -print` 形成新的组合表达式，它返回 false，会往下执行 `-print` 表达式，从而打印出来不匹配的文件名。
- 对于匹配 `-path ./tests` 模式的目录名，该表达式返回 true，`-path ./tests -and -prune` 组合表达式会评估后面的 `-prune` 表达式，指定不进入匹配的目录名查找底下的文件，这个例子里面就是不进入 `./tests` 目录，所以查找时会忽略该目录底下的文件，但还是会查找到 `./tests` 目录名自身。
- 对于 `./tests` 这个目录名，由于 `-prune` 返回 true，`-path ./tests -and -prune` 组合表达式会返回 true，基于 `-o` 操作符的特性，不执行后面的 `-print` 表达式，所以没有打印这个目录名。
- 基于这几条分析，这个命令最终打印的结果里面，即不包含 `./tests` 这个目录名，也不包含它底下的文件名。

总的来说，使用 `find` 命令查找时，如果要忽略一个目录，可以用类似 `find . -path ./tests -prune -o -print` 这样的写法，理解了上面对该命令的解释后，想要忽略其他模式的目录，应该就比较容易了。

## TODO: 忽略多个目录的写法
find . \( -path "./test" -o -path "./out" \) -prune

# TODO: fix this backup
一. 操作运算符
(1) expr1 -o expr2
    Or; expr2 is not evaluated if expr1 is true. 即这是一个或操作.

二. 查找时跳过一个或多个目录
find命令可以使用-path pattern -prune来忽略一个或多个目录.例如:
(1)find . -path ./test -prune 将会忽略当前目录的test目录.
(2)find . \( -path "./test" -o -path "./out" \) -prune 将忽略当前目录下
的test目录和out目录. 注意,在"\("和"-path"之间一定要有空格,否则会报错.
(3)这个-path选项需要指定具体的路径,而不是递归忽略,例如存在 ./a/test/a/,
./b/test/b, ./c/test/c 三个目录,如果想要全部忽略test目录,只写为-path ./test
是不行的,只能使用正则表达式进行模糊匹配,例如-path "*test".

三. 查找指定类型的文件
find在查找时,可以使用 -name pattern 来查找指定类型的文件.例如:
(1)find . -name "*.c" 将会在当前目录下查找 ".c" 类型的文件.
(2)find . -name "*.c" -o -name "*.h" 将会在当前目录下查找".c"和".h"类型的
文件,实际上就是通过-o来执行或操作,从而查找多种类型的文件.此时,要注意一点,
如果希望对查找到的内容做一些格式化打印操作,例如find . -name "*.c" -printf
"%f\t%p\n",那么当查找多个类型文件时,每个-name后面就要跟着-printf,类似于
find . -name "*.c" -printf "%f\t%p\n" -o -name "*.h" -printf "%f\t%p\n",不
能写为find . -name "*.c" -o -name -printf "%f\t%p\n",这种写法只会对找到的
".h"类型文件做格式化输出.这是因为-o把两个表达式分隔开,此时-name "*.c"和
-name "*.h" -printf "%f\t%p\n"是两个独立的表达式,-printf语句对前面的-name
"*.c"不起作用.

还可以使用 -regex pattern -type f 选项来查找指定类型的文件. "-type f" 表示
查找regular file,即普通文本文件. 对 "-regex pattern" 描述如下:
-regex pattern: File name matches regular expression pattern. This is a
match on the whole path, not a search. For example, to match a file named
'./fubar3', you can use the regular expression '.*bar.' or '.*b.*3', but
not 'f.*r3'.即,pattern中要指定一个完整的路径,比如相对路径的'./'就需要指定.
例如要在当前目录下递归查找".c", ".h"类型的文件,可以写为:
    find ./ -regex '.*\.\(c\|h)\)' -type f
在正则表达式'.*\.\(c\|h\)'中,最开始的".*"就用于指定完整路径,它可以匹配"./",
"./a", "./b/c/"等等目录.接下来的"\."则是匹配后缀名前面的'.',即".c",".cpp",
".h"里面的那个'.',最后的\(c\|h)就是要匹配的具体后缀名了.其中, '\' 表示引用,
即指示shell不对后面的字符做特殊解释,而留给find命令去解释其意义.

四. 输出
(1) -print 选项. man find手册对该选项描述为:
print the full file name on the standard output, followed by a newline.
(2) find使用 -printf format 来进行格式化输出. 注意,-printf does not add a
newline at the end of the string. 一些转换格式描述如下:
%f: File's name with any leading directories removed (only the last element)
%p: File's name

五. 指定查找多个目录
当指定查找多个目录时,直接在find后面写上这么目录的路径即可,不用加上-o、-path等选项.
例如, find ./src ./res 命令会在src/、res/目录下递归查找所有文件.
如果还要同时指定忽略这些目录底下的某个子目录,可以再加上-path pathname -prune选项.
例如, find src res \( -path "*git" -o -path "*test*" \) -prune -o -print
注意,此时要加上 -o -print 才能打印出来查找到的文件名. 如果不加 -o -print,会打印
所忽略的目录名,而不是打印所找到的目录名、或者文件名.
