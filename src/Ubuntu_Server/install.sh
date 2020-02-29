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
WASINS=false
SPIN_PID=0
 
#  File Locations
WEBROOT=\/var\/www\/html
USEFILE=null

#  Install Data Variables
WebURL=localhost
FullURL=https:\/\/localhost
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
	
	#  Set the full URL that will be used to access the website
	if [ $SSLOnly == 'true' ]; then
		FullURL=https:\\/\\/$WebURL
	else
		FullURL=http:\\/\\/$WebURL
	fi
	
	#  Check prerequisites
	printf 'Checking Dependencies...\n\n' | tee -a $LOGFILE
	checkPrereqs
	printf '\n'
	
	#  If the prerequisites fail, the installer will terminate
	if [ $PREREQ == 'false' ]; then
		echo 'You are missing one or more dependencies'
		echo 'These must be installed before we can continue installation process'
		printf '\n\n'		
		exit 1
	fi

	tput setaf 2
	echo 'Looking good so far'
	echo 'Lets continue'
	printf '\n'
	tput sgr0
	
	#  Determine which installation files to use and install them
	checkPackage
	installPackage
	
	
	
	#############################################
	#############################################
	#############################################
	
	
	
	

	printf '\n\ndone\n\n'
	exit 0
}

help()
{
	echo 'help menu'
	#  TODO - Create a help menu
}

#  Only run the prerequisite check and exit
check()
{
	LOGFILE=\/dev\/null
	MANUAL=true
	clear
	tput setaf 4
	echo '##################################################################' 
	echo '#                                                                #' 
	echo '#                 Welcome to the Tech Bench Setup                #' 
	echo '#                                                                #' 
	echo '##################################################################' 
	echo '' 
	tput sgr0
	
	#  Check prerequisites
	printf 'Checking Dependencies...\n\n' 
	checkPrereqs
	
	echo ''
	if [ $PREREQ == 'true' ]; then
		echo 'All dependencies are installed'
	else
		echo 'You are missing one or more dependencies.'
		echo 'The missing dependencies must be installed before Tech Bench can be installed'
	fi
	echo ''
	exit 0
}

#  Check prerequisites
checkPrereqs()
{
	#  Check for web server
	checkApache
	checkMysql
	checkPHP
	
	#  Check proper modules are installed
	if [ $PREREQ == 'true' ]; then
		checkModules
	fi
	
	#  Check third party software is installed for package management
	checkComposer
	checkNodeJS
	checkNPM
	checkUnzip
	checkSupervisor
}

