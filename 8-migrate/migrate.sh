#!/bin/bash
# 帮助在工程之间迁移文件. 在迁移过程中,如下类型的文件会被删除,不迁移
# *.so库, gsmmux bin文件, pppd bin文件, *.ko驱动文件
# *.rar, *.zip 文件
# *.xls, *.xlsx, *.doc 文件
# *torm 文件, 如果该文件是目录,则整个目录都会被删掉

delete_files=$(find . -name "*.so" -o -name "*.ko" -o -name "pppd*" \
    -o -name "*.xls" -o -name "*.xlsx" -o -name "*.doc" \
    -o -name "*.rar" -o -name "*.zip" -o -name "*torm" \
    -o -name "gsmMux*" -o -name "gsm0710*" -o -name "gsmmux*")

# 当文件名中有空格时,下面的for循环会按空格把文件名分为多个部分,
# 所以文件名里面不要带有空格.
for name in ${delete_files}; do
    echo ${name}
    rm -rv ${name}
done

exit
