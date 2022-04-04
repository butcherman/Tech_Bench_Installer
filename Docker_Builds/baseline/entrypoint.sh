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
sleep 45                        #  Pause to allow other containers to finish coming online

#  If the .env file does not exist, run the setup script to create the database and configuration
if [ ! -f "/app/.env" ]
then
    /scripts/setup.sh
fi

#  Check if the version file is available in the /app/config/ directory
if [ -f "/app/config/version.yml" ]
then
    #  Get staged version
    cd /staging
    composer install --no-dev --no-interaction --optimize-autoloader  --no-ansi >> /dev/null 2>&1
    STAGED_VERSION=$(php artisan version --format=compact | sed -e 's/Tech Bench //g')

    #  Get current version
    cd /app
    CURRENT_VERSION=$(php artisan version --format=compact | sed -e 's/Tech Bench //g')

    vercomp $STAGED_VERSION $CURRENT_VERSION
    NEED_UPDATE=$?

    #  If the staged version of the app is newer than the used version, copy the files into the /app directory
    if [ $NEED_UPDATE  == 1 ]
    then
        /scripts/update.sh
    fi
fi

#  Start the Horizon and PHP-FPM Services and run the Scheduler script
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf &
php-fpm -F --pid /opt/bitnami/php/tmp/php-fpm.pid -y /opt/bitnami/php/etc/php-fpm.conf &
/scripts/scheduler.sh &&
fg
