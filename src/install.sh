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

#  Start installation process
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
checkApacheRewrite
checkComposer

#  Check if all prerequesits have passed or not.  If a prereq fails, exit script
if test $PREREQ = false; then
	printf '\n\nOne or more prerequesits has failed.\nPlease install the missing prerequesits and run this installer again.\n\n' | tee -a $LOGFILE
	exit 1
fi
printf '\nLooking Good - lets move on...\n\n' | tee -a $LOGFILE





exit 1
