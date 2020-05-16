# 描述 Linux tar 命令的使用

在 Linux 中，可以使用 `tar` 命令把多个文件、目录打包到指定的归档文件里面。

要注意的是，`tar` 命令默认只是把多个文件打包放到一起，不会对文件进行压缩，所以打包后的文件大小并不会变小，由于添加了一些 tar 格式的文件信息，甚至可能会变大。

如果想在 `tar` 命令中进行压缩、或者解压缩操作，需要提供对应的选项参数。后面会具体说明。

# tar 命令格式
查看 man tar 对 `tar` 命令的格式说明如下：
> **tar [-] A --catenate --concatenate | c --create | d --diff --compare | --delete | r --append | t --list | --test-label | u --update | x --extract --get [options] [pathname ...]**
>
> Tar stores and extracts files from a tape or disk archive.
>
> A function letter need not be prefixed with ``-'', and may be combined with other single-letter options. A long function name must be prefixed with --.
>
> Some options take a parameter; with the single-letter form these must be given as separate arguments.  With the long form, they may be given by appending =value to the option.

即，`tar` 命令可以在磁带、或者磁盘上创建和提取归档文件。

提供 `Acdrtux` 这些选项时，选项前面可以不带连字符 `-`。

当其他选项和这几个功能选项写在一起时，也可以不带 `-` 字符。如果单独提供其他选项，需要以 `-` 开头。

对常用的功能选项说明如下：
- **-c, --create**  
    create a new archive.  
    即，指定创建一个新的归档文件，而不是从归档文件中提取文件。
- **-r, --append**  
    append files to the end of an archive.  
    即，往已有的归档文件中追加写入新的文件。
- **-t, --list**  
    list the contents of an archive.  
    即，不用解开归档文件，就能列出归档文件里面打包的文件信息
- **-u, --update**  
    only append files newer than copy in archive  
    即，当本地文件新于归档文件里面的文件时，打包本地文件到归档文件里面。  
    这个选项不能更新被压缩的归档文件。
- **-x, --extract, --get**  
    extract files from an archive.  
    即，从归档文件中提取出文件

在这些功能选项中，没有包含压缩和解压缩的选项。

一般来说，这些功能选项会再搭配下面的选项进行使用：
- **-f, --file ARCHIVE**  
    use archive file or device ARCHIVE.  
    即，`-f` 选项要提供一个参数，指定归档文件名称。  
    如果没有指定该选项，tar 命令一般会把内容写到标准输出。  
- **-v, --verbose**  
    verbosely list files processed.  
    即，打印操作过程的详细信息。常用于查看提取的文件信息。

