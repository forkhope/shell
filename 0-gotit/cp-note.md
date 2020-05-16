# 描述 Linux cp 命令的使用

# 复制时自动创建不存在的子目录
在 Linux 中，可以使用 `cp` 命令的 `--path` 选项指定在复制的时候自动创建不存在的子目录。

例如执行下面的命令：
```bash
$ cp --path java/com/server/Service.java target/
```
如果 *target* 目录下不存在 *java/com/server/* 这一串子目录，`cp --path` 命令会自动创建 *java/com/server/* 这一串子目录，然后把文件复制到对应的子目录下。

**注意**：在上面命令中，*target* 目录必须存在，才能复制。`cp --path` 命令只会自动创建源文件路径包含的子目录，不会自动创建所给的目标目录。

从行为来看，`cp --path java/com/server/Service.java target/` 命令类似于下面的命令：
```bash
$ mkdir -p target/java/com/server/
$ cp java/com/server/Service.java target/java/com/server/
```
`mkdir -p` 命令表示递归创建一串子目录。

## --parents 选项
查看 man cp 的说明，里面没有提到 `--path` 选项，但实际上可以使用这个选项。它应该是被废弃了。

使用该选项复制报错时，提示的选项名是 `--parents`，应该是被 `--parents` 选项所替代：
```bash
$ cp --path java/com/server/Service.java not_exist/
cp: with --parents, the destination must be a directory
Try 'cp --help' for more information.
```
可以看到，`cp --path` 命令复制报错，提示信息说是使用 `--parents` 时，目标文件名必须是一个已经存在的目录。

可见，`--path` 被当成 `--parents` 来处理。

查看 GNU cp 的在线帮助链接 <https://www.gnu.org/software/coreutils/manual/html_node/cp-invocation.html>，对 `--parents` 选项说明如下：
> **--parents**
>
> Form the name of each destination file by appending to the target directory a slash and the specified name of the source file.
>
> The last argument given to cp must be the name of an existing directory. For example, the command:
```
    cp --parents a/b/c existing_dir
```
> copies the file a/b/c to existing_dir/a/b/c, creating any missing intermediate directories.

即，当被复制的源文件路径包含子目录名，`--parent` 选项会在目标目录下自动创建不存在的子目录。目标目录本身必须已经存在。

由于在 `cp` 命令的帮助信息中已经找不到 `--path` 选项的说明，建议不再使用这个选项，改用 `--parents` 选项。

# 只复制新修改过或者不存在的文件
在 Linux 中，有时候会遇到这样一个问题场景：使用 `cp` 命令复制一个很大的目录（该目录底下有很多子目录或者文件），但是复制到中途时，遇到异常，导致停止复制，需要重新复制。

这个时候不希望复制已经复制过的文件，而是只复制还没有复制过的文件。那么可以使用 `cp` 命令的 `-u` 选项。

查看 man cp 对 `-u` 选项说明如下：
> **-u, --update**
>
> copy only when the SOURCE file is newer than the destination file or when the destination file is missing.

即，只有源文件新于目标文件、或者目标文件不存在时，`cp -u` 命令才会复制这个文件。
