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
source function/dependency_functions.sh

#  Verify the script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"  | tee $LOGFILE
   exit 1
fi

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
	printf '\n\nPlease Verify the Information is Correct:\n\n'
	echo 'Webroot Directory:          ' $RootDir
	echo 'Tech Bench URL:             ' $WebURL
	echo 'Database Name               ' $DBName
	echo 'Database User               ' $DBUser
	echo 'Database Password           <redacted>'
	read -p 'Would you like to continue? [y/n]'  doInstall  

	if [[ $doInstall =~ ^[Yy]$ ]]; then
		break
	fi	
done

###  Setup the Tech Bench  ###
cd $RootDir
echo 'Setting up Tech Bench.  Please wait...'
spin & 
SPIN_PID=$!
trap "kill -9 $SPIN_PID" `seq 0 15`

#  Create the .env configuration file
echo 'Writing Configuration File...'
writeEnv

#  Download all composer dependencies and generate new encryption key
echo 'Downloading Additional Files...'

su -c "composer install --optimize-autoloader --no-dev --no-interaction" $SUDO_USER
su -c "php artisan key:generate" $SUDO_USER

#  Setup the database
echo 'Setting Up Database...'
if [[ $ExistingDB =~ ^[Nn]$ ]]; then
    mysql -u$DBUser -p$DBPass 
        CREATE DATABASE IF NOT EXISTS \`${DBName}\`;
        GRANT ALL PRIVILEGES ON \`${DBName}\`.* TO '${DBUser}'@'localhost' WITH GRANT OPTION;
        GRANT SELECT ON INFORMATION_SCHEMA TO '${SBUser}'@'localhost';
        FLUSH PRIVILEGES;
    MYSQL_SCRIPT
fi
su -c "php artisan migrate --force" $SUDO_USER

echo 'Almost Done...'
su -c "php artisan storage:link" $SUDO_USER

##  Show Finished Message  ##
clear
tput setaf 4
echo '##################################################################'
echo '#                                                                #'
echo '#                 The Tech Bench is ready to go!                 #'
echo '#                                                                #'
echo '##################################################################'
tput sgr0
echo ''
echo 'Visit '$WebURL' and log in with the default user name and password:'
echo ''
echo 'Username:  admin'
echo 'Password:  password'
echo ''
echo 'Post Install Instructions:'
echo ''
echo 'For security purposes it is highly recommended to change the Apache ' | tee -a $LOGFILE
echo 'conf file to point to '$PROD_DIR'/public.' | tee -a $LOGFILE
echo ''
echo 'More information can be found in the log file'


exit 1