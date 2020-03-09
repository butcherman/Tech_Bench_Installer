#!/bin/bash
################################################################################
#                                                                              #
#  This bash script is for the initial installation of the Tech Bench          #
#                                                                              #
################################################################################

#  Minimum PHP Version Required to run Tech Bench
minimumPHPVer=72;
minimumPHPReadable=7.2

#  Variables
PREREQ=true
MODULE=true
MANUAL=false
WASINS=false
SPIN_PID=0
BRANCH=null

#  File Locations
SCRIPTROOT=$(pwd)
LOGFILE=$SCRIPTROOT/TB_Install.log
WEBROOT=\/var\/www\/html
USEFILE=null
WORKERFILE=/etc/supervisor/conf.d/laravel-worker.conf
CRONFILE=/etc/cron.d/laravel-jobs

#  Install Data Variables
WebURL=localhost
FullURL=https:\/\/localhost
SSLOnly=true
DBName=techbench
DBUser=tbUser
DBPass=null
ROOTPass=null
VIRDIR=true
DISVIR=true

#  Verify the script is being run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"  | tee $LOGFILE
   exit 1
fi

#  Touch the log file and make sure it can be writen to by both the sudo user and normal user
touch $LOGFILE && chmod 777 $LOGFILE

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
	read -p "Enter URL [$WebURL]:  " WebURL2
	echo ''
	#  If input was blank, use default value
	if [[ $WebURL2 != '' ]]; then
		WebURL=$WebURL2
	fi
	#  Determine if we should only use https access
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
		read -p 'What is the Web Server Root Directory where the Tech Bench files are loaded to? ['$WEBROOT']:  ' WEBROOT2
		#  If input was blank, use default value
		if [[ $WEBROOT2 != '' ]]; then
			WEBROOT=$WEBROOT2
		fi

		#  Name of the database to use
		echo ''
		read -p 'Please enter the name of the database to hold the Tech Bench data ['$DBName']:  ' DBName2
		#  If input was blank, use default value
		if [[ $DBName2 != '' ]]; then
			DBName=$DBName2
		fi

		#  Username and password to access database
		while true; do
			read -p 'Please enter the name of the database user:  ' DBUser
			read -p 'Please enter the password of the database user:  ' -s DBPass

			if [[ $DBUser != 'root' ]]; then
				break
			fi

			printf '\n\n Using the "root" user as the primary Tech Bench Database User can be very insecure.'
			read -p 'Are you sure you want to continue with this database user? [y/n]'  cont

			if [[ $cont =~ ^[Yy]$ ]]; then
				break
			fi
		done

		#  Get the root password for the database
		if [ $DBUser != 'root' ]; then
			echo 'For the database installation, we will need to get the password of the root user'
			read -p 'Please enter the password for the MySQL root user: ' ROOTPass
		else
			ROOTPass=$DBPASS
		fi

		#  Ask if virtual directories are already built
		echo ''
		read -p 'Update existing virtual sites for Tech Bench (Recommended)? [Y/N]: ' VIRDIR
		if [[ $VIRDIR =~ [Nn]$ ]]; then
			VIRDIR=false
		else
			VIRDIR=true
		fi

		#  Ask to disable any existing virtual directories
		# echo ''
		# read -p 'Disable any existing virtual directories? [Y/N]: ' DISVIR
		# if [[ $DISVIR =~ [Yy]$ ]]; then
		# 	DISVIR=true
		# else
		# 	DISVIR=false
		# fi
	fi

	#  Set the full URL that will be used to access the website
	if [ $SSLOnly == 'true' ]; then
		FullURL=https:\\/\\/$WebURL
		WebLink=https:\/\/$WebURL
	else
		FullURL=http:\\/\\/$WebURL
		WebLink=http:\/\/$WebURL
	fi

	#  Check prerequisites
	printf '\nChecking Dependencies...\n\n' | tee -a $LOGFILE
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

	#  Create new virtual directory files for the Tech Bench site
	if [ $VIRDIR == 'true' ]; then
