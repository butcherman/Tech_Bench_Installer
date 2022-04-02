#!/bin/bash

#################################################################################################
#                                                                                               #
#                                      Entrypoint Script                                        #
#                  If Tech Bench is not initialized, first time setup will occur                #
#                           After initialization, services will start                           #
#                                                                                               #
#################################################################################################

set -m

echo "Starting Tech Bench"
sleep 45    #  Pause to allow other containers to finish coming online

#  If the .env file does not exist, run the setup script to create the database and configuration
if [ ! -f "/app/.env" ]
then
    /scripts/setup.sh
fi

#  Start the Horizon and PHP-FPM Services and run the Scheduler script
/usr/bin/supervisord -c /etc/supervisor/supervisord.conf &
php-fpm -F --pid /opt/bitnami/php/tmp/php-fpm.pid -y /opt/bitnami/php/etc/php-fpm.conf &
/scripts/scheduler.sh &&
fg
