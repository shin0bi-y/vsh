#!/bin/bash

# function that verifies if $1 is a valid ip adress
verify_ipaddr() {
	pattern="^([0-9]{1,3}\.){3}[0-9]{1,3}$"
	if [[ ! $1 =~ $pattern ]] && [ ! $1 = "localhost" ]; then
		echo "Bad syntax !"
        echo "Choose a correct IP Adress"
		exit
	fi
}

# function that verifies if $1 is a valid port number
verify_port() {
	pattern="[0-9]+"
    if [[ ! $1 =~ $pattern ]]; then
        echo "Bad syntax !"
		echo "Choose a correct port number"
        exit
    fi
}

case $1 in
	"-create")
		if [ $# -ne 4 ];then
			echo "Bad syntax !"
			echo "Syntax: vsh -create <ip> <port> <archive_name>"
			exit
		fi
		echo -n "Enter your SSH password: "
		read -s password; echo
		# First, we verify that the server does not have an archive with the same name
		archives=$(sshpass -p $password ssh vsh@$2 -p $3 "ls archives/" 2>/dev/null)
		if [[ $? -ne 0 ]]; then
			echo "Cannot login with ssh"
			echo "Exiting..."
			exit
		fi
		pattern="\b$4\b"
		if [[ $archives =~ $pattern ]]; then
			echo "This VSH server already has an archive called '$4'"
			echo "Would you like to overwrite it ? [Y/n]"
			read rep
			if ! [[ $rep = "Y" ]]; then
				echo "Exiting..."
				exit
			fi
		fi
		arch_path=$(bash /opt/vsh/vsh_create.sh)
        verify_ipaddr $2
        verify_port $3
        sshpass -p $password scp -P $3 $arch_path vsh@$2:archives/$4 >> /dev/null
        if [[ $? -ne 0 ]]; then
            echo Exiting...
            exit
        fi
		echo "$4 has been successfully uploaded on the server !"
		;;
	"-list")
		if [ $# -ne 3 ]; then
            echo "Bad syntax !"
            echo "Syntax: vsh -list <ip> <port>"
            exit
        fi
		echo -n "Enter your SSH password: "
        read -s password; echo
		verify_ipaddr $2
		verify_port $3
		sshpass -p $password ssh vsh@$2 -p $3 "ls archives/"
	    ;;
	"-browse")
		if [ $# -ne 4 ];then
            echo "Bad syntax !"
            echo "Syntax: vsh -browse <ip> <port> <archive_name>"
            exit
        fi
		verify_ipaddr $2
        verify_port $3
		echo -n "Enter your SSH password: "
        read -s password; echo
        archives=$(sshpass -p $password ssh vsh@$2 -p $3 "ls archives/" 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            echo Exiting...
            exit
        fi
		pattern="\b$4\b"
		if ! [[ $archives =~ $pattern ]]; then
            echo "This VSH server doesn't have an archive called '$4'"
            echo "Exiting..."
            exit
        fi
		sshpass -p $password ssh vsh@$2 -p $3 "mkdir /home/vsh/browse/$4 && cd /home/vsh/browse/$4; bash /opt/vsh/vsh_extract.sh /home/vsh/archives/$4 >> /dev/null"
		sshpass -p $password ssh vsh@$2 -p $3 "cd browse/$4/*; bash /opt/vsh/vsh_shell.sh $4"
		arch_path=$(sshpass -p $password ssh vsh@$2 -p $3 "cd /home/vsh/browse/$4/*; bash /opt/vsh/vsh_create.sh")
		sshpass -p $password ssh vsh@$2 -p $3 "rm -rf /home/vsh/archives/$4; cp $arch_path /home/vsh/archives/$4; rm -rf /home/vsh/browse/$4"
		;;
	"-extract")
		if [ $# -ne 4 ];then
            echo "Bad syntax !"
            echo "Syntax: vsh -extract <ip> <port> <archive_name>"
            exit
        fi
		verify_ipaddr $2
		verify_port $3
		echo -n "Enter your SSH password: "
        read -s password; echo
        # We verify that the server does have an archive with this name
        archives=$(sshpass -p $password ssh vsh@$2 -p $3 "ls archives/$4" 2>/dev/null)
        pattern="\b$4\b"
		if ! [[ $archives =~ $pattern ]]; then
            echo "This VSH server does not have an archive called '$4'"
			exit
		fi
		# Downloading the archive
		sshpass -p $password scp -P $3 vsh@$2:archives/$4 ./ >> /dev/null
		bash /opt/vsh/vsh_extract.sh $4 >> /dev/null
		rm -rf $4
		;;
	"-delete")
		if [ $# -ne 4 ];then
            echo "Bad syntax !"
            echo "Syntax: vsh -delete <ip> <port> <archive_name>"
            exit
        fi
		if [[ $4 =~ ".." ]]; then
            echo "'..' isn't allowed in an archive name !"
			exit
        fi
        verify_ipaddr $2
        verify_port $3
		echo -n "Enter your SSH password: "
        read -s password; echo
		# We verify that the server does have an archive with this name
        archives=$(sshpass -p $password ssh vsh@$2 -p $3 "ls archives/$4" 2>/dev/null)
		sshpass -p $password ssh vsh@$2 -p $3 "rm archives/$4"
		;;
	*)
		echo "---vsh command---"
        echo "Options :"
        echo
        echo "vsh -list <ip> <port> : Returns what archives are stored on the server"
        echo
        echo "vsh -create <ip> <port> <archive_name> : Creates an archive on the server based on the current directory"
        echo
        echo "vsh -extract <ip> <port> <archvive_name> : Extracts the content of a distant archive in the current directory"
        echo
        echo "vsh -browse <ip> <port> <archive_name> : Allows the user to browse a distant archive"
        echo
        echo "vsh -delete <ip> <port> <archive_name> : Deletes an archive on the server"
        echo
        echo "vsh -help : Prints this manual"
        echo
		;;
esac
