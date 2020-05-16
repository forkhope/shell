# 记录 Linux crontab 命令设置定时任务的使用笔记

# 使用 crontab 命令指定周期执行的定时任务
在 Linux 中，可以使用 `crontab` 命令指定周期执行的定时任务，也就是周期性在指定的时间点执行某个任务，而不是执行一次之后就不再执行。

这个 `crontab` 命令用于设置在指定时间点要进行的具体操作，通过特定格式的信息来进行指定，这些信息会被写入一个 *crontab* 文件。

这些定时任务由 cron 守护进程来执行，该进程一直运行在后台，会定时检查 *crontab* 文件来判断需要做什么，如果某个任务需要被执行，就会执行该任务指定的操作。

一般来说，系统启动时，init 进程会启动 cron 进程。

可以使用 man crontab 来查看 `crontab` 命令的帮助信息。

使用 man 5 crontab 来查看 *ctontab* 文件的格式，需要基于特定格式来设置定时任务。

使用 man 8 cron 命令查看 cron 守护进程的帮助信息。

## 编辑定时任务
在 `crontab` 命令中，可以使用 `-e` 选项来指定编辑定时任务。

查看 man crontab 对 `-e` 选项的说明如下：
> The -e option is used to edit the current crontab using the editor specified by the VISUAL or EDITOR environment variables. After you exit from the editor, the modified crontab will be installed automatically. If neither of the environment variables is defined, then the default editor /usr/bin/editor is used.

即，`crontab -e` 命令编辑当前用户的 *crontab* 文件，在该文件中按照特定格式添加定时任务，优先使用 *VISUAL*、或者 *EDITOR* 环境变量值指定的编辑器来进行编辑。

如果这两个环境变量都没有定义，则默认使用 */usr/bin/editor* 文件指定的编辑器。

在 Debian 系统和 Ubuntu 系统上， */usr/bin/editor* 文件是一个链接文件，最终链接到 */bin/nano* 文件，也就是默认使用 nano 编辑器。

在 Ubuntu 系统上测试发现，第一次执行 `crontab -e` 命令时，它会调用 `select-editor` 命令提供一个编辑器菜单列表，可以选择一个默认的编辑器。如果按 CTRL-D，什么都没有选择，默认会使用 nano 编辑器。

## crontab 文件格式
执行 `crontab -e` 命令后，就会打开当前用户的 *crontab* 文件，在这个文件中，以 `#` 开头的语句是注释语句。

默认的 *crontab* 文件包含一些注释，在注释中提供了一个例子、以及设置定时任务的字段格式说明。具体内容如下：
```
# For example, you can run a backup of all your user accounts
# at 5 a.m every week with:
# 0 5 * * 1 tar -zcf /var/backups/home.tgz /home/
#
# m h  dom mon dow   command
```
这里举例说明了一个 `0 5 * * 1 tar -zcf /var/backups/home.tgz /home/` 定时任务，在每周一的五点钟会执行 `tar -zcf /var/backups/home.tgz /home/` 命令。

下面具体说明如何理解这个定时任务的各个字段。

在 *crontab* 文件中，通过 `m h  dom mon dow   command` 这六个字段来设置定时任务，每一行对应一个定时任务。这六个字段的含义说明如下：
- m：对应分钟（minute）  
指定要在一小时之中的第几分钟执行该任务。取值范围是 0-59.
- h：对应小时（hour）  
指定要在一天之中的第几个小时执行该任务。取值范围是 0-23.
- dom：对应日期（day of month）  
指定要在一月之中的第几天执行该任务。取值范围是 0-31.
- mon：对应月份（month）  
指定要在一年之中的第几月执行该任务。取值范围是 1-12。  
也可以通过月份英文名称的前三个字母来指定，不区分大小写。例如，一月的英文单词是 january，那么这里可以用 jan 来指定一月。
- dow：对应星期几（day of week）  
指定要在一周之中的星期几执行该任务。取值范围是 0-7，0 和 7 都对应星期天。  
也可以通过星期英文名称的前三个字母来指定，不区分大小写。例如，星期一的英文单词是 monday，那么这里可以用 mon 来指定星期一。
- command：对应具体的操作  
提供具体的命令来指定进行什么操作，可以提供脚本文件的路径来执行该脚本文件。

这六个字段要求用空格隔开。且每个字段都必须提供值，不能省略某个字段的值。从第五个字段之后的所有内容都属于第六个字段，也就是要执行的操作。

前五个字段可以使用下面的特殊字符来指定一些特殊的时间：
- \*  
表示任意一个有效的取值。例如，把日期指定为 `*`，则表示每一天都进行该任务。
- \-  
表示一个有效的范围值。例如，在小时指定为 `8-11`，表示在 8点、9点、10点、和 11点都执行该任务。
- ,  
表示隔开不同的取值列表。例如，把小时指定为 `2,3,5,7`，表示在 2点、3点、5点、7点都执行该任务。  
注意：在逗号后面不要加空格，空格表示隔开不同的字段。
- /  
表示一个时间间隔，而不是指定具体的时间。例如，把小时指定为 `*/2`，表示每间隔两小时执行一次该任务。