#  Check Apache is installed and running
checkApache()
{
    printf 'Apache                                                      ' | tee -a $LOGFILE
    if systemctl is-active --quiet apache2; then
        tput setaf 2
        echo '[PASS]' | tee -a $LOGFILE
	elif [ $MANUAL == 'false' ]; then
		echo 'Apache is not Installed' >> $LOGFILE 2>&1
		echo 'Installing LAMP Server' >> $LOGFILE 2>&1
		echo -en '[INSTALLING] '
		startSpin
		apt-get -q update >> $LOGFILE
		apt-get -q install lamp-server^ -y >> $LOGFILE 2>&1
		echo -ne '\b\b\b\b\bED]      \n'
		echo 'LAMP Server Installed' >> $LOGFILE 2>&1
		WASINS=true
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
        if [ $WASINS == 'false' ]; then
			tput setaf 2
			echo '[PASS]' | tee -a $LOGFILE
		else
			echo '[INSTALLED]' | tee -a $LOGFILE
		fi
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
        if (($PHPVersion >= $minimumPHPVer)); then
            if [ $WASINS == 'false' ]; then
				tput setaf 2
				echo '[PASS]' | tee -a $LOGFILE
			else
				echo '[INSTALLED]' | tee -a $LOGFILE
			fi
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
		if [ $WASINS == 'false' ]; then
			tput setaf 2
			echo '[PASS]' | tee -a $LOGFILE
		else
			echo '[INSTALLED]' | tee -a $LOGFILE
		fi
	elif [ $MANUAL == 'false' ]; then
		echo -en '[INSTALLING]'
		apt-get install php-xml -y >> $LOGFILE 2>&1
		echo -ne '\b\b\b\bED]      '
		echo '[INSTALLED]' >> $LOGFILE 2>&1
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
		echo 'PHP-ZIP Module is not Installed.  Installing' >> $LOGFILE 2>&1
		echo -en '[INSTALLING]'
		apt-get install php-zip -y >> $LOGFILE 2>&1
		echo -ne '\b\b\b\bED]      \n'
		echo 'PHP-ZIP Module Installed' >> $LOGFILE 2>&1
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
		echo 'PHP-GD Module is not Installed.  Installing' >> $LOGFILE 2>&1
		echo -en '[INSTALLING]'
		apt-get install php-gd -y >> $LOGFILE 2>&1
		echo -ne '\b\b\b\bED]      \n'
		echo 'PHP-GD Module Installed' >> $LOGFILE 2>&1
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
			echo 'Composer is not Installed.  Installing' >> $LOGFILE 2>&1
			echo -en '[INSTALLING]'
			apt-get install composer -y >> $LOGFILE 2>&1
			echo -ne '\b\b\b\bED]      \n'
			echo 'Composer Installed' >> $LOGFILE 2>&1
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
		echo 'NodeJS is not Installed.  Installing' >> $LOGFILE 2>&1
			echo -en '[INSTALLING]'
			apt-get install nodejs -y >> $LOGFILE 2>&1
			echo -ne '\b\b\b\bED]      \n'
			echo 'NodeJS Installed' >> $LOGFILE 2>&1
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

#  Check if NPM is installed
checkNPM()
{
	printf 'NPM                                                         ' | tee -a $LOGFILE
	npm -v > /dev/null 2>&1
	NODE=$?
	if [[ $NODE -ne 0 ]]; then
		if [ $MANUAL == 'false' ]; then
			echo 'NPM is not Installed.  Installing' >> $LOGFILE 2>&1
			echo -en '[INSTALLING]'
			apt-get install npm -y >> $LOGFILE 2>&1
			echo -ne '\b\b\b\bED]      \n'
			echo 'NPM Installed' >> $LOGFILE 2>&1
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

#  Check if Unzip is installed
checkUnzip()
{
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

#  Check if supervisor is installed
checkSupervisor()
{
	printf 'Supervisor                                                  ' | tee -a $LOGFILE
	supervisord -v > /dev/null 2>&1
	NODE=$?
	if [[ $NODE -ne 0 ]]; then
		if [ $MANUAL == 'false' ]; then
			echo 'Supervisor is not Installed.  Installing' >> $LOGFILE 2>&1
			echo -en '[INSTALLING]'
			apt-get install supervisor -y >> $LOGFILE 2>&1
			echo -ne '\b\b\b\bED]      \n'
			echo 'Supervisor Installed' >> $LOGFILE 2>&1
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

#  Check for the proper installation package
checkPackage()
{
	FILELIST=(`ls | grep Tech_Bench`)
	LISTLEN=${#FILELIST[*]}
	USEINDEX=null

	if [ $LISTLEN == 0 ]; then
		echo 'Downloading latest Tech Bench release'
		startSpin
		USEFILE=Tech_Bench_latest.zip
		GETURL=$(curl -s https://api.github.com/repos/butcherman/tech_bench/releases/latest | grep zipball_url | cut -d : -f 2,3 | tr -d \" | tr -d \,)
		wget -O $USEFILE $GETURL > /dev/null 2>&1
	elif [ $LISTLEN -ne 1 ]; then
		while true; do
			echo 'Please select the Tech Bench installation package to install'
			echo ''
			i=0
			while [ $i -lt $LISTLEN ]; do
				echo "$i: ${FILELIST[$i]}"
				let i++
			done
			echo ''
			read -p 'Please select 0 through '$LISTLEN' [0]:  ' USEINDEX
			
			if [[ ! $USEINDEX =~ ^[+-]?[0-9]+$ ]]; then
				echo 'Numbers Only Please'
			elif [[ $USEINDEX -le $LISTLEN ]]; then
				USEFILE=${FILELIST[$USEINDEX]}
				break
			fi
		done
	else
		USEFILE=${FILELIST[0]}
	fi
	
	printf 'Using '$USEFILE' as installation package'
}

#  Move the installation files to the WebRoot directory
installPackage()
{
	#  Add the current user to the www-data group
	usermod -a -G www-data $SUDO_USER

	#  Unzip installation files
	echo 'Extracting Files'
	DIRNAME=$(zipinfo -1 $USEFILE | grep -o "^[^/]\+[/]" | sort -u | tr -d \/)
	unzip $USEFILE >> $LOGFILE

	#  Move files to web root directory
	cp -r $DIRNAME/* $WEBROOT
	cp -r $DIRNAME/.htaccess $WEBROOT/.htaccess
	cp -r $DIRNAME/.env.example $WEBROOT/.env

	#  Set file permissions and owner
	chown -R www-data:www-data $WEBROOT
	chmod 777 $WEBROOT/storage/logs
	chmod 777 $WEBROOT/storage/app/public
	
	#  Write the configuration settings to the .env file
	sed -i "s/APP_URL=http:\/\/localhost/APP_URL=$FullURL/g" $WEBROOT/.env
	sed -i "s/DB_DATABASE=tech-bench/DB_DATABASE=$DBName/g" $WEBROOT/.env
	sed -i "s/DB_USERNAME=root/DB_USERNAME=$DBUser/g" $WEBROOT/.env
	sed -i "s/DB_PASSWORD=/DB_PASSWORD=$DBPass/g" $WEBROOT/.env
}

#  Spinner to show while background processes are running
spin()
{
	spinner="/|\\-/|\\-"
	while :
	do
		for i in `seq 0 7`
		do
			echo -n "${spinner:$i:1}"
			echo -en "\010"
			sleep 1
		done
	done
}

#  Start the spinner
startSpin()
{
	spin &
	SPIN_PID=$!
	trap "kill -9 $SPIN_PID" `seq 0 15`
	echo -en "\b "
}

#  Check arguments
while [ "$1" != "" ]; do
	case $1 in
		-m | --manual )	shift
						MANUAL=true
						;;
		-c | --check )	shift	
						check
						exit 0
						;;
		-h | --help )	shift
						help
						exit 0
						;;
		* )				main
						exit 0			
	esac
	shift
done

main
exit 0