一些使用例子说明如下：
- 创建归档文件
```bash
$ tar c java/ hello.c -f archive.tar
$ ls
archive.tar    java    hello.c
```
在 `tar c java/ hello.c -f archive.tar` 命令中，`c java/ hello.c` 指定对 *java/* 目录、*hello.c* 文件进行打包。`-f archive.tar` 指定打包生成的归档文件名是 *archive.tar*。

执行 `tar` 命令后，使用 `ls` 命令可以看到生成了 *archive.tar* 文件。

- 列出归档文件里面的文件信息
```bash
$ tar tf archive.tar
java/
java/Service.java
hello.c
```
可以看到，刚才打包生成的 `archive.tar` 里面包含一个 *java/* 目录，一个 *hello.c* 文件，在 *java/* 目录里面有一个 *Service.java* 文件。

- 从归档文件中提取出文件
```bash
$ tar xf archive.tar
$ tar xvf archive.tar
java/
java/Service.java
hello.c
```
可以看到，`tar xvf archive.tar` 命令从 *archive.tar* 归档文件中提取文件到本地，使用 `-v` 选项列出提取的文件信息。

而 `tar xf archive.tar` 命令只提取文件到本地，没有列出提取的文件信息。

# 指定压缩和解压缩
由于 `tar` 命令默认只打包，不压缩，打包后的归档文件大小并不会变小。

如果想在打包时进行压缩，需要指定其他选项。如果要解压缩，也需要指定对应的选项。

下面这些选项用于指定使用什么压缩工具，指定的压缩工具可用于压缩、或者解压缩。
- **-j, --bzip2**  
    使用 `bzip2` 命令进行压缩或解压缩
- **-z, --gzip, --gunzip --ungzip**  
    使用 `gzip` 命令进行压缩或解压缩
- **-Z, --compress, --uncompress**  
    使用 `compress` 命令进行压缩或解压缩
- **-a, --auto-compress**  
    use archive suffix to determine the compression program.  
    即，根据归档文件的后缀名自动选择压缩命令。例如，`.gz` 后缀名使用 `gzip` 命令进行压缩。

**注意**：这几个选项用于指定使用什么压缩工具来进行压缩、或者解压缩，这些选项仅仅只是指定压缩工具。具体是压缩、还是解压缩，可以由 `-c` 选项和 `-x` 选项来指定。

当这几个选项搭配打包归档文件的选项一起使用时，会进行压缩操作。

当这几个选项搭配提取归档文件的选项一起使用时，会进行解压缩操作。

**所指定的压缩工具是单独的命令，需要系统已经安装这些命令才能正常使用**。

## 使用 tar 进行压缩的命令
下面是一些使用 tar 进行压缩的命令。
- 使用 gzip 进行压缩
```bash
tar czf archive.tar.gz java/ hello.c
```
在 `tar czf archive.tar.gz java/ hello.c` 命令中，`-z` 选项指定使用 gzip 命令进行操作。`-c` 选项指定创建归档文件，结合 `-z` 使用就是进行压缩。`-f` 选项指定后面跟着的参数是归档文件名，也就是 *archive.tar.gz*。后面所给的 *java/ hello.c* 这几个文件会被压缩打包。

一般来说，使用 gzip 进行压缩的文件，文件名会以 `.gz` 结尾。在 `tar` 命令中使用 gzip 进行压缩，文件名会以 `.tar.gz` 结尾。但这并不是强制的。

在 Linux 里面，文件名后缀名并不能决定文件的格式，这样写只是为了方便查看。

- 使用 bzip2 进行压缩
```bash
tar cjf archive.tar.bz2 java/ hello.c
```
在这个命令中，`-j` 选项指定使用 bzip2 命令进行操作。

一般来说，使用 bzip2 进行压缩的文件，文件名会以 `.bz2` 结尾。在 `tar` 命令中使用 bzip2 进行压缩，文件名会以 `.tar.bz2` 结尾。

- 使用 compress 进行压缩
```bash
tar cZf archive.tar.Z java/ hello.c
```
在这个命令中，`-Z` 选项指定使用 compress 命令进行操作。

如果当前系统没有安装 *compress* 命令会报错。

一般来说，使用 compress 进行压缩的文件，文件名会以 `.Z` 结尾。在 `tar` 命令中使用 bzip2 进行压缩，文件名会以 `.tar.Z` 结尾。

- 根据归档文件的后缀名自动使用对应命令进行压缩
```bash
$ tar caf archive.tar.gz java/ hello.c
$ file archive.tar.gz
archive.tar.gz: gzip compressed data, from Unix, last modified: Fri Dec  6 14:50:57 2019
$ tar caf archive.tar.bz2 java/ hello.c
$ file archive.tar.bz2
archive.tar.bz2: bzip2 compressed data, block size = 900k
```
在 `tar caf archive.tar.gz java/ hello.c` 命令中，`-a` 选项指定根据归档文件后缀名自动选择相应的命令。这里提供的后缀名是 `.gz`，会使用 gzip 命令。

执行该命令后，使用 `file archive.tar.gz` 命令查看生成的文件格式，确实是 gzip 压缩格式。

类似的，在 `tar caf archive.tar.bz2 java/ hello.c` 命令中，通过 `-a` 选项和 `.bz2` 后缀名指定用 bzip2 进行操作。

## 使用 tar 进行解压缩的命令
在 `tar` 命令进行解压缩，也是用到 `-z`、`-f`、`-Z` 选项。下面是一些使用 tar 进行解压缩的命令。
- 使用 gzip 进行解压缩
```bash
tar xzvf archive.tar.gz
```
在 `tar xzf archive.tar.gz` 命令中，`-z` 选项指定用 gzip 命令进行操作，`-x` 选项指定从归档文件提取文件，结合 `-z` 使用就是进行解压缩。`-f archive.tar.gz` 指定对 *archive.tar.gz* 归档文件进行解压缩，并提取文件到本地，该文件必须是用 gzip 格式的压缩文件才能正确解压缩。

这里使用 `-v` 选项以便打印提取的文件。这个选项不是必须的。如果没有添加该选项，解压缩的时候，界面会没有任何打印。

- 使用 bzip2 进行解压缩
```bash
tar xjvf archive.tar.bz2
```
在这个命令中，`-j` 选项指定使用 bzip2 命令进行操作。

- 使用 compress 进行解压缩
```bash
tar xZvf archive.tar.Z
```
在这个命令中，`-Z` 选项指定使用 compress 命令进行操作。

**注意**：对于某些没有使用约定后缀名结尾的归档压缩文件，可以使用 `file` 命令来确认它的格式，以便使用对应的选项来进行解压缩。

# 结合 openssl 命令进行加密解密

## 对归档文件进行加密
在使用 `tar` 命令打包时，可以结合 `openssl` 命令使用，对生成的归档文件进行加密。具体命令如下：
```bash
tar -czf - filename | openssl des3 -salt -k passwd | dd of=filename.des3
```
在 `tar -czf - filename` 命令中，`-zc` 指定对所给的文件使用 gzip 进行压缩。如果想用其他的压缩命令，可以改用对应的选项。

`-f -` 表示把创建的归档文件写入到标准输出，`tar` 命令可以把 `-` 当成文件名，并进行一些特殊处理。后面会具体说明。而 *filename* 是被打包压缩的文件名，可以提供多个文件名、或者目录名。

这个命令把生成的归档文件写入到标准输出，以便通过管道把归档文件的内容传递给 `openssl` 命令处理。

查看 GNU tar 的在线帮助链接 <https://www.gnu.org/software/tar/manual/tar.html>，对使用 `-` 作为文件名的说明如下：
> If you use '-' as an archive-name, tar reads the archive from standard input (when listing or extracting files), or writes it to standard output (when creating an archive).  
> If you use '-' as an archive-name when modifying an archive, tar reads the original archive from its standard input and writes the entire new archive to its standard output.

即，在创建归档文件时，使用 `-` 作为文件名，会把生成归档文件写入到标准输出，不会生成文件到本地文件系统上。

在提取归档文件时，使用 `-` 作为文件名，会从标准输入读取要提取的归档文件。

`openssl des3 -salt -k passwd` 命令指定用 des3 算法进行加密，`-k passwd` 指定加密加密，可以修改 *passwd* 成其他密码。如果需要用其他算法进行加密，可以查看 `openssl` 的帮助说明。

如果不想在终端上明文输入密码，可以不提供 `-k passwd` 选项，会提示从终端输入密码，不会回显。

`dd of=filename.des3` 命令指定加密后的文件名为 *filename.des3*，可以修改成其他文件名。

## 对归档文件进行解密
使用上面命令对归档文件价加密后，可以使用下面命令进行解密：
```bash
dd if=filename.des3 | openssl des3 -d -k passwd | tar zxf -
```
`dd if=filename.des3 ` 命令指定读取 *filename.des3* 文件内容。

`openssl des3 -d -k passwd` 命令表示使用 des3 算法进行解密。

解密之后的内容是之前 `tar` 命令生成的归档文件内容，会写入到标准输出，通过管道传递给后面 `tar` 命令的标准输入。

可以不提供 `-k passwd` 选项，执行时会提示从终端输入密码，不会回显。

`tar zxf -` 命令表示从标准输入读取要提取的归档文件内容，提取出来的文件会写入到本地。
