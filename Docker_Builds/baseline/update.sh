#!/bin/bash

cd /app
php artisan migrate --force

#  Cache Files
# php artisan config:cache
php artisan route:cache
