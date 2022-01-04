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
			output="c_ls"
			flag=1
			for param in ${@:2}; do
				if ! [[ $param = "-l" ]] && ! [[ $param = "-a" ]] && ! [[ $param = "-al" ]] && ! [[ $param = "-la" ]]; then
                   	flag=0
               	fi
			done
			;;
		"cd")
			# to avoid security flaws
			if [[ $# -eq 2 ]]; then
        		if [[ $2 = "/" ]]; then
					output="c_cd"
					flag=1
				elif [[ ! $2 =~ ";" ]]; then
					# building a jail
					path=$(cd $2 2>/dev/null; pwd)
					pattern="^($VSH_ARCHDIR).*"
                    if [[ $path =~ $pattern ]] && [[ $? -eq 0 ]]; then
						flag=1
					fi
                fi
            fi
			;;
		"pwd")
			if [[ $# -eq 1 ]]; then
                output="c_pwd"
				flag=1
            fi
			;;
		"cat" | "rm" | "touch")
			flag=1
            for path in ${@:2}; do
                pattern="\.\."
                if [[ $path =~ $pattern ]]; then
                    flag=0
                elif [[ ${path::1} = '/' ]]; then
                    p=$(readlink -f $path)
                    pattern="^($VSH_ARCHDIR).*"
                    if ! [[ $p =~ $pattern ]]; then
                        flag=0
                    fi
                fi
            done
			;;
		"mkdir")
			flag=1
			if [[ $# -gt 2 ]] && [[ $2 = "-p" ]]; then
	            for path in ${@:3}; do
    	            pattern="\.\."
        	        if [[ $path =~ $pattern ]]; then
            	        flag=0
					elif [[ ${path::1} = '/' ]]; then
                    	p=$(readlink -f $path)
                    	pattern="^($VSH_ARCHDIR).*"
                    	if ! [[ $p =~ $pattern ]]; then
                        	flag=0
                    	fi
                	fi
            	done
			elif [[ $# -gt 1 ]]; then
				for path in ${@:2}; do
                    pattern="\.\."
                    if [[ $path =~ $pattern ]]; then
                        flag=0
                    elif [[ ${path::1} = '/' ]]; then
                        p=$(readlink -f $path)
                        pattern="^($VSH_ARCHDIR).*"
                        if ! [[ $p =~ $pattern ]]; then
                            flag=0
                        fi
                    fi
				done
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
	rep=$(pwd | sed -e "s#^$VSH_ARCHDIR##")
	echo -n "[ user@vsh $rep ]$> "
	read command
	output=""
	shell $command

	if [ $flag -eq 1 ]; then
		case $output in
			"c_cd")
				# command : cd /
				cd $VSH_ARCHDIR
				;;
			"c_ls")
				# command : ls with flags
				SAVEIFS=$IFS
				IFS=$'\n'
				if [[ $command = "ls" ]]; then
                	out=$(bash -c "ls -l -1")
               	else
					command+=" -1"
					out=$(bash -c $command)
				fi
				for line in $out; do
					is_exec=0
					# skipping first line
					if [[ $line =~ "total" ]]; then
						continue
					fi
					rights=$(echo $line | awk '{print $1}')
					size=$(echo $line | awk '{print $5}')
					name=$(echo $line | awk '{print $9}')
					if [[ $rights =~ "x" ]] && ! [[ ${line:0:1} = "d" ]]; then
                        is_exec=1
                    fi
					if [[ $is_exec -eq 1 ]]; then
                        name+="*"
                    fi
					if [[ $command = "ls" ]]; then
						if [[ ${line:0:1} = "d" ]]; then
							echo "$name\\"
						else
							echo "$name"
						fi
					else
						if [[ ${line:0:1} = "d" ]]; then
                            echo "$rights $size $name\\"
                        else
                            echo "$rights $size $name"
                        fi
					fi
				done
				IFS=$SAVEIFS
				;;
			"c_pwd")
				p=$(pwd)
				res=$(pwd | sed -e "s#^$VSH_ARCHDIR##")
				if [[ $res = "" ]]; then
					echo "\\"
				else
					echo $res
				fi
				;;
			"")
				$command 2>/dev/null
				;;
		esac
	else
		echo "Error, bad path or command not known"
	fi
done

