#!/bin/bash
search=compact.php
w3m -no-cookie -dump http://dict.cn/${search}?q=$1 | tac | sed '1,2d' | tac | sed -n '3,$p'
