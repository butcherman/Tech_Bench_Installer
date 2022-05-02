#!/bin/bash

#################################################################################################
#                                                                                               #
#                                       Update Script                                           #
#                  Complete the update process by copying files in the staging                  #
#                               directory to the app directory                                  #
#                                                                                               #
#################################################################################################

echo 'Completing system update'

#  Copy all staged files to /app directory
cp -R /staging/* /app/

#  Update and compile all dependencies
cd /app
composer install --no-dev --no-interaction --optimize-autoloader  --no-ansi >> /dev/null 2>&1
npm install >> /dev/null 2>&1
npm run production

#  Create the database
php /app/artisan migrate --force

#  Cache configuration files
# php /app/artisan config:cache
php /app/artisan breadcrumbs:cache
php /app/artisan route:cache
php /app/artisan view:cache

echo 'Update Completed'
