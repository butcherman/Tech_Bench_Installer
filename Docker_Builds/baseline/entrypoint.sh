#!/bin/bash

#################################################################################################
#                                                                                               #
#                                      Entrypoint Script                                        #
#                  If Tech Bench is not initialized, first time setup will occur                #
#                           After initialization, services will start                           #
#                                                                                               #
#################################################################################################

#  Fuction to compare version numbers
vercomp () {
    if [[ $1 == $2 ]]
    then
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
            return 2
        fi
    done
    return 0
}


set -m

echo "Starting Tech Bench"

#  During startup process, the MySQL container runs a self update command
#  To allow this update to finish properly and not cause issues with TB Boot
#  process, we will pause the TB startup process for 45 seconds
sleep 45

#  If the .env file does not exist, run the setup script to create the database and configuration
if [ ! -f "/app/.env" ]
then
    /scripts/setup.sh
#  Check if the version file is available in the /staging/config/ directory
elif [ -f "/staging/version" ]
then
    STAGED_VERSION=$(head -n 1 /staging/version)
    APP_VERSION=$(php /app/artisan version --format=compact | sed -e 's/Tech Bench //g')

    vercomp $STAGED_VERSION $APP_VERSION
    NEED_UPDATE=$?

    if [ $NEED_UPDATE == 1 ]
    then
        /scripts/update.sh
    fi
fi

#  Start the Horizon and PHP-FPM Services and run the Scheduler script
php /app/artisan horizon &
php-fpm -F --pid /opt/bitnami/php/tmp/php-fpm.pid -y /opt/bitnami/php/etc/php-fpm.conf &
/scripts/scheduler.sh &&
fg
