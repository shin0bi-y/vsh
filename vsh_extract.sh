#!/bin/bash

function rights()
{
	listrights=$(echo $giverights | cut -d" " -f2 | egrep -o "[xwr-]{9}$" | sed "s/^\(...\)\(...\)\(...\)$/\1 \2 \3/g")
	i=0
	octal=( "0" "0" "0" )
	for r in $listrights;do
		if [ ! -z $(echo "$r" | egrep "r") ];then
			((octal[$i]+=4))
		fi
		if [ ! -z $(echo "$r" | egrep "w")  ];then
			((octal[$i]+=2))
		fi
		if [ ! -z $(echo "$r" | egrep "x") ];then
			((octal[$i]+=1))
		fi
		((i++))
	done
	echo "$listrights : ${octal[0]}${octal[1]}${octal[2]}"
}

function createaccesspath()
{
	path=$(echo $line | cut -d" " -f2- | sed "s/\// /g")
	currentrep=$(echo $path | rev | cut -d" " -f 1 | rev)
	for rep in $path;do
		createaccesspath="$createaccesspath/$rep"
		if [ $rep != $currentrep ];then
			mkdir $createaccesspath
			echo $createaccesspath
		fi
	done
	flag=1
	echo "____$createaccesspath"
}

function createfile()
{
	file=$(echo $line | cut -d" " -f1)
	echo $file
	startb=$(echo $line | cut -d" " -f4)
	nlbody=$(echo $line | cut -d" " -f5)
	echo "IN CREATE FILE" $fullpath $directory $file
	tail -n +$startb $bodytmp | head -n +$nlbody > "$fullpath/$directory/$file"
	giverights=$line
	rights
	chmod ${octal[0]}${octal[1]}${octal[2]} $fullpath/$directory/$file
}

function createrepertory()
{
	directory=$(echo $line | cut -d" " -f2-)
	if [[ ${directory: -1} = "/" ]]; then
		directory=${directory::-1}
	fi
	finaldirectory=$(echo $directory | rev | cut -d'/' -f 1 | rev)
	echo $finaldirectory
	mkdir "$fullpath/$directory"
	if [ "$createaccesspath/" != "$fullpath/$directory" ];then
		giverights=$(egrep "^$finaldirectory\sd[rwx-]{9}\s[0-9]+" $headertmp)
	# 	TODO : FIX CHMOD ON DIRECTORIES !
		if [[ $flag_chmod_rep -ne 0 ]]; then
			rights
    	    chmod ${octal[0]}${octal[1]}${octal[2]} "$fullpath/$directory"
		else
			flag_chmod_rep=1
		fi
	fi
}

arch_path=$(readlink -e $1)
starth=$(head -1 $arch_path | cut -d":" -f1)
startb=$(head -1 $arch_path | cut -d":" -f2)
headertmp=$(mktemp /tmp/headertmp.XXXX)
bodytmp=$(mktemp /tmp/bodytmp.XXXX)
#fullpath=$(pwd | egrep -o "\/[^\/]+\/[^\/]+\/?" | sed "s/\/$//" )
fullpath=$(pwd)
echo $fullpath
tail -n +$starth $1 | head -n +$((startb-starth)) >> $headertmp
tail -n +$startb $arch_path >> $bodytmp
sed -i 's/\\/\//g' $headertmp
flag=0

flag_chmod_rep=0
while read line; do
	if [ "$(echo $line | egrep "^directory [^ ]+$")" ];then
		if [ $flag -eq 0 ];then
			createaccesspath
		fi
		echo "------------------------"
		createrepertory
	elif [ "$(echo $line | egrep "^[^ ]+\s-[rxw-]{9}\s[0-9]+\s?[0-9]*\s?[0-9]*")" ];then
		createfile
	fi
done < $headertmp

