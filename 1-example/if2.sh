#!/bin/bash

if [ "$1" == "hello" ]; then
	echo "Hello, World."
elif [ "$1" == "" ]; then
	echo "You must input paramters, ex> $0 someword"
else
	echo "The only parameters is 'hello'"
fi
