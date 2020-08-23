# 介绍一个可以左右下移动、以及可旋转方块的 shell 脚本

之前文章介绍过使用 k、j、h、l 键来上下左右移动单个方块的 shell 脚本。

下面继续介绍如何旋转单个方块。

# 执行效果
（FIXME: 把这个执行结果换成终端界面截图）
具体的执行效果如下：
```
Usage: k 键: 旋转方块. j/h/l 键: 下/左/右移动方块. q 键: 退出
  |======================|
  |                      |
  |            []        |
  |          [][]        |
  |          []          |
  |                      |
  |                      |
  |                      |
  |                      |
  |                      |
  |                      |
  |                      |
  |                      |
  |                      |
  |                      |
  |                      |
  |======================|
```
实际执行时，默认显示横向的 Z 字形方块。

可以在边框内部，左右下移动 Z 字形的方块，不能上移。俄罗斯方块不允许上移。

可以按 k 键在横向、竖向之间来回旋转方块。

# 脚本代码
假设有一个 `rotateblock_one.sh` 脚本，具体的代码内容如下所示。

在这个代码中，几乎每一行代码都提供了详细的注释，方便阅读。

这篇文章的后面也会对一些关键点进行说明，有助理解。
```bash
#!/bin/bash
# 实现一个可以左右下移动、以及可旋转的方块,
# 方块的移动和旋转范围限定在指定边框内.
# 只移动和旋转所有形状的 Z 字形方块.

# 下面几个常量指定长方形边框的上下左右边界
# 指定边框左边的列数
FRAME_LEFT=3
# 指定边框右边的列数
FRAME_RIGHT=26
# 指定边框上边的行数
FRAME_TOP=2
# 指定边框下边的行数
FRAME_BOTTOM=18

# 下面的 Z_BLOCKS 数组定义了 Z 字形方块的所有形状.
# 所给的初始值对应横放的 Z 字形方块,具体形状为:
# [][]
#   [][]
# 这里使用行数、列数坐标点的方式来表示每一个小方块的位置.
# 第一个小方块的起始行数、列数都是 0,作为整个方块的原点.
# 第二个小方块和第一个小方块在同一行,行数也是0.每一个小方块
#   显示两个字符,所以第二个小方块的起始列数是 2.
# 第三个小方块在第一个小方块的下一行,行数是 1. 它的列数是 2.
# 第四个小方块和第三个小方块在同一行,行数是 1. 它的列数是 4.
# 使用这些行列数加上方块的起始行列数,就能定位出每个小方块要
# 显示在哪一行、哪一列.之后可以使用ANSI转义码设置光标的位置.
# 前面 8 个数字对应横放的 Z 字形方块.
# 后面 8 个数字对应竖放的 Z 字形方块.
Z_BLOCKS=(\
    0 0 0 2 1 2 1 4\
    0 2 1 0 1 2 2 0\
)
# 上面的 Z_BLOCKS 数组保存 Z 字形方块的所有形状.
# 使用 displayBlockIndex 变量来指向当前显示的方块形状.
# 每个方块形状使用 8 个数字来表示.这个值要基于 8 进行递增.
displayBlockIndex=0

# 这个值加上 Z_BLOCKS 数组里面的小方块行数,
# 会指定每一个小方块要显示在哪一行.
# 其初始值是边框上边行数的下一行.
blockLine=$((FRAME_TOP + 1))
# blockColumn 指定整个方块显示的起始列.
# 这个值加上 Z_BLOCKS 数组里面的小方块列数,
# 会指定每一个小方块要显示在哪一列.
# 其初始值是边框左边列数的下一列.
blockColumn=$((FRAME_LEFT + 1))

# 显示一个长方形边框,作为方块移动的边界范围
function showFrame()
{
    # 设置边框字符的显示属性: 高亮反白显示,绿色文本,绿色背景
    printf "\e[1;7;32;42m"

    local i
    # 下面使用 "\e[line;columnH" ANSI 转义码移动
    # 光标到指定的行和列,然后显示对应的边框边界字符.
    # 行数递增,列数不变,竖向显示边框的左右边界
    for ((i = FRAME_TOP; i <= FRAME_BOTTOM; ++i)); do
        printf "\e[${i};${FRAME_LEFT}H|"
        printf "\e[${i};${FRAME_RIGHT}H|"
    done

    # 列数递增,行数不变,横向显示边框的上下边界
    for ((i = FRAME_LEFT + 1; i < FRAME_RIGHT; ++i)); do
        printf "\e[${FRAME_TOP};${i}H="
        printf "\e[${FRAME_BOTTOM};${i}H="
    done

    # 显示边框之后,重置终端的字符属性为原来的状态
    printf "\e[0m"
}

# 显示或者清除方块.由 displayBlockIndex 指定方块形状.
# 传入的第一个参数为 1,会显示方块.
# 传入的第一个参数为 0,会清除方块.
function drawBlock()
{
    local i squareIndex
    # square 变量保存要显示的小方块内容.
    # 如果内容为 "[]",会显示具体的方块.
    # 如果内容为 "  ",也就是两个空格,会清除方块
    local square
    # line 变量指定某个小方块显示在哪一行
    local line
    # column 变量指定某个小方块显示在哪一列
    local column

    # 所给的第一个参数值为 1,表示要显示具体的方块
    # 所给的第一个参数值为 0,表示要清除当前的方块
    # 方块显示的位置由 blockLine 和 blockColumn 指定
    if [ $1 -eq 1 ]; then
        square="[]"
        # 显示方块时,把方块的背景色设成红色
        printf "\e[41m"
    else
        # 把原先显示的方块内容都替换为空格,显示为空
        square="  "
        # 清除方块时,背景色要显示为原先的颜色
        printf "\e[0m"
    fi

    for ((i = 0; i < 8; i += 2)); do
        # 基于 displayBlockIndex 获取到要显示的小方块index
        squareIndex=$((i + displayBlockIndex))
        # 使用 blockLine 和 Z_BLOCKS 数组指定的小方块行数
        # 来获取每一个小方块要显示在哪一行.
        line=$((blockLine + ${Z_BLOCKS[squareIndex]}))
        # 使用 blockLine 和 Z_BLOCKS 数组指定的小方块列数
        # 来获取每一个小方块要显示在哪一列.
        column=$((blockColumn + ${Z_BLOCKS[squareIndex + 1]}))
        # 使用 "\e[line;columnH" 转义码移动光标到指定的
        # 行和列,然后开始显示对应的小方块.
        printf "\e[${line};${column}H${square}"
    done
}

# 该函数判断是否可以在指定的行和列放置特定形状的方块.
# 如果可以放置,返回 0. 不能放置,返回 1.
function canPlaceBlock()
{
    # 所给的第一个参数指定要移动到的起始行数
    local nextBaseLine="$1"
    # 所给的第二个参数指定要移动到的起始列数
    local nextBaseColumn="$2"
    # 所给的第三个参数指定要放置的方块形状index
    local blockIndex="$3"
    local i squareIndex nextLine nextColumn

    # blockIndex 变量指向当前显示的方块形状index.
    # 下面遍历当前方块的每一个小方块,获取它们
    # 将被显示的行列数,检查是否超过了边框范围.
    # 如果超过,则返回 1,表示不能移动方块到指定的行或列.
    for ((i = 0; i < 8; i += 2)); do
        squareIndex=$((i + blockIndex))
        nextLine=$((nextBaseLine + ${Z_BLOCKS[squareIndex]}))
        nextColumn=$((nextBaseColumn + ${Z_BLOCKS[squareIndex+1]}))

        # 下面两个 if 条件检查接下来要显示的行数、列数是否超过了
        # 边框范围.如果超过,则返回 1,不能放置方块到新的行或列上.
        if ((nextLine<=FRAME_TOP || nextLine>=FRAME_BOTTOM)); then
            return 1
        fi

        if ((nextColumn<=FRAME_LEFT || nextColumn>=FRAME_RIGHT)); then
            return 1
        fi
    done
    # 遍历方块的所有小方块,发现都可以移动,则返回 0
    return 0
}

# 左移方块
function leftMoveBlock()
{
    # 每次左移,要移动一个小方块的距离.每个小方块占据两列,
    # 所以左移后,新的起始列数是在前面第二列,下面要减 2.
    local newBaseColumn=$((blockColumn - 2))
    # bash 的 if 语句可以对任意命令的返回值进行判断,并不是
    # 只能判断 [、[[、(( 等命令的返回值. 下面直接判断
    # canPlaceBlock 函数的返回值.如果返回 0,就是 true.
    if canPlaceBlock "$blockLine" "$newBaseColumn" "$displayBlockIndex"; then
        # 可以移动方块. 先清除原先的方块
        drawBlock 0
        # 更新 blockColumn 的值,以便后续在新的列上显示方块
        ((blockColumn -= 2))
        drawBlock 1
    fi
}

# 右移方块
function rightMoveBlock()
{
    # 每次右移,要移动一个小方块的距离.每个小方块占据两列,
    # 所以右移后,新的起始列数是在后面第二列,下面要加 2.
    local newBaseColumn=$((blockColumn + 2))
    # bash 的 if 语句可以对任意命令的返回值进行判断,并不是
    # 只能判断 [、[[、(( 等命令的返回值. 下面直接判断
    # canPlaceBlock 函数的返回值.如果返回 0,就是 true.
    if canPlaceBlock "$blockLine" "$newBaseColumn" "$displayBlockIndex"; then
        # 可以移动方块. 先清除原先的方块
        drawBlock 0
        # 更新 blockColumn 的值,以便后续在新的列上显示方块
        ((blockColumn += 2))
        drawBlock 1
    fi
}

# 下移方块
function downMoveBlock()
{
    local newBaseLine=$((blockLine + 1))
    if canPlaceBlock "$newBaseLine" "$blockColumn" "$displayBlockIndex"; then
        # 可以移动方块. 先清除原先的方块
        drawBlock 0
        # 更新 blockLine 的值,以便后续在新的行上显示方块
        ((blockLine += 1))
        drawBlock 1
    fi
}

# 基于 displayBlockIndex 的值,获取下一个要显示的
# 方块index.需要检查新的index是否越界,越界则重置为 0.
function getNextBlockIndex()
{
    local nextBlockIndex=$((displayBlockIndex + 8))
    # ${#Z_BLOCKS[@]} 获取 Z_BLOCKS 数组的元素个数.
    # 当 nextBlockIndex 大于数组元素个数时,已经越界,
    # 要重置为 0. 从头开始旋转方块.
    if [ $nextBlockIndex -ge ${#Z_BLOCKS[@]} ]; then
        nextBlockIndex=0
    fi
    # 这里要用 echo 命令输出新的index,以便外面使用
    # $(getNextBlockIndex) 的方式获取这个值.
    # 如果用 return 命令返回,外面要用 $? 获取,不方便.
    echo "$nextBlockIndex"
}

# 旋转方块. 按照俄罗斯方块的规则,不能上移方块.
function rotateBlock()
{
    local newBlockIndex="$(getNextBlockIndex)"
    # 旋转方块后,形状发生变化,要检查是否可以旋转
    if canPlaceBlock "$blockLine" "$blockColumn" "$newBlockIndex"; then
        # 可以旋转成新的方块形状. 先清除原先的方块
        drawBlock 0
        # 更新 displayBlockIndex 的值,指向旋转后的下一个方块形状
        displayBlockIndex="$(getNextBlockIndex)"
        # 显示新的方块
        drawBlock 1
    fi
}

# 重置终端的显示状态为原先的状态
function resetDisplay()
{
    # 把光标显示到边框底部的下一行,
    # 以便终端提示符显示在边框之后,避免错乱
    printf "\e[$((FRAME_BOTTOM + 1));0H"
    # 显示光标
    printf "\e[?25h"
    # 重置终端的字符属性为原来的状态
    printf "\e[0m"
}

# 初始化显示状态.例如显示边框,隐藏光标,等等
function initDisplay()
{
    # 由于方块会显示在指定的行和列,
    # 为了避免已有内容的干扰,先清屏.
    clear
    # 隐藏光标
    printf "\e[?25l"
    # 显示提示字符串
    echo "Usage: k 键: 旋转方块. j/h/l 键: 下/左/右移动方块. q 键: 退出"
    # 显示边框
    showFrame
    # 先显示一个默认的方块
    drawBlock 1
}

initDisplay

# 循环读取用户按键,并进行相应处理
while read -s -n 1 char; do
    case "$char" in
        # h 键要左移一列
        "h") leftMoveBlock ;;
        # l 键要右移一列
        "l") rightMoveBlock ;;
        # j 键要下移一行
        "j") downMoveBlock ;;
        # k 键要旋转方块.俄罗斯方块不能上移方块
        "k") rotateBlock ;;
        # q 键退出
        "q") break ;;
    esac
done

resetDisplay
exit
```

# 代码关键点说明

## 确认旋转后的方块形状
在 `rotateblock_one.sh` 脚本中，定义了一个 *Z_BLOCKS* 数组，保存 Z 字形方块的所有形状。

每个形状使用 8 个数字表示。使用一个 *displayBlockIndex* 变量来指定要显示的方块形状的第一个数字。

当需要旋转到下一个形状时，让 *displayBlockIndex* 变量加上 8，指向下一个方块形状的第一个数字。

之后就可以使用 `drawBlock 1` 语句来显示下一个方块形状。

## 检查方块位置是否超过边框
在前面介绍方块移动的文章里面，硬编码记录方块的长度、高度，然后基于记录的长度、高度值检查方块位置是否超过边框。

但是在当前脚本中，由于旋转方块之后，方块的长度、高度会发生变化。

如果还是硬编码记录每个方块的长度、高度，那么判断起来比较麻烦。

当前脚本定义了一个 *canPlaceBlock* 函数来检查方块位置是否超过边框。

具体思路是，基于方块移动、或者旋转后的位置，获取每一个小方块的行数、列数，然后检查该小方块的显示位置是否超过边框范围。

如果任意一个小方块的显示位置超过边框范围，表示不能在新的位置显示方块。
