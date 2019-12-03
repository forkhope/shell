# 描述 ls 命令的使用

# 只获取指定目录下的子目录名

## 在 ls 命令中只列出子目录名
在 Linux 中，`ls` 命令默认会列出所给目录下的所有文件名，包括子目录名。如果只想列出当前目录下的子目录名，可以使用 `ls -d */` 命令。具体测试如下：
```bash
$ ls
test_dir  test_text
$ ls -d */
test_dir/
$ ls -d *
test_dir  test_text
```
在这个例子中，当前目录下有一个 *test_dir* 子目录、和一个 *test_text* 文本文件。

可以看到，`ls -d */` 命令只列出 *test_dir* 子目录名，且目录名以 `/` 结尾。而 `ls -d *` 命令还是列出了当前目录下的所有文件名。后面会说明这两个命令的区别。

查看 info ls 对 `-d` 选项的说明如下：
> **-d, --directory**  
List just the names of directories, as with other types of files, rather than listing their contents.

即，`ls -d` 选项只列出所给参数自身的名称。如果参数中包含目录名，只列出该目录名，不再列出该目录下的所有文件名。如果参数中包含文件名，则列出该文件名。

**注意**：`ls` 命令的参数是目录名时，默认是列出该目录下的文件名，包括子目录名。如果没有任何参数，默认使用 `.` 这个参数，也就是列出当前目录下的文件名。而 `ls -d` 选项改变了这个行为，不再获取所给目录下的文件信息，只列出所给的目录名。

具体举例说明如下：
```bash
$ ls
test_dir  test_text
$ ls -d
.
$ ls test_dir
$ ls -d test_dir
test_dir
```
跟上面例子一样，当前目录下有一个 *test_dir* 子目录、和一个 *test_text* 文本文件。`ls` 命令不提供任何参数时，相当于 `ls .` 命令，列出当前目录下的文件信息。

`ls -d` 命令只打印了一个 `.`，对应当前目录。`ls -d` 相当于 `ls -d .` 命令，而 `-d` 选项指定列出所给目录名，不列出目录下的文件。所以打印出一个 `.`。

`ls test_dir` 目录打印为空，因为 *test_dir* 是一个空目录，该目录下没有文件。`ls -d test_dir` 目录打印了 test_dir，也就是所给的 *test_dir* 目录名。

基于上面说明，打开 bash 的调试信息后，可以看到 `ls -d */` 命令和 `ls -d *` 命令的区别如下：
```bash
$ set -x
$ ls -d */
+ ls --color=auto -d test_dir/
test_dir/
$ ls -d *
+ ls --color=auto -d test_dir test_text
test_dir  test_text
$ set +x
```
可以看到，`*/` 扩展之后的结果是 *test_dir/*，只有子目录名，没有文本文件名。那么 `ls -d test_dir/` 只列出了这个目录名。

而 `*` 扩展之后的结果是 *test_dir test_text*，包含子目录名和文本文件名。那么 `ls -d test_dir test_text` 会列出所给的子目录名和文件文件名。

## 使用星号 * 通配符来获取子目录名
上面两个命令最大的区别在于 `*/` 和 `*` 的路径名扩展结果不同。查看 man bash 的 *Pathname Expansion* 小节，对此说明如下：
> If followed by a /, two adjacent *s will match only directories and subdirectories.

即，当星号 `*` 通配符后面跟着 `/` 字符时，路径名扩展结果只有目录名和子目录名。

如果只是想获取当前目录下的子目录名，直接为赋值为 `*/` 即可，不要用引号括起来。举例如下：
```bash
$ subdirs=*/
$ echo $subdirs
test_dir/
```
可以看到，`subdirs=*/` 语句会把 *subdirs* 变量赋值为当前目录下的子目录名，目录名会以 `/` 结尾。

当在 shell 脚本中使用时，由于执行 shell 脚本的工作目录可能不固定，可以通过绝对路径来寻址。举例如下：
```bash
$ subdirs=/home/sample/*/
$ echo $subdirs
/home/sample/test_dir/
```
