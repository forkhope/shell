#!/bin/bash

case $1 in
	"tianxia")
		echo "TianXiaYouQingRen."
		;;
	"yitian")
		echo "YiTianTuLong."
		;;
	"")
		echo "You must input paramters, ex> $0 someword!"
		;;
	*)
		echo "Usage $0 {tian}"
		;;
esac
