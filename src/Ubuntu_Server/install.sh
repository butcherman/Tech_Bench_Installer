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
MODULE=true
MANUAL=false

#  File Locations
WEBROOT=\/var\/www\/html

#  Install Data Variables
WebURL=localhost.com
SSLOnly=true
DBName=tech-bench
DBUser=tbUser
DBPass=null
VIRDIR=true

#  Verify the script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"  | tee $LOGFILE
   exit 1
fi

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
	
	printf 'Before we get started, lets gather some information from you'

	#  Get the full URL of the Tech Bench site
	printf '\n\nPlease enter the full url that will be used for the Tech Bench: \n'
	printf '(ex. techbench.domain.com)\n' 
	read -p "Enter URL [$WebURL]:  " WebURL
	echo ''
	read -p 'Use HTTPS for Tech Bench Access (Recommended) [y/n]: ' SSLOnly
	if [[ $SSLOnly =~ [Nn]$ ]]; then	
		SSLOnly=false
	else
		SSLOnly=true
	fi
	
	#  Additional questions if Manual installation is selected
	if [[ $MANUAL == 'true' ]]; then	
		#  Root directory where PHP files are served from
		echo ''
		read -p 'What is the Web Server Root Directory where the Tech Bench files are loaded to? ['$WEBROOT']:  ' WEBROOT
		
		#  Name of the database to use
		echo ''
		read -p 'Please enter the name of the database to hold the Tech Bench data ['$DBName']:  ' DBName
		
		#  Username and password to access database
		while true; do
			read -p 'Please enter the name of the database user:  ' DBUser
			read -p 'Please enter the password of the database user:  ' -s DBPass

			if [[ $DBUser != 'root' ]]; then
				break
			fi

			printf '\n\n Using the "root" database user can be very insecure.'
			read -p 'Are you sure you want to continue with this database user? [y/n]'  cont  

			if [[ $cont =~ ^[Yy]$ ]]; then
				break
			fi
		done
		
		#  Ask if virtual directories are already built
		echo ''
		read -p 'Build custom virtual sites for Tech Bench (Recommended)? [Y/N]: ' VIRDIR
		if [[ $VIRDIR =~ [Nn]$ ]]; then	
		VIRDIR=false
		else
			VIRDIR=true
		fi
	fi
	
	#  Check prerequisites
	printf 'Checking Dependencies...\n\n' | tee -a $LOGFILE
	checkPrereqs



	
	
	
	
	
	
	
	
	
	
	

	printf '\n\ndone\n\n'
	exit 1
}

help()
{
	echo 'help menu'
	#  TODO - Create a help menu
}

#  Only run the prerequisite check and exit
check()
{
	MANUAL=true
	clear
	tput setaf 4
	echo '##################################################################' 
	echo '#                                                                #' 
	echo '#                 Welcome to the Tech Bench Setup                #' 
	echo '#                                                                #' 
	echo '##################################################################' 
	echo '' | tee -a $LOGFILE
	tput sgr0
	
	#  Check prerequisites
	printf 'Checking Dependencies...\n\n' | tee -a $LOGFILE
	checkPrereqs
}

