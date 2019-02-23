#!/bin/bash
# 当要 cd 到多级的上层目录时,需要输入 cd ../../../ 等等多个 "../",为了简化
# 这个输入,该脚本将接收一个数字,表示要返回几级的上层目录,例如 cdup.sh 3 等
# 价于 cd ../../../, 为了让脚本执行结束后,还保持在cd后的目录,需要用source
# 命令在shell中执行该脚本.可以在~/.bashrc中添加如下别名来方便执行:
# alias up='source ~/bin/cdup.sh'

show_help()
{
printf "USAGE
        cdup.sh number
OPTIONS
        number: 要返回的几级的上层目录. 例如cdup.sh 3等价于 cd ../../../
"
}

UPDIR_PATH="../"
# 根据传入的数字参数,计算要返回到几级上层目录,并将结果写到标准输出
count_updir_number()
{
    local count updir

    count=$1
    updir=""
    while [ $((--count)) -ge 0 ]; do
        updir+=${UPDIR_PATH}
    done
    echo ${updir}
}

if [ $# -ne 1 ]; then
    show_help
    return 1
fi

target_dir=$(count_updir_number $1)
cd ${target_dir}

return