在 *command* 字段中，可以使用换行符、或者 % 字符来分隔命令内容。

在第一个 % 之前的内容会传递给 shell 来执行，这个 % 自身会被替换成换行符，在 % 之后、直到行末的内容都作为标准输入传递。

如果需要提供 % 字符自身，需要用 `\%` 进行转义。

## cron 守护进程如何执行定时任务
在 man 5 crontab 的说明中，有如下内容：
> Several environment variables are set up automatically by the cron(8) daemon. SHELL is set to /bin/sh, and LOGNAME and HOME are set from the /etc/passwd line of the crontab's owner. PATH is set to "/usr/bin:/bin". HOME, SHELL, and PATH may be overridden by settings in the crontab;
>
> An alternative for setting up the commands path is using the fact that many shells will treat the tilde(~) as substitution of $HOME, so if you use bash for your tasks you can use this:
```
        SHELL=/bin/bash
        PATH=~/bin:/usr/bin/:/bin
```

即，cron 守护进程默认使用 */bin/sh* 这个 shell 来执行 *crontab* 文件指定的命令。

如果想要用 bash 来执行，可以 *crontab* 文件中添加 `SHELL=/bin/bash` 这一行。

默认的寻址路径是 "/usr/bin:/bin"，如果需要执行的命令、或者脚本文件没有放在这两个路径下，就需要通过文件路径来指定，建议使用绝对路径。

由于定时任务是由 cron 守护进程来执行，需要确认该进程已经启动，才能执行定时任务，可以使用下面命令来确认 cron 守护进程是否已经启动：
```bash
$ service --status-all |& grep cron
 [ + ]  cron
$ ps -e | grep cron
 2340 ?        00:00:36 cron
```
在 `service --status-all |& grep cron` 命令中，看到 cron 前面显示加号 `+`，表示 cron 守护进程已经启动。

在 `ps -e | grep cron` 命令中，要能查找到 cron 这个名称，说明 cron 这个进程正在运行。

## 设置定时任务的实例
我们在使用 `crontab -e` 命令打开 *crontab* 文件后，可以输入下面的一行：
```
*/5 *  *   *   *  date >> ~/testcron.txt
```
基于前面的说明，第一个 `*/5` 表示每间隔 5 分钟就执行一次，后面四个 `*` 表示在每个月的每一天的每一个小时都执行该任务。

具体执行的命令是 `date >> ~/testcron.txt`，把执行任务时的时间追加写入到 *testcron.txt* 文件。

即，这个定时任务每天都会运行，每间隔 5 分钟就运行一次。可以通过查看  *testcron.txt* 文件来确认是否执行过该任务。

保存文件之后，再过 5 分钟，查看 *testcron.txt* 文件内容如下：
```bash
$ ls
testcron.txt
$ cat testcron.txt
2019年 12月 03日 星期二 14:20:01 CST
```
可以看到，在指定目录下生成了 *testcron.txt* 文件，且该文件内容就是 `date` 命令打印的日期，说明执行过指定的定时任务。

隔了较长时间后，再查看 *testcron.txt* 文件内容如下：
```bash
$ cat testcron.txt
2019年 12月 03日 星期二 14:20:01 CST
2019年 12月 03日 星期二 14:25:01 CST
2019年 12月 03日 星期二 14:30:01 CST
```
可以看到，确实是每隔 5 分钟就写入一次日期到 *testcron.txt* 文件。

## 查看定时任务内容
在 `crontab` 命令中，可以使用 `-l` 选项来查看 *crontab* 文件内容，从而看到里面包含的各个定时任务。

查看 man crontab 对 `-l` 选项的说明如下：
> The -l option causes the current crontab to be displayed on standard output.

这个文件会打印整个 *crontab* 文件内容，包含注释语句。部分内容列举如下：
```
# m h  dom mon dow   command
*/5 *  *   *   *  date >> ~/testcron.txt
```

其实直接执行 `crontab -e` 命令也能看到 *crontab* 文件内容，只是看完之后需要退出编辑器，没有 `crontab -l` 命令方便。

## 删除定时任务
如果要删除某个定时任务，执行 `crontab -e` 命令，从 *crontab* 文件删除对应定时任务所在的行，保存文件即可。也可以注释对应的行，以便后续需要的时候，再打开注释。

如果要删除所有定时任务，可以使用 `-r` 选项。查看 man crontab 对 `-r` 选项的说明如下：
> The -r option causes the current crontab to be removed.

即，`-r` 选项会删除当前用户的 *crontab* 文件，从而删除所有定时任务。