#		echo 'Generating Self Signed SSL Certificate.  Please answer the following questions: '
	#	openssl req -newkey rsa:2048 -nodes -keyout /etc/pki/tls/private/httpd.key -x509 -days 365 -out /etc/pki/tls/certs/httpd.crt

		writeConfFiles
	fi

	exit 0










	#  Load dependencies and build application files
	setupApplication
	cleanup

	#  Installation finished
	FullURL=$($FullURL -tr -d \ )
	clear
	tput setaf 4
	echo '##################################################################'
	echo '#                                                                #'
	echo '#                    Tech Bench Setup Complete                   #'
	echo '#                                                                #'
	echo '##################################################################'
	echo ''
	tput sgr0
	echo "Visit $WebLink and login with the default credentials of:"
	echo "     Username:  admin"
	echo "     Password:  password"
	echo "to start using the Tech Bench."
	echo ''
	echo "The full installation log can be found at $WEBROOT/storage/logs/Tech_Bench_Install.log"
	echo ''

	exit 0
}

help()
{
	echo '                             Tech Bench Installer Help'
	echo ''
	echo 'By default the Tech Bench installer will download the latest Tech Bench installation files and install '
	echo 'them to the default apache web server location (/var/ww/html)'
	echo ''
	echo 'The following arguments can be used for assistance:'
	echo ''
	echo '-m or --manual               - Run a manual installation that will not override any existing settings '
	echo '                               Use this option if you want to do a custom installation of the Tech Bench'
	echo ''
	echo '-b or --branch <branch name> - Select the specific Tech Bench Git Hub branch to use as the Tech Bench'
	echo '                               installation package.'
	echo '                               Use this option if you want to install a custom version of the Tech Bench'
	echo ''
	echo '-c or --check                - Check to see if the prerequisites are installed'
	echo '                               The Tech Bench install will not install any files, only check if the required'
	echo '                               prerequisites are installed and running on the server'
	echo '                               If you wish to install the prerequisites during the check, pass along the \"true\"'
	echo '                               flag with the --check argument'
	echo '                               Example:  ./install.sh --check true'
	echo ''
	echo '-h or --help                 - Display this help menu'
	echo ''
}

#  Only run the prerequisite check and exit
check()
{
	LOGFILE=\/dev\/null
	if [ $INSTALL == 't' ] || [ $INSTALL == 'true' ]; then
		MANUAL=false
	else
		MANUAL=true
	fi

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

	#  Restart Apache if the prerequisites were installed
	if [ $MANUAL == 'false' ]; then
		systemctl restart httpd.service >> $LOGFILE 2>&1
	fi
}

