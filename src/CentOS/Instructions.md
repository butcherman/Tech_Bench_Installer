# CentOS 8

## Preparing the server

Before the installation can begin, the following requirements must be met:

* CentOS Operating System is up to date with the latest security updates
* A Static IP Address must be assigned to the server
* Ports 80 and 443 for HTTP and HTTPS should be opened and pointed to the server for Web Access

## Installing Tech Bech

* Download the attached `install.sh` script to the Ubuntu server
* If you wish to install a specific Tech Bench installation package, place the zipped installation files in the same directory as the install script

***Note:***  Leave the files in zipped format.  They will be extraced by the installation script.

If you wish, you can copy and paste the command below to use curl to download the script directly from Github

    curl -s https://raw.githubusercontent.com/butcherman/Tech_Bench_Installer/master/src/CentOS/install.sh -o install.sh

Navigate to the folder containing the installation script.  To completely automate the process and have the script take care of all prerequisites, run the following commands:

    sudo chmod +x install.sh
    sudo ./install.sh

If your Ubuntu installation is not a standard default installation, you can run the installer with the `-m` or `--manual` arguments.  If you chose to run the installer this way, the installer will fail if any prerequisites are not met.

If you wish to install a specific version, or from one of the existing branches, includ the `-b` or `--branch` tag followed by the branch name or version tag.

Example:

    sudo ./install.sh -b master   #  This will download the files directly from the Master branch

During the installation process, the following information will be required:

* The full URL that will be used to access the Tech Bench Application (example: techbench.demo)

***Note:***  Do not include the http or https in the URL

* If you would like to use http or https access for the Tech Bench website

If you opt for a manual installation, the following additional information will be needed:

* The Root Directory the web files are served from (Default is /var/www/html)
* The name of the Database that will be used to store the Tech Bench data (note:  this database must already exist)
* The username and password of the user that will be used by the Tech Bench to access the Tech Bench database
* The password of the 'root' MySQL user   //  TODO:  Is this necessary???
* If you would like to remove any existing virtual apache sites and create new sites specifically for the Tech Bench

***Note:*** If you select No, you must make sure that Apache Rewrite is enabled and working on your server.  If you select Yes, any existing virtual sites will be disabled.

## After Installation is Completed

Log into the Tech Bench by browsing to the URL of the Tech Bench server, and use the following credentials for default access:

    Username:  admin
    Password:  password

The installation log can be found in the storage/logs folder of the Web Root directory.  You can access this manually in the server, or in the Tech Bench by going to Administration->Logs

Refer to the [Tech Bench Documentation](https://tech-bench.readthedocs.io/en/latest/) for more information on configuring the Tech Bench settings and using the Tech Bench.
