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

#  Verify the script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"  | tee $LOGFILE
   exit 1
fi

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

	#  Check the dependencies to make sure they are installed
	checkApache
	checkMysql
	checkPHP
	# checkApacheRewrite
	checkComposer

	## TODO - Check for Apache Rewrite Module
	## TODO - Check for php DOM extension (sudo apt-get install php-xml)
	## TODO - Check for PHP Zip extension

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
		echo 'Database Password            <redacted>'
		printf '\n'
		read -p 'Would you like to continue? [y/n]'  doInstall  

		if [[ $doInstall =~ ^[Yy]$ ]]; then
			break
		fi	
	done

	###  Setup the Tech Bench  ###
	echo 'Setting up Tech Bench.  Please wait...'
	chmod -R 777 $RootDir #  Temporarily allow full write access so script can download composer files
	cd $RootDir
	if [[ $ExistingDB =~ ^[Nn]$ ]]; then
		# mysql -u$DBUser -p$DBPass  
		mysql -u$DBUser -p$DBPass -e "CREATE DATABASE IF NOT EXISTS \`${DBName}\`;"
		mysql -u$DBUser -p$DBPass -e "GRANT ALL PRIVILEGES ON \`${DBName}\`.* TO '${DBUser}'@'localhost' WITH GRANT OPTION;"
		mysql -u$DBUser -p$DBPass -e "GRANT SELECT ON INFORMATION_SCHEMA TO '${SBUser}'@'localhost';"
		mysql -u$DBUser -p$DBPass -e "FLUSH PRIVILEGES;"
	fi

	#  TODO - Testing Here


	exit



	#  Create the .env configuration file
	echo 'Writing Configuration File...'
	writeEnv

	#  Download all composer dependencies and generate new encryption key
	echo 'Downloading Additional Files...'
	su -c "composer install --optimize-autoloader --no-dev --no-interaction" $SUDO_USER
	su -c "php artisan key:generate" $SUDO_USER# exit 1

	#  Setup the database
	echo 'Setting Up Database...'
	su -c "php artisan migrate --force" $SUDO_USER



	# Finish the install
	exit 1
	echo 'Almost Done...'
	chmod -R 755 $RootDir
	su -c "php artisan storage:link" $SUDO_USER

	##  Show Finished Message  ##
	# clear
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
}

spin()
{
    spinner="/|\\-/|\\-"
    while:
    do
        for i in `seq 0 7`
        do  
            echo -n "${spinner:$i:1}"
            echo -en "\010"
            sleep 0.5
        done
    done
}

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

writeEnv()
{
    touch .env
    echo '#  The settings can be changed as needed to match your environment' >> .env
    echo '#  Settings that have been commented out are settings that are not necessary,' >> .env
    echo '#  The .env file contains configuration data specific to your environment.' >> .env
    echo '#  but can be adjusted if necessary' >> .env
    echo '#' >> .env
    echo '#  VERY IMPORTANT:  In order for these settings to be applied, after saving the file,' >> .env
    echo '#  from the Web Root directory, run the command:  'php artisan config:cache'' >> .env
    echo '#' >> .env
    echo '#  USE CAUTION WHEN CHANGING SETTINGS ON A LIVE SYSTEM' >> .env
    echo '#  INCORRECT SETTINGS COULD CAUSE THE APPLICATION TO CRASH' >> .env
    echo '' >> .env
    echo '#  Primary Application Settings' >> .env
    echo '#  The APP_KEY is the encryption key for all application encryption and hashing.' >> .env
    echo '#  Modifying this setting could negitavely impact the user experience.' >> .env
    echo 'APP_KEY=base64:jZ4t3vJLWff1TXMjQhGmEBUosQFr0Ec0qbXM2hIwgwM=' >> .env
    echo '' >> .env
    echo '#  Uncomment and Modify the LOG_CHANNEL variable in order to increase or decrease the level of' >> .env
    echo '#  logging that is done by the Tech Bench application.  Valid inputs are in order of least' >> .env
    echo '#  amount of data gathered to the most amount of data gathered:' >> .env
    echo '#  1 -> emergency' >> .env
    echo '#  2 -> alert' >> .env
    echo '#  3 -> critical' >> .env
    echo '#  4 -> error' >> .env
    echo '#  5 -> warning' >> .env
    echo '#  6 -> notice' >> .env
    echo '#  7 -> info' >> .env
    echo '#  8 -> debug' >> .env
    echo '#  LOG_CHANNEL=debug' >> .env
    echo '' >> .env
    echo '#  For advanced troubleshooting, uncomment the APP_DEBUG line and set to true' >> .env
    echo '#  Setting this variable to true will cause error information to be printed to' >> .env
    echo '#  the user on the web browser.' >> .env
    echo '#  For security purposes, only turn this option on if absolutly necessary.' >> .env
    echo '#  Be sure to turn it back off when troubleshooting is completed' >> .env
    echo '#  APP_DEBUG=true' >> .env
    echo '' >> .env
    echo '#  The APP_URL is the url that is used for all hyperlinks both in the application' >> .env
    echo '#  and in emails.' >> .env
    echo "APP_URL=\"$WebURL\"" >> .env
    echo '' >> .env
    echo '#  Database Connection Settings' >> .env
    echo '#  The Tech Bench uses these settings for all database queries' >> .env
    echo '#  Do not modify unless you are sure that the settings are correct and need to be changed' >> .env
    echo 'DB_CONNECTION=mysql' >> .env
    echo 'DB_HOST=127.0.0.1' >> .env
    echo 'DB_PORT=3306' >> .env
    echo "DB_DATABASE=\"$DBName\"" 																	 >> .env
    echo "DB_USERNAME=\"$DBUser\"" 																 >> .env
    echo "DB_PASSWORD=\"$DBPass\"" >> .env
    echo '' >> .env
    echo '#  By default application files are stored int he WebRoot/storage/app directory' >> .env
    echo '#  To change this location, uncomment the lines below and modify as needed' >> .env
    echo '#  Be sure to make the assigned folders writable by the web_root user' >> .env
    echo '' >> .env
    echo '# ROOT_FOLDER="/path/to/doc/root"' >> .env
    echo '# DFLT_FOLDER="/default"' >> .env
    echo '# SYS_FOLDER="/systems"' >> .env
    echo '# CUST_FOLDER="/customers"' >> .env
    echo '# USER_FOLDER="/users"' >> .env
    echo '# TIP_FOLDER="/tips"' >> .env
    echo '# LINK_FOLDER="/links"' >> .env
    echo '# COMP_FOLDER="/company"' >> .env
    echo '# MAX_UPLOAD=2147483648' >> .env
}




main
