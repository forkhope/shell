# 记录 bash array 的相关笔记

# Bash 的关联数组 (associative arrays) 详解
Bash 支持关联数组(associative arrays)，可以使用任意的字符串、或者整数作为下标来访问数组元素。关联数组的下标和值称为键值对，它们是一一对应关系，键是唯一的，值可以不唯一。

要使用关联数组之前，需要用 `declare -A array_name` 来进行显式声明 *array_name* 变量为关联数组。查看 help declare 对 `-A` 选项的说明如下：
>**-A**  
to make NAMEs associative arrays (if supported)

例如下面的语句定义了一个名为 filetypes 的关联数组，并为数组赋值：
```bash
$ declare -A filetypes=([txt]=text [sh]=shell [mk]=makefile)
$ filetypes[c]="c source file"
```
在使用数组名进行赋值时，需要用小括号 `()` 把所有的值括起来。在关联数组里面，用方括号 `[]` 括起来的值是 key，为方括号 `[]` 赋予的值是该 key 对应的 value，不同的键值对之间用空格隔开。

也可以使用 `filetypes[key]=value` 的方式单独为指定的关联数组元素赋值。如果所给的 *key* 之前不存在，bash 会自动创建它。如果已经存在，则修改它的值为 *value* 对应的值。

基于 *filetypes* 这个数组名，说明关联数组的常用操作如下：
- `${!filetypes[*]}`：获取关联数组的所有键名，注意在 *filetypes* 前面有一个感叹号 `!`。
```bash
$ echo ${!filetypes[*]}
txt sh c mk
```
- `${!filetypes[@]}`: 获取关联数组的所有键名。后面会说明使用 `*` 和 `@` 的区别。
```bash
$ echo ${!filetypes[@]}
txt sh c mk
```
- `${filetypes[*]}`：获取关联数组的所有值。相比于获取键名的表达式，少了前面的感叹号 `!`。
```bash
$ echo ${filetypes[*]}
text shell c source file makefile
```
- `${filetypes[@]}`：获取关联数组的所有值。
```bash
$ echo ${filetypes[@]}
text shell c source file makefile
```
- `${#filetypes[*]}`：获取关联数组的长度，即元素个数。注意在 *filetypes* 前面有一个井号 `#`。
```bash
$ echo ${#filetypes[*]}
4
```
- `${#filetypes[@]}`：获取关联数组的长度，即元素个数
```bash
$ echo ${#filetypes[@]}
4
```
- `${filetypes[key]}`：获取 *key* 这个键名对应的值。注意大括号 `{}` 是必须的。
```bash
$ echo ${filetypes[sh]}
shell
$ echo $filetypes[sh]
[sh]        # 可以看到，不加大括号时，并不能获取到数组元素的值
```
查看 man bash 的 *Arrays* 部分，说明了这几个表达式的含义，同时还提到使用 `*` 和 `@` 的区别，贴出具体的区别如下：
> If the word is double-quoted, ${name[*]} expands to a single word with the value of each array member separated by the first character of the IFS special variable, and ${name[@]}  expands  each  element  of  name  to a separate word.  When there are no array members, ${name[@]} expands to nothing.

> ${!name[@]} and ${!name[*]} expand to the indices assigned in array variable name.  The treatment when in double quotes is similar to the expansion of the special parameters @ and * within double quotes.

即，使用 `*` 时，如果用双引号把整个表达式括起来，例如 `"${!name[*]}"`、或者 `"${name[*]}"`，那么会把所有值合并成一个字符串。使用 `@` 时，如果用双引号把整个表达式括起来，例如 `"${!name[@]}"`、或者 `"${name[@]}"`，那么会得到一个字符串数组，每个数组元素会用双引号括起来，所以数组元素自身的空格不会导致拆分成几个单词。具体如下面的例子所示：
```bash
$ for key in "${filetypes[*]}"; do echo "****:" $key; done
****: text shell c source file makefile
$ for key in "${filetypes[@]}"; do echo "@@@@:" $key; done
@@@@: text
@@@@: shell
@@@@: c source file
@@@@: makefile
```
可以看到，`"${filetypes[*]}"` 只产生一个字符串，for 循环只遍历一次。而 `"${filetypes[@]}"` 产生了多个字符串，for 循环遍历多次，是一个字符串数组，而且 "c source file" 这个字符串没有被空格隔开成几个单词。

这个例子也演示了如何用 `for` 命令来遍历数组元素。

可以使用 `declare -p` 命令来查看数组具体的键值对关系：
```bash
$ declare -p filetypes
declare -A filetypes='([txt]="text" [sh]="shell" [c]="c source file" [mk]="makefile" )'
```

# Bash 的一维数组 (one-dimensional indexed array) 详解
Bash 只支持一维数组 (one-dimensional indexed array)，不支持二维数组。声明数组的方式是 `declare -a array_name`。由于 bash 不要求明确指定变量的类型，其实不声明也可以，按数组的方式直接赋值给变量即可。查看 help declare 对 `-a` 选项的说明如下：
> **-a**  
to make NAMEs indexed arrays (if supported)

