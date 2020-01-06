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

#  Include Files
# source function/dependency_functions.sh

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

#  Check the dependencies to make sure they are installed
checkApache
checkMysql
checkPHP
# checkApacheRewrite
checkComposer

#  Check if all prerequesits have passed or not.  If a prereq fails, exit script
if test $PREREQ = false; then
	printf '\n\nOne or more prerequesits has failed.\nPlease install the missing prerequesits and run this installer again.\n\n' | tee -a $LOGFILE
	exit 1
fi
printf '\nLooking Good - lets move on...\n\n' | tee -a $LOGFILE

###  Gather Information for the Install  ###

while true; do
	gatherData
	###  Verify all the information is correct ###
	print -f '\n\nPlease Verify the Information is Correct:\n\n'
	echo 'Webroot Directory:          ' $RootDir
	echo 'Tech Bench URL:             ' $WebURL
	echo 'Database Name               ' $DBName
	echo 'Database User               ' $DBUser
	echo 'Database Password            <redacted>'
	read -p 'Would you like to continue? [y/n]'  doInstall  

	if [[ $doInstall =~ ^[Yy]$ ]]; then
		break
	fi	
done



exit 1




###  Dependency Functions ###
#  Check Apache is installed and running
checkApache()
{
    printf 'Apache                                                      ' | tee -a $LOGFILE
    if systemctl is-active --quiet apache2; then
        tput setaf 2
        echo '[PASS]' | tee -a $LOGFILE
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

#  Check if the Apache Rewrite Module is installed
checkApacheRewrite()
{
    if $PREREQ; then
        REWRITE=$(apachectl -M | grep 'rewrite_module' > /dev/null 2>&1)
        printf 'Rewrite Module                                              ' | tee -a $LOGFILE
        if $REWRITE; then
            tput setaf 2
            echo '[PASS]' | tee -a $LOGFILE
        else	
            tput setaf 1
            echo '[FAIL]' | tee -a $LOGFILE
            PREREQ=false
        fi
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
        tput setaf 1
        echo '[FAIL]' | tee -a $LOGFILE
        PREREQ=false
    else
        tput setaf 2
        echo '[PASS]' | tee -a $LOGFILE
    fi
    tput sgr0
}

###  Gather Informaiton Function 
gatherData()
{
	#  Install variables
	CurDir=`pwd`

	#  Root directory where PHP files are served from
	read -p 'What is the Web Server Root Directory where the Tech Bench files are loaded to? ['$CurDir']:  ' RootDir
	RootDir=${RootDir:$curDir}

	#  Get the full URL of the Tech Bench site
	printf '\n\nPlease enter the full url that will be used for the Tech Bench: '
	echo '(ex. https://techbench.domain.com)' 
	read -p 'Enter URL [https://localhost]:  ' WebURL

	#  Get the Database Information
	read -p 'Will the Tech Bench use an existing database?  [y/n]' ExistingDB

	if [[ $ExistingDB =~ ^[Yy]$ ]]; then
		read -p 'Please enter the Database Name: [techbench]  ' DBName 
	fi
	DBName=${DBName:-techbench}

	#  If the user wants to use the 'root' database user, present warning that this is insecure
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
}
