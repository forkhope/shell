# 记录 bash wait 内置命令的使用笔记

在 bash 中，可以使用控制操作符 `&` 让命令在后台运行，然后使用 `wait` 内置命令等待任务完成。

# 控制操作符 &
查看 man bash 对控制操作符 `&` 的说明如下：
> If a command is terminated by the control operator &, the shell executes the command in the background in a subshell.  The shell does not wait for the command to finish, and the return status is 0.

即，当要执行的命令以 `&` 结尾时，这个命令会在后台子 shell 执行。当前 shell 不会等待这个命令执行完成，可以继续执行下一个命令。

即，某个命令执行耗时较久时，如果不以 `&` 结尾，当前 shell 会等待该命令执行完成，才能执行下一个命令。而以 `&` 结尾后，这个命令被放到后台子 shell 执行，当前 shell 可以继续执行下一个命令。

# wait 内置命令
查看 help wait 对该命令的说明如下：
> **wait: wait [-n] [id ...]**  
Wait for job completion and return exit status.
Waits for each process identified by an ID, which may be a process ID or a job specification, and reports its termination status. If ID is not given, waits for all currently active child processes, and the return status is zero. If ID is a a job specification, waits for all processes in that job's pipeline.

> If the -n option is supplied, waits for the next job to terminate and returns its exit status.

即，`wait` 命令可以等待指定 PID 的进程执行完成。如果不提供任何参数，则等待当前激活的所有子进程执行完成。

当有多个耗时操作可以并发执行，且这些操作都执行完成后，再进行下一步操作，就可以使用 `wait` 命令来等待这些操作执行完成。类似于下面的语句：
```bash
command1 &
command2 &
wait
```
`command1 &` 命令用 `&` 指定在后台执行 *command1* 命令。如果执行 *command1* 命令需要较长时间，不加 `&` 的话，需要等待 *command1* 执行完成，才能执行下一个命令。加了 `&` 后，在后台执行 *command1* 命令，可以继续执行下一个命令。

类似的，`command2 &` 也是在后台执行 *command2* 命令。

即，通过 `&` 在后台并发执行 *command1*、*command2* 命令，可以更好地利用 CPU 并发能力，加快执行速度。如果先等待 *command1* 执行完成，再来执行 *command2* 命令，可能会比较慢。

之后执行 `wait` 命令，没有提供任何参数，会等待所有激活的的子进程执行完成，在后台执行的子进程也是激活状态。这里会等待 *command1*、*command2* 都执行完成。

这里的 *command1*、*command2* 只是举例用的名称，实际测试时要换成可以执行的命令。
