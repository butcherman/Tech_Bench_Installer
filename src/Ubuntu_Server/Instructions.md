#  Ubuntu Server 19.10 and Higher

## Preparing the server

Before the installation can begin, the following requirements must be met:

* Ubuntu Operating System is up to date with the latest security updates
* A Static IP Address must be assigned to the server
* Ports 80 and 443 for HTTP and HTTPS should be opened and pointed to the server for Web Access

## Installing Tech Bech

* Download the attached `install.sh` script to the Ubuntu server
* Download the latest Tech Bench release and place in the same directory as the installation script
Note:  Leave the files in zipped format.  They will be extraced by the installation script.

Navigate to the folder containing the installation script.  To completely automate the process and have the script take care of all prerequisites, run the following command:

    ./install.sh 

If your Ubuntu installation is not a standard default installation, you can run the installer with the `-m` or `--manual` arguments.  If you chose to run the installer this way, the installer will fail if any prerequisites are not met.  









During the installation process, the following information will be required:
* The full URL that will be used to access the Tech Bench Application (example: https://techbench.demo)

For a manual installation, the following additional information will be needed:
* The Root Directory the web files are served from (Default is /var/www/html) 
* The name of the Database that will be used to store the Tech Bench data (note:  the database will be created if it does not already exist)
* The username and password of the user that will be used by the Tech Bench to access the Tech Bench database