#  Check prerequisites
checkPrereqs()
{
	#  Check for web server
	checkApache
	checkMysql
	checkPHP
	
	#  Check proper modules are installed
	checkModules
	
	#  Check third party software is installed for package management
	checkComposer
	checkNodeJS
	checkNPM
	checkUnzip
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
		apt-get -q update > $LOGFILE
		apt-get -q install lamp-server^ -y > $LOGFILE
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

#  Make sure that all of the needed PHP modules are installed
checkModules()
{
	#  PHP-XML Module
	printf 'PHP-XML Module                                              ' | tee -a $LOGFILE
	XMLMod=$(php -m | grep -c xml)
	
	if (( $XMLMod > 0 )); then
		tput setaf 2
            echo '[PASS]' | tee -a $LOGFILE
	elif [ $MANUAL == 'false' ]; then
		echo -en '[INSTALLING]'
		apt-get install php-xml -y > $LOGFILE
		echo -ne '\b\b\b\bED] '
		echo '[INSTALLED]' >> $LOGFILE
    else	
        tput setaf 1
        echo '[FAIL]' | tee -a $LOGFILE
        PREREQ=false
    fi
    tput sgr0
		
	#  PHP-ZIP Module
	printf 'PHP-ZIP Module                                              ' | tee -a $LOGFILE
	ZIPMod=$(php -m | grep -c zip)
	
	if (( $ZIPMod > 0 )); then
		tput setaf 2
            echo '[PASS]' | tee -a $LOGFILE
	elif [ $MANUAL == 'false' ]; then
		echo -en '[INSTALLING]'
		apt-get install php-zip -y > $LOGFILE
		echo -ne '\b\b\b\bED] \n'
		echo '[INSTALLED]' >> $LOGFILE
    else	
        tput setaf 1
        echo '[FAIL]' | tee -a $LOGFILE
        PREREQ=false
    fi
    tput sgr0
		
	#  PHP-GD Module
	printf 'PHP-GD Module                                               ' | tee -a $LOGFILE
	GDMod=$(php -m | grep -c gd)
	
	if (( $GDMod > 0 )); then
		tput setaf 2
            echo '[PASS]' | tee -a $LOGFILE
	elif [ $MANUAL == 'false' ]; then
		echo -en '[INSTALLING]'
		apt-get install php-gd -y > $LOGFILE
		echo -ne '\b\b\b\bED] '
		echo '[INSTALLED]' >> $LOGFILE
    else	
        tput setaf 1
        echo '[FAIL]' | tee -a $LOGFILE
        PREREQ=false
    fi
    tput sgr0
}

# Check if Composer is installed
checkComposer()
{
	printf 'Composer                                                    ' | tee -a $LOGFILE
	composer -v > /dev/null 2>&1
	COMPOSER=$?
	if [[ $COMPOSER -ne 0 ]]; then
		if [ $MANUAL == 'false' ]; then
			echo -en '[INSTALLING]'
			apt-get install composer -y > $LOGFILE
			echo -ne '\b\b\b\bED] \n'
			echo '[INSTALLED]' >> $LOGFILE
		else
			tput setaf 1
			echo '[FAIL]' | tee -a $LOGFILE
			PREREQ=false
		fi
	else
		tput setaf 2
		echo '[PASS]' | tee -a $LOGFILE
	fi
	tput sgr0
}

# Check if NodeJS is installed
checkNodeJS()
{
	printf 'NodeJS                                                      ' | tee -a $LOGFILE
	node -v > /dev/null 2>&1
	NODE=$?
	if [[ $NODE -ne 0 ]]; then
		if [ $MANUAL == 'false' ]; then
			echo -en '[INSTALLING]'
			apt-get install nodejs -y > $LOGFILE
			echo -ne '\b\b\b\bED] \n'
			echo '[INSTALLED]' >> $LOGFILE
		else
			tput setaf 1
			echo '[FAIL]' | tee -a $LOGFILE
			PREREQ=false
		fi
	else
		tput setaf 2
		echo '[PASS]' | tee -a $LOGFILE
	fi
	tput sgr0
}

checkNPM()
{
	# Check if NPM is installed
	printf 'NPM                                                         ' | tee -a $LOGFILE
	npm -v > /dev/null 2>&1
	NODE=$?
	if [[ $NODE -ne 0 ]]; then
		if [ $MANUAL == 'false' ]; then
			echo -en '[INSTALLING]'
			apt-get install npm -y > $LOGFILE
			echo -ne '\b\b\b\bED] \n'
			echo '[INSTALLED]' >> $LOGFILE
		else
			tput setaf 1
			echo '[FAIL]' | tee -a $LOGFILE
			PREREQ=false
		fi
	else
		tput setaf 2
		echo '[PASS]' | tee -a $LOGFILE
	fi
	tput sgr0
}

checkUnzip()
{
	# Check if Unzip is installed
	printf 'Unzip                                                       ' | tee -a $LOGFILE
	unzip -v > /dev/null 2>&1
	NODE=$?
	if [[ $NODE -ne 0 ]]; then
		tput setaf 1
		echo '[FAIL]' | tee -a $LOGFILE
		PREREQ=false
	else
		tput setaf 2
		echo '[PASS]' | tee -a $LOGFILE
	fi
	tput sgr0
}











#  Check arguments
while [ "$1" != "" ]; do
	case $1 in
		-m | --manual )	shift
						MANUAL=true
						main
						exit 1
						;;
		-c | --check )	shift	
						check
						exit 1
						;;
		-h | --help )	shift
						help
						exit 1
						;;
		* )				main
						exit 1				
	esac
	shift
done

main

exit 0
