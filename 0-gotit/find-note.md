# 描述 find 命令的使用

在 Linux 命令中，`find` 是比较复杂难用的命令。使用该命令搜索文件时，常常发现自己找了一些例子能用，但稍微改一下条件，就搜不到想要的结果。

下面会以一些实例来说明使用 `find` 命令的关键要点和注意事项，解释清楚各个条件能够工作、或者不能工作的原因。

# find 命令格式
要使用一个命令，首先要了解命令的格式，知道要提供什么参数、参数作用是什么。

查看 man find 对该命令的说明如下：
- find - search for files in a directory hierarchy.
- find [-H] [-L] [-P] [-D debugopts] [-Olevel] [path...] [expression]
- GNU find searches the directory tree rooted at each given file name by evaluating the given expression from left to right, according to the rules of precedence, until the outcome is known (the left hand side is false for and operations, true for or), at which point find moves on to the next file name.
- The -H, -L and -P options control the treatment of symbolic links. Command-line arguments following these are taken to be names of files or directories to be examined, up to the first argument that begins with `‘-’`, or the argument `‘(’` or `‘!’`.
- If no paths are given, the current directory is used. If no expression is given, the expression -print is used (but you should probably consider using -print0 instead, anyway).
- The expression is made up of options (which affect overall operation rather than the processing of a specific file, and always return true), tests (which return a true or false value), and actions (which have side effects and return a true or false value), all separated by operators.  -and is assumed where the operator is omitted.
- If the expression contains no actions other than -prune, -print is performed on all files for which the expression is true.

即，`find` 命令的作用是在目录层次结构下搜索文件，默认会递归搜索所给目录的子目录，对查找到的每一个文件名（目录名也属于文件名）依次进行后面表达式的判断，来决定是否打印搜索到的文件名、或者进行其他的操作。

**注意**：对每一个搜索到的文件名都依次进行表达式评估是非常关键的点，`find` 命令会把搜索到的每一个文件名都依次作为参数传递给后面的表达式进行评估，来决定如何处理这个文件，某个文件的表达式评估为 false，还是会继续评估下一个文件，除非主动执行了结束的操作。

理解这一点，就会清楚为什么有些文件名会打印出来，而有些文件名不会打印出来，因为它们本身就相互不关联。

下面具体说明 `find` 命令格式各个部分的含义：
- `[-H] [-L] [-P] [-D debugopts] [-Olevel]` 这部分属于命令选项，比较少用到，这里不做说明。
- `[path...]` 该参数指定要查找哪个目录，可以同时提供多个目录名，用空格隔开，如果没有提供该参数，默认查找当前目录、及其子目录。也可以提供文件名，只在当前目录下查找该文件，不会在子目录中查找。
- `[expression]` 该参数指定评估表达式，可以提供多个表达式，不同表达式之间要用 *operator* 操作符来分隔开，如果表达式之间没有提供操作符，默认会用 -and 操作符。表达式有 *option*、*test*、*action* 三种类型。如果不提供该参数，默认使用 `-print` 表达式，也就是打印出所给的文件名。参考上面说明，表达式参数要求以 `‘-’`、`‘(’`、或者 `‘!’` 开头，以便区分开前面的目录参数。注意，在 bash 中要用 `‘\(’` 来对 `‘(’` 进行转义。

关于 `find` 命令的说明，也可以查看 GNU find 的在线帮助手册 <https://www.gnu.org/software/findutils/manual/html_mono/find.html>，这里面的说明比 man find 详细，并提供了不少例子，可供参考。

在 Linux 中，目录也属于文件，`find` 在查找时，把目录也当成文件处理，会查找并处理目录名，并不是只处理文件名。

后面在说明时，如无特别备注，所说的文件名包含了目录名。

# 查找指定目录下的所有文件
`find` 命令最简单的用法就是直接执行这个命令，不提供任何参数，默认会查找当前目录、及其子目录下的所有文件，并打印出所有文件名。

具体举例如下：
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
可以看到，在 shell 的当前工作目录下执行 `find` 命令，不提供任何参数，会打印出当前目录、及其子目录下的所有文件名，包括目录名。

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
在 Linux 下，点号 `‘.’` 对应当前目录，所以 `find .` 就是查找当前目录下的所有文件，当没有提供目录参数时，默认就是使用 `‘.’` 这个参数。

`find src` 命令指定只查找 *src* 这个目录下的所有文件。

