#!/bin/bash

#################################################################################################
#                                                                                               #
#                                      Scheduler Script                                         #
#                          This script runs the Laravel Task Scheduler                          #
#                                                                                               #
#################################################################################################

echo "Starting Task Scheduler"

while [ true ]
do
    #  Run the command schedule:run every 60 seconds
    php /app/artisan schedule:run --verbose --no-interaction &
    sleep 60
done
