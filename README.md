# Tech_Bench_Installer

This repository is designed to hold Docker files to build the Tech Bench application.  Tech Bench is designed to run in a Docker environment and builds four separate containers.

* Tech Bench Application container that holds all logic and application files
* NGINX container that serves as the Web Host for the application
* MySQL Database container that holds all DB information
* REDIS container that holds cache and background job data

## Requirements

Tech Bench requires that Docker and Docker Compose are installed on the dedicated server for the application.  For more information regarding installing and setting up Docker,
refer to the Docker website:  <https://www.docker.com/get-started/>

By default, Tech Bench is set to run only through HTTPS.  It is highly recommended to upload a valid SSL Certificate to the application.

## Installation Instructions

Download the included docker-compose.yml and .env files to the desired root folder of the application server.
Modify the .env file to include secure passwords and the Web URL that will be assigned during the system build.
Run the command: ` docker-compose up -d ` to download, build and start the containers and run the Tech Bench application.

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
