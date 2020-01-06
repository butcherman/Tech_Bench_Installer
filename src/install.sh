#!/bin/bash
################################################################################
#                                                                              #
#  This bash script is for the initial installation of the Tech Bench          #
#                                                                              #
################################################################################

#  Log File Location
LOGFILE=install.log
#  Minimum PHP Version Required to run Tech Bench
minimumPHPVer=73;
minimumPHPReadable=7.3

#  Variables
PREREQ=true

#  Include Files
source function/dependency_functions.sh

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
#  Install variables
CurDir=$pwd

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
	read -p 'Please enter the password of the database user:  ' DBPass

	if [[ $DBUser -ne 'root' ]]; then
		break
	fi

	printf '\n\n Using the "root" database user can be very insecure.'
	read -p 'Are you sure you want to continue with this database user? [y/n]'  cont  

	if [[ $cont =~ ^[Yy]$ ]]
		break
	fi
done






exit 1