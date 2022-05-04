# Tech_Bench_Installer

This repository is designed to hold Docker files to build the Tech Bench application.  Tech Bench is designed to run in a Docker environment and builds four separate containers.

* Tech Bench Application container that holds all logic and application files
* NGINX container that serves as the Web Host for the application
* MySQL Database container that holds all DB information
* REDIS container that holds cache and background job data

## Requirements

Tech Bench requires that Docker and Docker Compose are installed on the dedicated server for the application.  For more information regarding installing and setting up Docker, refer to the Docker website:  <https://www.docker.com/get-started/>

By default, Tech Bench is set to run only through HTTPS.  It is highly recommended to upload a valid SSL Certificate to the application.

## Installation Instructions

Download the included docker-compose.yml and .env files to the desired root folder of the application server.  To download the files using wget, enter the following commands:

```bash
wget https://raw.githubusercontent.com/butcherman/Tech_Bench_Installer/master/docker-compose.yml
wget https://raw.githubusercontent.com/butcherman/Tech_Bench_Installer/master/.env
```

Modify the .env file to include secure passwords and the Web URL that will be assigned during the system build.

To get around possible permission issues created by having different users and groups in different containers, create the necessary storage volumes and assign permissions to them with the following commands:

```bash
#  Create a Docker Group and add the current user to it
sudo groupadd docker
sudo usermod -aG docker $USER

#  Create the necessary file structure for application files and data storage
sudo mkdir -p appData/{database,redis}
sudo mkdir -p storageData/{disks,backups,logs,keystore}

sudo chmod 775 -R appData/ storageData
```

Run the command: ` docker-compose up -d ` to download, build and start the containers and run the Tech Bench application.

Visit the website URL provided in the .env file.  The initial login will be:

Username: admin

Password: password

You will be forced to change this password on the first login.

##  Upgrading Tech Bench

Updating the Tech Bench is as simple as replacing the Docker image with the latest image.  Run the following commands to perform the update:

```bash
docker pull butcherman/tech_bench_app:latest
docker-compose down
docker-compose up -d
```

Once the new image is booted, the system will automatically see the updated software and apply it.

Note:  The boot processes takes longer during an update.

## Troubleshooting

### .env Permissions Error

If you installed Docker Compose using Snap, you may run into permission issues and get the following error when running the `docker-compose` command:

```bash
PermissionError: [Errno 13] Permission denied: './.env'
```

If this happens, it is recommended to install Docker Compose via the official install tutorial found at <https://docs.docker.com/compose/install/>

### Error 502 Bad Gateway Message

This is normal during the boot process of the Tech Bench.  Until the application is fully up and running, you will get this error.  During the initial setup, this can take as long as 10 minutes.  To be sure that there are no errors happening, you can run the ```docker-compose up``` command without the ```-d``` to view all status messages as they are printed out to watch for errors.  It is recommended to do this on first run to make sure that everything comes up correctly.

### Error 500 This Page Isn't Working Message

If you did not create the folder structure during the install process, the Docker Containers cannot write to the hard drive.  You will need to go back and modify the folder permissions to allow Docker to have access to these folders.

### IMPORTANT NOTE

It is the responsibility of the system administrator to install and maintain the operating system and web server with the latest updates and security patches.

## Copyright © 2022 Butcherman

This program is free software:  you can redistribute it and/or modify it under the terms of the GNU
General Public License as published by the Free Software Foundation, either version 2 of the License,
or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see
www.gnu.org/licenses.
