#!/bin/bash

# Todo : replace w/ the argument passed to this script
# ex : ./vsh_shell.sh <arch_name>
# in order to jail the user into the archive he asked to browse
export VSH_ARCHDIR="/home/vsh/browse/$1"

# shell function
# takes a basic command as arguments
function shell() {
	flag=0
	case $1 in
		"ls")
			if [[ $# -eq 1 ]]; then
				flag=1
			elif [[ $# -eq 2 ]] && [[ $2 = "-l" ]]; then
				flag=1
			fi
			;;
		"cd")
			# to avoid security flaws
			if [[ $# -eq 2 ]]; then
        		if [[ ! $2 =~ ";" ]]; then
					# building a jail
					path=$(cd $2; pwd)
					pattern="^($VSH_ARCHDIR).*"
                    if [[ $path =~ $pattern ]]; then
						flag=1
					fi
                fi
            fi
			;;
		"pwd")
			if [[ $# -eq 1 ]]; then
                flag=1
            fi
			;;
		"cat")
            if [[ $# -eq 1 ]]; then
                flag=1
            fi
			;;
		"rm")
			# the most dangerous command
			# needs security...
			if [[ $# -eq 2 ]]; then
                if ! [[ $2 =~ ".*(\.\.).*" ]]; then
				    flag=1
				fi
            fi
			;;
		"exit")
			exit
			;;
	esac
	return $flag
}


# where we read the user's input and make the shell function persistant
while [[ 1 -eq 1 ]]; do
	echo -n "$> "
	read command
	shell $command

	if [ $flag -eq 1 ]; then
		$command
	else
		echo "Error"
	fi
done
