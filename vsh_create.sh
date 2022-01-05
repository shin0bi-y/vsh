#!/bin/bash

function printrepertory () {
	end=$(ls -la $directory | grep "^d" | egrep -o '[0-9A-Za-z]+$')
	#Check if it is the end of a branch
	if [ -z "$end" ];then
		echo "directory $directory" >> $headertmp
	else
		echo "directory $directory/" >> $headertmp
	fi
	ls -la $directory > $temp
	#Print the informations needed in temporary files
	while read line;do
		set -- $line
		if [ $1 != "total" ];then
			if [[ -f "$directory/${9-}" ]];then
				nl=$(cat "$directory/$9" | wc -l)
				echo "$9 $1 $5 $countlb $nl" >> $headertmp
				((countlb=countlb+nl))
				cat "$directory/$9" >> $bodytmp
			else
				if ! [[ $9 = "." ]] && ! [[ $9 = ".." ]]; then
					echo "$9 $1 $5" >> $headertmp
				fi
			fi
		fi
	done < $temp
	echo "@" >> $headertmp
}

#Recursive function to analyse the entire tree structure from the current repertory
function rtree () {
	printrepertory
	local list_rep=$(ls -la $directory | egrep '^d[rwx-]{9}' | egrep -o '\.*[0-9A-Za-z]+$')
	if [[ ! -z $list_rep ]];then
		local tmp_directory=$directory
		for rep in $list_rep;do
			directory="$directory/$rep"
			rtree
			directory=$tmp_directory
		done
	fi
}

#Function which concatenate the temporary header part with the temporary body part to create the final archive
assemblyarch () {
	nlheader=$(cat $headertmp | wc -l)
	((startb=starth+nlheader))
	echo "$starth:$startb" >> $arch
	echo "" >> $arch
	cat $headertmp $bodytmp >> $arch

}

#Normalize the archive
normalization () {
	# removes the beginning of every path
	sed -i -r "s\directory $absolute_path/\directory \g" $headertmp

	# turns every "/" into "\"
	sed -i 's/\//\\/g' $headertmp
	#cat $headertmp
}


headertmp=$(mktemp /tmp/headertmp.XXXX)
bodytmp=$(mktemp /tmp/body.XXXX)
temp=$(mktemp /tmp/temp.XXXX)
arch=$(mktemp /tmp/arch.XXXX)

nl=0
starth=3
countlb=1
directory=$(pwd)
absolute_path=$(cd ..; pwd)
cd $directory
rtree
normalization
assemblyarch

rm -rf $temp $headertmp $bodytmp
echo $arch
