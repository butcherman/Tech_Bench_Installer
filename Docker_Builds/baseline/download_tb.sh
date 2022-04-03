#!/bin/bash

#################################################################################################
#                                                                                               #
#                                      Download Script                                          #
#                      Download and install the Tech Bench application                          #
#                                                                                               #
#################################################################################################

#  Variables
BRANCH=$1           #  If this argument is populated, the branch identified will be downloaded and installed
VERSION=$2          #  If BRANCH is left to false, this version will be downloaded.  Default value is "latest"

mkdir /tmp/downloads
cd /tmp/downloads

#  Determine if we are using a Github Branch, or downloading an official release
if [ "${BRANCH}" != false ];
then
    URL=https://github.com/butcherman/tech_bench/archive/$BRANCH.zip;
else
    URL=$(curl -s https://api.github.com/repos/butcherman/tech_bench/releases/$VERSION | grep zipball_url | cut -d : -f 2,3 | tr -d \" | tr -d \,)
fi

#  Download package
curl -LJO $URL

#  Extract package
FILE_ROOT=(*)
unzip -o $FILE_ROOT

#  Copy files to the /app directory
DIRNAME=$(zipinfo -1 $FILE_ROOT | grep -o "^[^/]\+[/]" | sort -u | tr -d \/)
cd $DIRNAME
cp -R * /app/
cp .env.example /app/.env.example

#  Create a staging directory for future updates
mkdir /staging
cp -R * /staging/

#  Make a Keystore directory for SSL Certificates
mkdir /app/keystore
chmod 777 /app/keystore         #  TODO - correct permissions

#  Cleanup
rm -rf /tmp/downloads/