使用 `declare -a` 声明的数组，默认以数字作为数组下标，而且不需要指定数组长度，其赋值方式说明如下：
- array=(value1 value2 value3 ... valueN)：这种方式从数组下标 0 开始为数组元素赋值，不同值之间用空格隔开，所给的值可以是数字、字符串等。
```bash
$ declare -a array=(1 2 "30" "40" 5)
$ echo ${array[@]}
1 2 30 40 5
```
- array=([0]=var1 [1]=var2 [2]=var3 ... [n]=varN)：这种方式显式提供数组下标，指定为该元素赋值，所给的数组下标可以不连续。
```bash
$ declare -a array=([0]=1 [1]=2 [3]="30" [6]="60" [9]=9)
$ echo ${array[@]}    # 用 ${array[@]} 获取所有数组元素的值
1 2 30 60 9
$ echo ${array[5]}    # 上面赋值的时候，跳过了数组下标5，所以它对应的值为空

$ declare -p array    # 使用 declare -p 命令查看，会打印出被赋值的所有元素
declare -a array='([0]="1" [1]="2" [3]="30" [6]="60" [9]="9")'
```
- array[0]=value1; array[1]=value2; ...; array[n]=varN：这种方式是单独为数组元素赋值。
```bash
$ unset array; declare -a array
$ array[0]=0; array[1]=1; array[7]="70"
$ declare -p array
declare -a array='([0]="0" [1]="1" [7]="70")'
```

一维数组的其他用法和关联数组用法一样。例如，可以用 `${array[@]}` 获取所有数组元素的值，用 `${#array[@]}` 获取数组的元素个数，等等。

一维数组通过正整数来索引数组元素。如果提供负整数的下标值，那么它具有特殊含义，表示从数组末尾开始往前索引，例如，`array[-1]` 会索引到数组的最后一个元素，`array[-2]` 索引到数组的倒数第二个元素，依此类推。
```bash
$ declare -a array=([0]=0 [1]=1 [2]="20" [3]=3)
$ echo ${array[-1]}, ${array[-3]}
3, 1
```

**注意**：虽然 `declare -a` 声明的数组要用数字作为数组下标，但是使用字符串作为数组下标不会报错，实际测试有一些比较古怪的地方。具体举例如下：
```bash
$ declare -a array=([0]=0 [1]=1 [2]="20" [3]=3)
$ array[index]=1000
$ echo ${array[index]}
1000
$ array[new]=2000
$ echo ${array[index]}
2000
$ echo ${array[new]}
2000
$ declare -p array
declare -a array='([0]="2000" [1]="1" [2]="20" [3]="3")'
```
可以看到，为 `array[index]` 元素赋值，没有报错，使用 `${array[index]}` 可以正常获取到它的值。但是为 `array[new]` 赋值为 2000 后，使用 `${array[index]}` 打印 *index* 这个字符串下标对应的数组元素值，发现变成了 2000，跟 `${array[new]}` 打印的值一样。看起来，就像是这两个字符串下标关连到同一个数组元素。实际上，它们都对应到数组元素 0，`declare -p array` 可以看到 `[0]` 的值变成了 2000。查看 man bash 的 *Arrays* 部分，说明如下：
> Indexed arrays are referenced using integers (including arithmetic expressions)  and are zero-based;

> An indexed array is created automatically if any variable is assigned to using the syntax name[subscript]=value.  The subscript is treated as an arithmetic expression that must evaluate to a number.

> Referencing an array variable without a subscript is equivalent to referencing the array with a subscript of 0.

即，indexed array 的下标一定是数字、或者是经过算术表达式 (arithmetic expressions) 计算得到的数字。如果没有提供数组下标，默认会使用数组下标 0。

由于 bash 的算术表达式在获取变量值时，不需要使用 `$` 符号，所以上面的 `array[index]` 实际上相当于 `array[$index]`，也就是获取 *index* 变量的值来作为数组下标。如果这个变量没有值，就相当于没有提供数组下标，默认使用数组下标 0，所以为 `array[index]` 赋值，实际上是为 `array[0]` 赋值。同理，为 `array[new]` 赋值，也是为 `array[0]` 赋值，会看到 `array[index]` 的值也跟着改变。

如果 *index* 变量的值不是 0，而且 *new* 变量没有值，那么为 `array[index]` 赋值，将不会影响到 `array[new]`。在上面例子的基础上，继续执行下面语句：
```bash
$ index=1
$ array[index]=100
$ echo "array[index] = ${array[index]}, array[1] = ${array[1]}"
array[index] = 100, array[1] = 100
$ array[new]=900
$ echo "array[new] = ${array[new]}, array[0] = ${array[0]}, array[index]=${array[index]}"
array[new] = 900, array[0] = 900, array[index]=100
$ recurse=index
$ array[recurse]=500
$ echo "array[index] = ${array[index]}, array[recurse] = ${array[recurse]}, array[1] = ${array[1]}"
array[index] = 500, array[recurse] = 500, array[1] = 500
```
可以看到，将 *index* 变量赋值为 1，修改 `array[index]` 的值，则改变的是数组下标 1 对应的元素、也就是 `array[1]` 的值。即相当于用 `$index` 获取该变量的值来作为数组下标。此时，由于没有为 *new* 变量赋值，修改 `array[new]` 的值还是关连到 `array[0]`，不会影响到 `array[index]`。

如果将变量赋值为字符串，那么会往下递归获取该字符串对应的变量值。上面将 *recurse* 赋值为 "index" 字符串，修改 `array[recurse]` 的值，可以看到 `array[1]` 的值被改变了。即相当于先用 `$recurse` 获取 *recurse* 变量的值是 "index"，发现是字符串，继续把 "index" 字符串作为变量名，用 `$index` 来获取 *index* 变量的值是 1，最终使用 1 作为数组下标。