#  Check Apache is installed and running
checkApache()
{
    printf 'Apache                                                      ' | tee -a $LOGFILE
    if systemctl is-active --quiet httpd; then
        tput setaf 2
        echo '[PASS]' | tee -a $LOGFILE
	elif [ $MANUAL == 'false' ]; then
		echo 'Apache is not Installed' >> $LOGFILE 2>&1
		echo 'Installing Apache Server' >> $LOGFILE 2>&1
		echo -en '[INSTALLING] '
		startSpin

		#  Install Apache and register the service
		yum -q install httpd -y >> $LOGFILE 2>&1
        systemctl start httpd.service >> $LOGFILE 2>&1
        systemctl enable httpd.service >> $LOGFILE 2>&1

		#  TODO - Set the servername globally

		#  Enable SSL if required
		if [ $SSLOnly == 'true' ]; then
			SSLMOD=$(httpd -M | grep -c ssl) >> $LOGFILE 2>&1
			if (( $SSLMOD < 1 )); then
				yum -q install mod_ssl -y >> $LOGFILE 2>&1
				systemctl restart httpd.service >> $LOGFILE 2>&1
			fi
		fi

		#  Open http and https services on internal firewall
		firewall-cmd --permanent --zone=public --add-service=http >> /dev/null 2>&1
		firewall-cmd --permanent --zone=public --add-service=https >> /dev/null 2>&1
		firewall-cmd --reload >> /dev/null 2>&1

		echo -ne '\b\b\b\b\bED]      \n'
		echo 'Apache Server Installed' >> $LOGFILE 2>&1
		killSpin
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
    elif [ $MANUAL == 'false' ]; then
        echo 'MySQL is not Installed' >> $LOGFILE 2>&1
		echo 'Installing MySQL' >> $LOGFILE 2>&1
		echo -en '[INSTALLING] '
		startSpin
		yum -q install mariadb-server mariadb -y >> $LOGFILE 2>&1
        systemctl start mariadb >> $LOGFILE 2>&1
        systemctl enable mariadb.service >> $LOGFILE 2>&1
		echo -ne '\b\b\b\b\bED]      \n'
		echo 'MySQL Installed' >> $LOGFILE 2>&1
		killSpin
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
			tput setaf 2
			echo '[PASS]' | tee -a $LOGFILE
        else
            tput setaf 1
            echo '[FAIL]' | tee -a $LOGFILE
            PREREQ=false
        fi
	elif [ $MANUAL == 'false' ]; then
        echo 'PHP is not Installed' >> $LOGFILE 2>&1
		echo 'Installing PHP' >> $LOGFILE 2>&1
		echo -en '[INSTALLING] '
		startSpin
		yum -q install php -y >> $LOGFILE 2>&1

		#  Get the location of the php.ini file and update the upload_max_filesize paramater
		PHPINI=$(php -i | grep php.ini | head -n 1 | cut -d " " -f 6)
		sed -i 's,^upload_max_filesize =.*$,upload_max_filesize = 6M,' $PHPINI/php.ini

		#  Restart httpd to load new settings
		systemctl restart httpd.service >> $LOGFILE 2>&1
		echo -ne '\b\b\b\b\bED]      \n'
		echo 'PHP Installed' >> $LOGFILE 2>&1
		killSpin
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
	XMLMod=$(php -m | grep -c dom)

	if (( $XMLMod > 0 )); then
		if [ $WASINS == 'false' ]; then
			tput setaf 2
			echo '[PASS]' | tee -a $LOGFILE
		else
			echo '[INSTALLED]' | tee -a $LOGFILE
		fi
	elif [ $MANUAL == 'false' ]; then
		echo -en '[INSTALLING]'
		startSpin
		yum -q install php-dom -y >> $LOGFILE 2>&1
		echo -ne '\b\b\b\bED]      \n'
		echo '[INSTALLED]' >> $LOGFILE 2>&1
		killSpin
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
		startSpin
		yum -q install php-zip -y >> $LOGFILE 2>&1
		echo -ne '\b\b\b\bED]      \n'
		echo 'PHP-ZIP Module Installed' >> $LOGFILE 2>&1
		killSpin
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
		startSpin
		yum -q install php-gd -y >> $LOGFILE 2>&1
		echo -ne '\b\b\b\bED]      \n'
		echo 'PHP-GD Module Installed' >> $LOGFILE 2>&1
		killSpin
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
			startSpin
			yum -q install php-json -y >> $LOGFILE 2>&1
			curl -s https://getcomposer.org/installer -o composer-installer.php >> $LOGFILE 2>&1
			sudo php composer-installer.php --install-dir=/usr/local/bin --filename=composer >> $LOGFILE 2>&1
			echo -ne '\b\b\b\bED]      \n'
			echo 'Composer Installed' >> $LOGFILE 2>&1
			killSpin
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
			startSpin
			yum -q install nodejs -y >> $LOGFILE 2>&1
			echo -ne '\b\b\b\bED]      \n'
			echo 'NodeJS Installed' >> $LOGFILE 2>&1
			killSpin
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
			startSpin
			mkdir npm && cd npm/
			curl -s https://www.npmjs.com/install.sh | sh  >> $LOGFILE 2>&1
			echo -ne '\b\b\b\bED]      \n'
			echo 'NPM Installed' >> $LOGFILE 2>&1
			killSpin
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
			startSpin
			yum -q install epel-release -y >> $LOGFILE 2>&1
			yum -q install supervisor -y >> $LOGFILE 2>&1
			echo -ne '\b\b\b\bED]      \n\n'
			echo 'Supervisor Installed' >> $LOGFILE 2>&1
			killSpin
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
	FILELIST=(`find . -maxdepth 1 -not -type d | grep Tech_Bench | tr -d .\/zip`)
	LISTLEN=${#FILELIST[*]}
	USEINDEX=null

	if [ "$BRANCH" != 'null' ]; then
		echo 'Downloading Branch '$BRANCH
		startSpin
		USEFILE=Tech_Bench_$BRANCH.zip
		RESPONSE=$(wget --server-response -O $USEFILE https://api.github.com/repos/butcherman/tech_bench/zipball/$BRANCH 2>&1 | awk '/^  HTTP/{print $2}')
		CODES=($RESPONSE)
		if [[ ${CODES[1]} -ne '200' ]]; then
			tput setaf 1
			echo 'There was an issue downloading from Branch '$BRANCH'.'
			echo 'Verify this is a valid branch and try again.'
			tput sgr0
			exit 1
		fi
		killSpin
	elif [ $LISTLEN == 0 ]; then
		echo 'Downloading latest Tech Bench release'
		startSpin
		USEFILE=Tech_Bench_latest.zip
		GETURL=$(curl -s https://api.github.com/repos/butcherman/tech_bench/releases/latest | grep zipball_url | cut -d : -f 2,3 | tr -d \" | tr -d \,)
		wget -O $USEFILE $GETURL > /dev/null 2>&1
		killSpin
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

	printf 'Using '
	tput setaf 2
	printf $USEFILE
	tput sgr0
	printf ' as installation package\n\n'
}

#  Move the installation files to the WebRoot directory
installPackage()
{
	#  Add the current user to the www-data group
#	usermod -a -G apache $SUDO_USER

	#  Unzip installation files
	echo 'Extracting Files'
	startSpin
	DIRNAME=$(zipinfo -1 $USEFILE | grep -o "^[^/]\+[/]" | sort -u | tr -d \/)
	unzip -o $USEFILE >> $LOGFILE

	#  Empty any existing files out of the Web Root directory
	find $WEBROOT/ -type f -delete > /dev/null 2>&1
	find $WEBROOT/* -type d -delete > /dev/null 2>&1
	find $WEBROOT/node_modules -delete > /dev/null 2>&1
	find $WEBROOT/vendor -delete > /dev/null 2>&1

	#  Move files to web root directory
	cp -r $DIRNAME/* $WEBROOT
	cp -r $DIRNAME/.htaccess $WEBROOT/.htaccess
	cp -r $DIRNAME/.env.example $WEBROOT/.env

	#  Create the folders for the dependencies
	mkdir $WEBROOT/vendor $WEBROOT/node_modules
	chmod 777 -R $WEBROOT/*
	chmod 777 $WEBROOT/.env

	#  If the installer is not being done manually, generate a password for the database user
	if [ $MANUAL == 'false' ]; then
		DBPass=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
		ROOTPass=$DBPASS
	fi

	#  Write the configuration settings to the .env file
	sed -i "s/APP_URL=http:\/\/localhost/APP_URL=$FullURL/g" $WEBROOT/.env
	sed -i "s/DB_DATABASE=tech-bench/DB_DATABASE=$DBName/g" $WEBROOT/.env
	sed -i "s/DB_USERNAME=root/DB_USERNAME=root/g" $WEBROOT/.env        #  $DBUser/g" $WEBROOT/.env
	sed -i "s/DB_PASSWORD=/DB_PASSWORD=$ROOTPass/g" $WEBROOT/.env

	killSpin
}

#  Write new apache config files
writeConfFiles()
{
	echo 'Updating Apache Virtual Directories'
	startSpin
	sed -i "s/DocumentRoot.*$/DocumentRoot \"\/var\/www\/\/html\/public\"/g" /etc/httpd/conf/httpd.conf

	#  Create the new http site
	# HTTPSITE=/etc/httpd/conf.d/TechBench.conf
	# touch $HTTPSITE
	# echo '<VirtualHost _default_:80>' > $HTTPSITE
	# echo '	ServerAdmin webmaster@localhost' >> $HTTPSITE
	# echo '	DocumentRoot /var/www/html/public' >> $HTTPSITE
	# echo '	<Directory "/var/www/html/public">' >> $HTTPSITE
	# echo '		Options Indexes FollowSymLinks MultiViews' >> $HTTPSITE
	# echo '		AllowOverride All' >> $HTTPSITE
	# echo '		Order allow,deny' >> $HTTPSITE
	# echo '		Allow from all' >> $HTTPSITE
	# echo '	</Directory>' >> $HTTPSITE
	# if [ $SSLOnly == 'true' ]; then
	# 	echo ''	 >> $HTTPSITE
	# 	echo '	RewriteEngine on' >> $HTTPSITE
	# 	echo '	RewriteCond %{SERVER_NAME} ='$WebURL' [OR]' >> $HTTPSITE
    #     echo '	RewriteCond %{SERVER_NAME} ='$FullURL >> $HTTPSITE
    #     echo '	RewriteRule ^ https://%{SERVER_NAME}%{REQUEST_URI} [END,NE,R=permanent]' >> $HTTPSITE
	# 	echo '' >> $HTTPSITE
	# fi
	# echo '</VirtualHost>' >> $HTTPSITE

	# #  Create the new https site
	# if [ $SSLOnly == 'true' ]; then
	# 	HTTPSSITE=/etc/httpd/conf.d/SSLTechBench.conf
	# 	touch $HTTPSSITE
	# 	echo '<IfModule mod_ssl.c>' > $HTTPSSITE
	# 	echo '	<VirtualHost *:443>' >> $HTTPSSITE
	# 	echo '		ServerAdmin webmaster@localhost' >> $HTTPSSITE
	# 	echo '		DocumentRoot /var/www/html/public' >> $HTTPSSITE
	# 	echo '		<Directory "/var/www/html/public">' >> $HTTPSSITE
	# 	echo '			Options Indexes FollowSymLinks MultiViews' >> $HTTPSSITE
	# 	echo '			AllowOverride All' >> $HTTPSSITE
	# 	echo '			Order allow,deny' >> $HTTPSSITE
	# 	echo '			Allow from all' >> $HTTPSSITE
	# 	echo '		</Directory>' >> $HTTPSSITE
	# 	echo '' >> $HTTPSSITE
	# 	echo '		SSLEngine on' >> $HTTPSSITE
	# 	echo '		SSLCertificateFile	/etc/pki/tls/certs/httpd.crt' >> $HTTPSSITE
	# 	echo '		SSLCertificateKeyFile /etc/pki/tls/private/httpd.key' >> $HTTPSSITE
	# 	echo '		<FilesMatch "\.(cgi|shtml|phtml|php)$">' >> $HTTPSSITE
	# 	echo '			SSLOptions +StdEnvVars' >> $HTTPSSITE
	# 	echo '		</FilesMatch>' >> $HTTPSSITE
	# 	echo '		<Directory /usr/lib/cgi-bin>' >> $HTTPSSITE
	# 	echo '			SSLOptions +StdEnvVars' >> $HTTPSSITE
	# 	echo '		</Directory>' >> $HTTPSSITE
	# 	echo '	</VirtualHost>' >> $HTTPSSITE
	# 	echo '</IfModule>' >> $HTTPSSITE
	# fi

	# #  Enable the necessary modules
	# a2enmod rewrite ssl >> $LOGFILE

	# #  Enable the new sites
	# a2ensite TechBench.conf SSLTechBench.conf >> $LOGFILE

	# #  Restart Apache
	systemctl reload httpd.service >> $LOGFILE

	killSpin
}

#  Download all dependencies from composer and NPM and setup application
setupApplication()
{
	printf 'Creating Tech Bench Application '
	startSpin
	#  If the installer is not being done manually, create the database and database user
	if [ $MANUAL == 'false' ]; then
		mysql <<SCRIPT
			ALTER USER 'root'@'localhost' IDENTIFIED BY '$DBPASS';
			ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$DBPASS';
			CREATE DATABASE IF NOT EXISTS \`$DBName\`;
			CREATE USER IF NOT EXISTS $DBUser@localhost IDENTIFIED WITH mysql_native_password BY '$DBPass';
			GRANT ALL PRIVILEGES ON \`$DBName\`.* TO '$DBUser'@'localhost' WITH GRANT OPTION;
#			GRANT SELECT ON \`information_schema\`.* TO '$DBUser'@'localhost';
			FLUSH PRIVILEGES;
SCRIPT
	fi

	#  Install composer dependencies
	cd $WEBROOT
	su -c "composer install --no-dev --no-interaction --optimize-autoloader" $SUDO_USER &>> $LOGFILE
	su -c "php artisan key:generate --force" $SUDO_USER &>> $LOGFILE
	su -c "php artisan storage:link" $SUDO_USER &>> $LOGFILE
	su -c "php artisan ziggy:generate" $SUDO_USER &>> $LOGFILE

	#  Install NPM dependencies
	su -c "npm install --silent cross-env" $SUDO_USER &>> $LOGFILE
	su -c "npm install --silent --only=production" $SUDO_USER &>> $LOGFILE
	su -c "npm run production" $SUDO_USER &>> $LOGFILE

	#  Setup DATABASE
	su -c "php artisan migrate --force" $SUDO_USER &>> $LOGFILE

	#  Cache Files
	su -c "php artisan config:cache" $SUDO_USER &>> $LOGFILE
	su -c "php artisan route:cache" $SUDO_USER &>> $LOGFILE

	# Setup Supervisor service to work email queue
	touch $WORKERFILE
	echo "#  The laravel-worker program will ensure the queue:work command " >> $WORKERFILE
	echo "#  is constantly running." >> $WORKERFILE
	echo "" >> $WORKERFILE
	echo "[program:laravel-worker]" >> $WORKERFILE
	echo "process_name=%(program_name)s_%(process_num)02d" >> $WORKERFILE
	echo "command=php $WEBROOT/artisan queue:work --sleep=3 --tries=3" >> $WORKERFILE
	echo "autostart=true" >> $WORKERFILE
	echo "autorestart=true" >> $WORKERFILE
	echo "user=www-data" >> $WORKERFILE
	echo "numprocs=8" >> $WORKERFILE
	echo "redirect_stderr=true" >> $WORKERFILE
	echo "stdout_logfile=$WEBROOT/storage/logs/worker.log" >> $WORKERFILE

	# Start the Supervisor service
	supervisorctl reread >> $LOGFILE
	supervisorctl update >> $LOGFILE
	supervisorctl start laravel-worker:* >> $LOGFILE

	# Setup the cron file for all Scheduled Tasks performed by the Tech Bench
	touch $CRONFILE
	echo "#  The laravel-jobs cron job is to run any scheduled tasks performed by the Tech Bench" >> $CRONFILE
	echo "" >> $CRONFILE
	echo "* * * * * cd $WEBROOT && php artisan schedule:run >> /dev/null 2>&1" >> $CRONFILE

	killSpin
}

cleanup()
{
	printf '\nCleaning Up '
	startSpin

	#  Update the .env file to use the proper user for the database access
	sed -i "s/DB_USERNAME=root/DB_USERNAME=$DBUser/g" $WEBROOT/.env
	sed -i "s/DB_PASSWORD=$ROOTPass/DB_PASSWORD=$DBPASS/g" $WEBROOT/.env

	#  Set file permissions and owner
	chown -R www-data:www-data $WEBROOT $WEBROOT/.env $WEBROOT/.htaccess
	find $WEBROOT -type f -exec chmod 644 {} \; >> $LOGFILE
	find $WEBROOT -type d -exec chmod 755 {} \; >> $LOGFILE

	#  Lock down the config file and .htaccess
	chmod 600 $WEBROOT/.env >> $LOGFILE
	chmod 500 $WEBROOT/.htaccess >> $LOGFILE

	#  Delete the files created by the installer
	find $SCRIPTROOT/$USEFILE --delete >> $LOGFILE
	find $SCRIPTROOT/npm --delete >> $LOGFILE

	#  Move the installer log into the storage/logs directory
	mv $LOGFILE $WEBROOT/storage/logs/Tech_Bench_Install.log

	killSpin
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
}

#  Kill the spinner
killSpin()
{
	kill -9 $SPIN_PID > /dev/null 2>&1
	wait $! > /dev/null 2>&1
	echo -en "\b "
}

#  Check arguments
while [ "$1" != "" ]; do
	case $1 in
		-m | --manual )	shift
						MANUAL=true
						;;
		-b | --branch ) shift
						BRANCH=$1
						;;
		-c | --check )	shift
						INSTALL=$1
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
