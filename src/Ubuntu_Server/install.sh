#!/bin/bash
################################################################################
#                                                                              #
#  This bash script is for the initial installation of the Tech Bench          #
#                                                                              #
################################################################################

#  Log File Location
LOGFILE=install.log
#  Minimum PHP Version Required to run Tech Bench
minimumPHPVer=72;
minimumPHPReadable=7.2

#  Variables
PREREQ=true
MANUAL=false

#  Verify the script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"  | tee $LOGFILE
   exit 1
fi

#  Check arguments
while [ "$1" != "" ]; do
	case $1 in
		-m | --manual )	shift
						MANUAL=true
						;;
		* )				main
						exit 1				
	esac
	shift
done

#  Primary script
main()
{
	###  Start installation process  ###
	clear
	tput setaf 4
	echo '##################################################################' | tee $LOGFILE
	echo '#                                                                #' | tee -a $LOGFILE
	echo '#                 Welcome to the Tech Bench Setup                #' 
	echo '#                   Tech Bench Installation Log                  #' >> $LOGFILE
	echo '#                                                                #' | tee -a $LOGFILE
	echo '##################################################################' | tee -a $LOGFILE
	echo '' | tee -a $LOGFILE
	tput sgr0
	printf 'Checking Dependencies...\n\n' | tee -a $LOGFILE

	#  Check prerequisites
	checkApache
	checkMysql
	checkPHP
	
	installLamp

	printf '\n\ndone'
	exit 1
}

#  Check Apache is installed and running
checkApache()
{
    printf 'Apache                                                      ' | tee -a $LOGFILE
    if systemctl is-active --quiet apache2; then
        tput setaf 2
        echo '[PASS]' | tee -a $LOGFILE
	elif [ $MANUAL == 'false' ]; then
		echo -en '[INSTALLING]'
		installLamp
		echo -ne '\b\b\b\bED] '
		echo '[INSTALLED]' >> $LOGFILE
    else	
        tput setaf 1
        echo '[FAIL]' | tee -a $LOGFILE
        PREREQ=false
    fi
    tput sgr0
}

#  Check if MySQL is installed and running
checkMysql()
{
    printf 'MySQL                                                       ' | tee -a $LOGFILE
    if systemctl is-active --quiet mysql; then
        tput setaf 2
        echo '[PASS]' | tee -a $LOGFILE
    else	
        tput setaf 1
        echo '[FAIL]' | tee -a $LOGFILE
        PREREQ=false
    fi
    tput sgr0
}

#  Check if PHP is installed and running the proper version
checkPHP()
{
    printf 'PHP '$minimumPHPReadable'                                                     ' | tee -a $LOGFILE
    if hash php 2>/dev/null; then
        PHPVersion=$(php --version | head -n 1 | cut -d " " -f 2 | cut -c 1,3)
        # minimumRequiredVersion=71;
        if (($PHPVersion >= $minimumPHPVer)); then
            tput setaf 2
            echo '[PASS]' | tee -a $LOGFILE
        else
            tput setaf 1
            echo '[FAIL]' | tee -a $LOGFILE
            PREREQ=false
        fi
    else
        tput setaf 1
        echo '[FAIL]' | tee -a $LOGFILE
        PREREQ=false
    fi
    tput sgr0
}












#  Install the LAMP Stack 
installLamp()
{
	apt-get update > /dev/null
	apt-get install lamp-server^ -y > /dev/null
}


main



