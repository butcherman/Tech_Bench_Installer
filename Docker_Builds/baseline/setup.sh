#!/bin/bash

#################################################################################################
#                                                                                               #
#                                      Setup Script                                             #
#                  If Tech Bench is not initialized, first time setup will occur                #
#                                                                                               #
#################################################################################################

echo "New installation of Tech Bench detected"
echo "Setting up the application for the first time"
echo "Please wait...."
cd /app

#  Create .env file
cp /app/.env.example /app/.env
#  Add App URL to the .env file
sed -i "s/localhost/$TB_URL/g" /app/.env

#  If Enable HTTPS is turned off, then modify it in the .env file
if [ ! $ENABLE_HTTPS ]
then
    sed -i 's/https/http/g' /app/.env
fi

#  Create Encryption Key
echo "Creating Encryption Key"
php artisan key:generate --force

#  Create symbolic link for public directory
php artisan storage:link -q

#  Create the database
php /app/artisan migrate --force

#  Cache configuration files
# php /app/artisan config:cache
php /app/artisan breadcrumbs:cache
php /app/artisan route:cache
php /app/artisan view:cache