`find src tests` 命令指定查找 *src*、*tests* 这两个目录下的所有文件，可以同时提供多个目录名来指定查找这些目录。

`find src tests` 命令也可以写为 `find ./src ./tests`。

如果在 `find` 命令后面提供文件名，则只在当前目录下查找该文件，不会在子目录下查找：
```bash
$ find Makefile.am
Makefile.am
$ find main.c
find: `main.c': No such file or directory
```
结合上面打印的文件信息，可以看到当前目录下有一个 `Makefile.am` 文件，`find Makefile.am` 命令可以找到这个文件，不会报错。

而 *main.c* 文件是在 *src* 子目录下，`find main.c` 命令执行报错，提示找不到这个文件，它不会进入 *src* 子目录进行查找。

**注意**：前面提到，查找条件要求以 `‘-’`、`‘(’`、或者 `‘!’` 开头，在遇到以这几个字符开头的任意参数之前，前面的参数都会被当作目录参数，指定查找多个目录时，直接在 `find` 命令后面写上这些目录的路径，用空格隔开即可，不用加上 -o、-path 等选项，加上反而有异常。

刚接触 `find` 命令，常见的误区之一就是认为要用 `-o` 选项来指定查找多个目录。

例如认为 `find src -o tests` 是同时查找 *src*、*tests* 这两个目录，这是错误的写法，执行会报错：
```bash
$ find src -o tests
find: paths must precede expression: tests
```
可以看到，执行报错，提示目录路径参数必须在表达式参数之前提供。`-o` 参数以 `-` 开头，会被认为是表达式参数，它自身、以及在它之后的所有参数都会认为是表达式参数，之后提供的目录名不会被当作要查找的目录。

某些表达式参数的后面可以提供目录名，但是这些目录名并不是用于指定查找该目录下的文件，而是另有含义。

另一个误区是，执行 `find src -o tests` 命令报错后还不知道错在哪里，望文生义，又加上 `-path` 选项，误写为 `find src -o -path tests`、或者 `find src -path -o tests`。这两个命令都会报错，自行测试即知。

虽然写为 `find src -path tests` 不会报错，但是它并不会打印出 *src*、*tests* 这两个目录下的文件名。

后面会具体说明 `-path` 参数的用法。

# 查找时指定忽略一个或多个目录
基于上面例子的目录结构，如果想查找当前目录下的文件，且忽略 *tests* 目录，可以执行下面的命令：
```bash
$ find . -path ./tests -prune -o -print
.
./src
./src/main.c
./Makefile.am
```
可以看到，打印的文件名里面没有 *tests* 目录名、以及它底下的文件名。

但是如果把上面 `-path` 后面的 `./tests` 改成 `tests`，还是会查找 *tests* 目录下的文件：
```bash
$ find . -path tests -prune -o -print
.
./src
./src/main.c
./tests
./tests/bre.tests
./Makefile.am
```
这个结果比较奇怪，查找时想要忽略 *tests* 目录，写为 `-path ./tests` 可以忽略，写为 `-path tests` 就不能忽略。

这是使用 `find` 命令的 `-path` 参数时常见的错误，别人的例子可以生效，自己写的时候就不生效。这需要理解 `-path` 参数的含义才能正确使用它。

前面提到，不同的表达式之间要用操作符分隔开，如果没有提供操作符，默认使用 `-and` 操作符。

所以 `find . -path ./tests -prune -o -print` 命令的完整格式其实是 `find . -path ./tests -and -prune -o -print`。

下面对这个完整命令格式的各个参数进行详细说明，以便理解它的工作原理，就能知道为什么写为 `-path ./tests` 可以忽略，写为 `-path tests` 不能忽略。

## -path pattern
这是一个 *test* 类型表达式，GNU find 在线帮助手册对该表达式的说明如下：
> **Test: -path pattern**
>
> True if the entire file name, starting with the command line argument under which the file was found, matches shell pattern pattern.
>
> To ignore a whole directory tree, use ‘-prune’ rather than checking every file in the tree.
>
> The “entire file name” as used by find starts with the starting-point specified on the command line, and is not converted to an absolute pathname.

即，当 `find` 命令查找到的文件名完全匹配所给的 *pattern* 模式时，该表达式返回 true。

这里面最关键的点是，**要完全匹配 `find` 命令查找到的名称，而不是部分匹配，也不是匹配文件的绝对路径名**。

具体举例说明如下：
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
可以看到，`find . -path ./tests` 命令打印了 `./tests` 目录名，但是 `find . -path tests` 命令什么都没有打印。

查看上面 `find .` 命令打印的信息，可以看到该命令打印的 *tests* 目录名是 `./tests`，`-path` 参数要求是完全匹配才会返回 true，所以基于打印结果，就是要写为 `-path ./tests` 才会返回 true。

前面贴出的 man find 说明提到，没有提供除了 `-prune` 表达式之外的其他 *action* 类型表达式时，默认会对所有返回 true 的文件名执行 `-print` 表达式，打印该文件名。

所以打印结果里面只有匹配到的 `./tests` 目录名，那些没有完全匹配 `./tests` 的文件名会返回 false，没有被打印。

由于 `find .` 命令打印的目录名后面没有加上 `/` 字符，所以 `find . -path ./tests/` 也匹配不到任何文件名，没有打印任何信息。

类似的，执行 `find tests` 命令，打印的 *tests* 目录名是 `tests`，那么 `find tests -path tests` 命令可以完全匹配 `tests` 模式，打印出这个目录名。

而 `find tests -path ./tests` 就匹配不到，没有打印。

即，根据传入的目录参数不同，`find` 打印的目录名不同，`-path` 后面要提供的目录名也不同。

**总的来说，在 `-path` 后面跟着的目录名，需要完全匹配 `find` 命令打印的目录名，而不是部分匹配。如果不确定 `find` 命令打印的目录名是什么，可以先不加 `-path` 参数执行一次 `find` 命令，看打印的文件名是什么，再把对应的文件名写到 `-path` 参数后面**。

在 `-path` 后面的 *pattern* 模式可以用通配符匹配特定模式的文件名，常见的通配符是用 `*` 来匹配零个或多个字符。

在 `find` 中使用时有一些需要注意的地方，举例说明如下：
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
可以看到，`find . -path *test*` 什么都没有打印，`*test*` 没有匹配到 `./tests` 这个名称。

原因是这里的 `*` 通配符是由 bash 来处理，通过文件名扩展来得到当前目录下的子目录名或者文件名，但是不会在目录名前面加上 `./`。

即，这里的 `find . -path *test*` 相当于 `find . -path tests`，前面已经说明这是不匹配的。

`find . -path ./test*` 可以打印出匹配到的目录名，经过 bash 扩展后，这个命令相当于 `find . -path ./tests`。

`find . -path \*test\*` 命令不但匹配到了 `./tests` 目录，还匹配到了该目录下的 `./tests/bre.tests` 文件。

这里用 `\*` 对 `*` 进行转义，对 bash 来说它不再是通配符，不做扩展处理，而是把 `*` 这个字符传递给 `find` 命令，由 `find` 命令自身进行通配符处理，可以匹配到更多的文件。

这里面涉及到 bash 和 find 对 `*` 通配符扩展的区别，bash 在文件名扩展 `*` 时，遇到斜线字符 `/` 则停止，不会扩展到目录底下的文件名。

而 find 没有把 `/` 当成特殊字符，会继续扩展到目录底下的文件名。

查看 GNU find 在线帮助手册 <https://www.gnu.org/software/findutils/manual/html_mono/find.html#Shell-Pattern-Matching> 的说明如下：
> Slash characters have no special significance in the shell pattern matching that find and locate do, unlike in the shell, in which wildcards do not match them.

`find . -path "*test*"` 命令的打印结果跟 `find . -path \*test\*` 相同。

原因是，bash 没有把双引号内的 `*` 当成通配符，会传递这个字符给 find，由 find 来处理通配符扩展。

如果不想用 `\*` 来转义，可以用双引号把模式字符串括起来。

**注意**：虽然 `-path` 表达式的名字看起来是对应目录路径，但是也能用于匹配文件名，并不只限于目录。

在 man find 里面提到，有一个 `-wholename` 表达式和 `-path` 表达式是等效的，但是只有 GNU find 命令支持 `-wholename` 表达式，其他版本的 find 命令不支持该表达式。从名字上来说，`-wholename` 表达式比较准确地表达出要完全匹配文件名称。

## -and
这是一个 *operator* 操作符，GNU find 在线帮助手册对该操作符的说明如下：
> **expr1 expr2**
>
> **expr1 -a expr2**
>
> **expr1 -and expr2**
>
> And; expr2 is not evaluated if expr1 is false.

可以看到，`-and` 操作符有三个不同的写法，都是等效的。

`find` 命令的操作符把多个表达式组合到一起，成为一个新的组合表达式，组合表达式也会有自身的返回值。

使用 `-and` 操作符组合的表达式要求两个表达式都是 true，该组合表达式才是 true。

左边的 *expr1* 表达式为 false 时，不再评估右边的 *expr2* 表达式，该组合表达式会返回 false。

上面例子的 `find . -path tests` 命令什么都没有打印，就跟 `-and` 操作符的特性有关。

由于该命令没有提供 *action* 类型表达式，默认会加上 `-print` 表达式，也就是 `find . -path tests -print`。

由于在 `-path tests` 和 `-print` 之间没有提供操作符，默认会加上 `-and` 操作符，也就是 `find . -path tests -and -print`。

而 `find .` 命令搜索到的所有文件名都不匹配 `-path tests` 模式，都返回 false，基于 `-and` 操作符的特性，不往下执行 `-print` 表达式，也就不会打印任何文件名。

## -prune
这是一个 *action* 类型表达式，GNU find 在线帮助手册对该表达式的说明如下：
> **Action: -prune**
>
> If the file is a directory, do not descend into it. The result is true.
>
> For example, to skip the directory src/emacs and all files and directories under it, and print the names of the other files found:  
> 
> `find . -wholename './src/emacs' -prune -o -print`  
>
> The above command will not print ./src/emacs among its list of results. This however is not due to the effect of the ‘-prune’ action (which only prevents further descent, it doesn’t make sure we ignore that item). 
>
> Instead, this effect is due to the use of ‘-o’. Since the left hand side of the “or” condition has succeeded for ./src/emacs, it is not necessary to evaluate the right-hand-side (‘-print’) at all for this particular file.

这里举的例子就类似于我们现在讨论的例子，里面也解释了查找时能够忽略目录的原因，可供参考。

前面提到，`find` 命令会把搜索到的每一个文件名都依次作为参数传递给后面的表达式进行评估。

如果传递到 `-prune` 表达式的文件名是一个目录，那么不会进入该目录进行查找。

这个表达式的返回值总是 true。

具体举例说明如下：
```bash
$ find . -path \*test\* -prune
./tests
$ find . -path \*test\* -o -prune
.
```
前面例子提到，`find . -path \*test\*` 会匹配到 `./tests` 目录和该目录下的 `./tests/bre.tests` 文件。

而这里的 `find . -path \*test\* -prune` 只匹配到 `./tests` 目录，没有进入该目录下查找文件，就是受到了 `-prune` 表达式的影响。

基于前面的说明，`find . -path \*test\* -prune` 相当于 `find . -path \*test\* -and -prune -and print`。

对于不匹配 `\*test\*` 模式的文件名，`-path \*test\*` 表达式返回 false，不往下处理，不打印不匹配的文件名。

对于匹配 `\*test\*` 模式的文件名，`-path \*test\*` 表达式返回 true，会往下处理，遇到 `-prune` 表达式。该表达式总是返回 true，继续往下处理 `-print` 表达式，打印出该目录名。

由于 `-prune` 表达式指定不进入对应的目录，所以没有查找该目录下的文件，没有查找到 `./tests/bre.tests` 文件。

## -o
这是一个 *operator* 操作符，GNU find 在线帮助手册对该操作符的说明如下：
> **expr1 -o expr2**
>
> **expr1 -or expr2**
>
> Or; expr2 is not evaluated if expr1 is true.

使用 `-o` 操作符组合的表达式要求两个表达式都是 false，该组合表达式才是 false。

左边的 *expr1* 表达式为 true 时，不再评估右边的 *expr2* 表达式，该组合表达式会返回 true。

前面提到， `find . -path tests` 命令什么都没有打印，跟使用了 `-and` 操作符有关，如果改成 `-o` 操作符，结果就会不一样。

具体举例如下：
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
可以看到，`find . -path tests -o -print` 命令打印了当前目录下的所有文件名。

由于 `-path tests` 什么都匹配不到，都返回 false，基于 `-o` 操作符的特性，全都执行后面的 `-print` 表达式，打印所有文件名。

这个结果跟 `find . -path tests` 命令完全相反。

类似的，`find . -path ./tests -o -print` 命令的打印结果跟 `find . -path ./tests` 命令也相反。

前者的打印结果不包含 `./tests` 目录名，后者的打印结果只包含 `./tests` 目录名。

对于匹配 `-path ./tests` 模式的目录名，该表达式返回 true，基于 `-o` 操作符的特性，不往下执行 `-print` 表达式，所以不打印该目录名。

## -print
这是一个 *action* 类型表达式，GNU find 在线帮助手册对该表达式的说明如下：
> **Action: -print**
>
> True; print the entire file name on the standard output, followed by a newline.

前面例子已经说明过 `-print` 表达式的作用，它会打印传递下来的完整文件路径名，会自动添加换行符。

如果没有提供除了 `-prune` 之外的其他 *action* 类型表达式，`find` 默认会加上 `-print` 表达式，并用 `-and` 来连接前面的表达式。

这个行为可能会带来一些误解，认为 `find` 命令总是会打印搜索到、或者匹配到的文件名，但有时候搜索到、或者匹配到的文件名反而不打印。

例如上面 `find . -path ./tests -o -print` 的例子。

要消除这个误解，就一定要清楚地认识到，`find` 命令想要打印文件名，就必须执行到 `-print` 表达式、或者其他可以打印文件名的表达式。

即，要执行可以打印文件名的表达式才会打印文件名，否则不会打印。

至于是匹配特定模式的文件名会打印，还是不匹配特定模式的文件名才会打印，取决于各个表达式、包括操作符组合表达式的判断结果，看是否会执行到可以打印文件名的表达式。

## 总结
结合上面的说明，对 `find . -path ./tests -and -prune -o -print` 命令在查找时能够忽略 `./tests` 目录底下文件的原因总结如下：
- `find .` 指定查找当前目录、及其子目录下的所有文件，每查找到一个文件名，就把这个文件名传递到后面的表达式进行评估，进行相应处理。
- `-path ./tests` 指定传递下来的文件名要完全匹配 `./tests` 这个字符串。对于不匹配的文件名，该表达式返回 false，那么 `-path ./tests -and -prune` 这个组合表达式会返回 false，且没有评估后面的 `-prune` 表达式。由于 `-and` 操作符优先级高于 `-o` 操作符，该组合表达式再跟后面的 `-o -print` 形成新的组合表达式，它返回 false，会往下执行 `-print` 表达式，从而打印出来不匹配的文件名。
- 对于匹配 `-path ./tests` 模式的目录名，该表达式返回 true，`-path ./tests -and -prune` 组合表达式会评估后面的 `-prune` 表达式，指定不进入匹配的目录名查找底下的文件，这个例子里面就是不进入 `./tests` 目录，所以查找时会忽略该目录底下的文件，但还是会查找到 `./tests` 目录名自身。
- 对于 `./tests` 这个目录名，由于 `-prune` 返回 true，`-path ./tests -and -prune` 组合表达式会返回 true，基于 `-o` 操作符的特性，不执行后面的 `-print` 表达式，所以没有打印这个目录名。
- 最后的 `-o -print` 是必要的，如果不加这两个参数，将不会打印不匹配 `./tests` 模式的文件名。
- 基于这几条分析，这个命令最终打印的结果里面，即不包含 `./tests` 这个目录名，也不包含它底下的文件名。

总的来说，使用 `find` 命令查找时，如果要忽略一个目录，可以用类似 `find . -path ./tests -prune -o -print` 这样的写法。

理解了上面对该命令的说明后，想要忽略其他模式的目录，应该就比较容易了。

## 忽略多个目录的写法
如果想要忽略多个目录，要使用 `-o` 操作符把多个  `-path pattern` 表达式组合起来。

基于上面例子的目录结构，举例如下：
```bash
$ find . \( -path ./tests -o -path ./src \) -prune -o -print
.
./Makefile.am
```
可以看到，`find . \( -path ./tests -o -path ./src \) -prune -o -print` 命令打印的查找结果里面，没有 `./src`、`./tests` 这两个目录、及其底下文件，也就是忽略了这两个目录。

基于 `-o` 操作符的特性，`-path ./tests -o -path ./src` 组合表达式在不匹配 `./tests` 模式时，会再尝试匹配 `./src` 模式，两个模式都不匹配，才会返回 false。

由于 `-and` 操作符优先级高于 `-o` 操作符，所以要用小括号 `()` 把 `-path ./tests -o -path ./src` 组合表达式括起来，形成一个独立的表达式，再跟后面的 `-prune` 组合成新的表达式。

小括号在 bash 中有特殊含义，所以要加 `\` 转义字符，写成 `\(`，避免 bash 对小括号进行特殊处理。

**注意**：在 `\(` 和 `\)` 前后要用空格隔开，这两个是单独的操作符，如果不加空格，会组合成其他名称。

其他表达式的含义和作用可以参考前面例子的说明。

如果能够基于这个命令的各个表达式、各个操作符的作用，推导出打印结果，就基本理解 `find` 命令的工作原理了。

# 匹配特定模式的文件名
上面说明的 `-path pattern` 表达式要求完全匹配整个目录路径，如果想要只匹配文件名，不包含目录路径部分，可以使用 `-name pattern` 表达式。

这是一个 *test* 类型表达式，GNU find 在线帮助手册对该表达式的说明如下：
> **Test: -name pattern**
>
> True if the base of the file name (the path with the leading directories removed) matches shell pattern pattern. As an example, to find Texinfo source files in /usr/local/doc:
>
> `find /usr/local/doc -name '*.texi'`
>
> Notice that the wildcard must be enclosed in quotes in order to protect it from expansion by the shell.

如这个帮助说明所举的例子，一般常用这个表达式来匹配特定后缀名的文件。具体举例如下。

## 匹配单个后缀名
下面是匹配单个后缀名的例子：
```bash
$ find . -name '*.c'
./src/main.c
```
可以看到，`find . -name '*.c'` 命令打印出所有后缀名为 `.c` 的文件名。

注意 `*.c` 要用引号括起来，避免 bash 当 `*` 号当成通配符处理。

该命令相当于 `find . -name '*.c' -and -print`，只有 `-name '*.c'` 表达式返回为 true 的文件名才会执行到 `-print` 表达式，打印出该文件名。

**注意**：使用 `-name pattern` 表达式并不表示只查找符合 *pattern* 模式的文件，`find` 命令还是会查找出所给目录的所有文件，并把每个文件名依次传给后面的表达式进行评估，只有符合 `-name pattern` 表达式的文件名才会返回 true，才会被打印出来。

不符合这个表达式的文件也会被查找到，只是没有打印出来而已。

## 匹配多个后缀名
下面是匹配多个后缀名的例子：
```bash
$ find . -name '*.c' -o -name '*.am'
./src/main.c
./Makefile.am
$ find . \( -name '*.c' -o -name '*.am' \) -and -print
./src/main.c
./Makefile.am
$ find . -name '*.c' -o -name '*.am' -and -print
./Makefile.am
```
可以看到，`find . -name '*.c' -o -name '*.am'` 命令打印出所有后缀名为 `.c` 和 `.am` 的文件名。

该命令相当于 `find . \( -name '*.c' -o -name '*.am' \) -and -print`，而不是相当于 `find . -name '*.c' -o -name '*.am' -and -print`，后者只能打印出后缀名为 `.am` 的文件名。

前面也有说明，`find` 命令会对所有返回为 true 的文件名默认执行 `-print` 表达式，这个返回为 true 是手动提供的整个表达式的判断结果。

也就是说手动提供的整个表达式应该会用小括号括起来，组成独立的表达式，再跟默认添加的 `-and -print` 表达式组合成新的表达式，避免直接加上 `-and -print` 后，会受到操作符优先级的影响，打印结果可能不符合预期。

## 重新格式化要打印的文件名信息
除了使用 `-print` 表达式打印文件名之外，也可以使用 `-printf` 表达式格式化要打印的文件名信息。

这是一个 *action* 类型表达式，GNU find 在线帮助手册对该表达式的说明如下：
> **Action: -printf format**
>
> True; print format on the standard output, interpreting ‘\’ escapes and ‘%’ directives.
>
> Field widths and precisions can be specified as with the printf C function.
>
> Unlike ‘-print’, ‘-printf’ does not add a newline at the end of the string. If you want a newline at the end of the string, add a ‘\n’.

即，`-printf` 表达式使用类似于C语言 *printf* 函数的写法来格式化要打印的信息，支持的一些格式如下：
- %p

    File’s name.

    这个格式包含完整路径的文件名。

- %f

    File’s name with any leading directories removed (only the last element).

    这个格式只包含文件名，会去掉目录路径部分。

**注意**：`-printf` 是 *action* 类型表达式，前面提到，如果提供除了 `-prune` 之外的 *action* 类型表达式，将不会自动添加 `-print` 表达式。

加了 `-printf` 表达式将由该表达式来决定打印的文件信息。

使用 `-printf` 表达式的例子如下：
```bash
$ find . \( -name '*.c' -o -name '*.am' \) -printf "%f  \t%p\n"
main.c          ./src/main.c
Makefile.am     ./Makefile.am
```
可以看到，所给 find 命令打印出指定后缀的文件名本身、以及完整路径的文件名。

`-name '*.c' -o -name '*.am'` 表达式需要用小括号括起来，组成独立的表达式。

如果不加小括号，由于 `-and` 操作符优先级高于 `-o` 操作符，`-name '*.am'` 实际上是跟 `-printf` 表达式组合，后缀名为 `.c` 的文件名无法执行到 `-printf` 表达式，将不会打印这些文件名。

由于 `-printf` 表达式不会在末尾自动加上换行符，想要换行的话，需要在格式字符串里面加上 ‘\n’ 换行符。

# 使用正则表达式匹配完整路径文件名
在 `find` 命令里面，`-path pattern` 表达式和 `-name pattern` 表达式都是使用通配符来匹配模式，如果想要用正则表达式进行匹配，可以使用 `-regex expr` 表达式。

这是 *test* 类型表达式，GNU find 在线帮助手册对该表达式的说明如下：
> **-regex expr**
>
> True if the entire file name matches regular expression expr. This is a match on the whole path, not a search.
>
> As for ‘-path’, the candidate file name never ends with a slash, so regular expressions which only match something that ends in slash will always fail.

即，`-regex expr` 表达式用正则表达式匹配完整路径的文件名，包含目录路径部分。

用正则表达式匹配后缀名为 `.c` 文件的例子如下：
```bash
$ find . -regex '.*\.c'
./src/main.c
$ find . -regex '.*c'
./src
./src/main.c
```
可以看到，`find . -regex '.*\.c'` 命令只打印出后缀名为 `.c` 的文件名。

而 `find . -regex '.*c'` 命令除了打印后缀名为 `.c` 的文件名，还打印了其他的文件名，这个命令的正则表达式不够精确，少了关键的 `\.` 来转义匹配点号 `.` 字符。

在 `.*\.c` 这个正则表达式中，最前面的 `.` 表示匹配任意单个字符，`*` 表示匹配零个或连续多个前面的字符，`\.` 通过转义来表示 `.` 字符自身，`c` 表示字符 *c* 自身，组合起来就是匹配后缀名为 `.c` 的字符串。

而 `.*c` 这个正则表达式匹配最后一个字符为 `c` 的字符串，不管在字符 *c* 前面是否有 `.` 字符，这个不符合后缀名的要求。

下面例子用正则表达式来匹配多个后缀名：
```bash
$ find . -regex '.*\.\(c\|am\)'
./src/main.c
./Makefile.am
```
这个例子同时匹配后缀名为 `.c` 和 `.am` 的文件名。

在正则表达式中，`(a|b)` 表示匹配 `a` 或者匹配 `b`。上面的 `\(c\|am\)` 经过转义后，也就是 `(c|am)`，用于匹配 `c` 或者 `am`，这样就比较好理解，不要被转义字符吓到了。

# 匹配特定类型的文件
在 Linux 中，文件类型可以分为目录 (directory)、文本文件 (regular file)、符号链接 (symbolic link)、socket，等等。

`find` 命令可以用 `-type c` 表达式来指定匹配这些类型的文件。

这是一个 *test* 类型表达式，GNU find 在线帮助手册对该表达式的说明如下：
> **Test: -type c**
>
> True if the file is of type c:
>
> d: directory
>
> f: regular file
>
> l: symbolic link
>
> s: socket

例如，使用 `-type f` 来指定只匹配文本文件：
```bash
$ find . -type f
./src/main.c
./tests/bre.tests
./Makefile.am
```
可以看到，在打印结果里面，没有看到目录名，只有文本文件名。

**注意**：`-type f` 表达式只表示匹配文本文件，并不表示只查找文本文件，`find` 命令还是会查找出所给目录的所有文件，并把每个文件名依次传给后面的表达式进行评估，只有符合 `-type f` 表达式的文件才会返回 true，才会被打印出来。

不符合这个表达式的文件也会被查找到，只是没有打印出来而已。
