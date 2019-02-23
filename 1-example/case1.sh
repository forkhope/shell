#!/bin/bash

read -p "Input your choice: " choice
case $choice in
	"Linux")
		echo "Linux!"
		;;
	"Windows")
		echo "Windows!"
		;;
	"")
		echo "Your didn't input your choice."
		;;
	*)
		echo "Your didn't choice a Operating System."
		;;
esac
