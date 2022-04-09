#!/bin/bash

#################################################################################################
#                                                                                               #
#                                      Entrypoint Script                                        #
#              If there is no SSL Cert, create one before running Bitnami entrypoint            #
#                                                                                               #
#################################################################################################

echo "Starting NGINX"

#  If the SSL file does not exist, create a self signed SSL cert
if [ ! -f "/app/keystore/server.crt" ]
then
    #  Generate self signed SSL Certificate
    echo "Creating Self Signed SSL Certificate"
    openssl rand -base64 48 > /tmp/passphrase.txt
    openssl genrsa -aes128 -passout file:/tmp/passphrase.txt -out /tmp/server.key 2048
    openssl req -new -passin file:/tmp/passphrase.txt -key /tmp/server.key -out /tmp/server.csr -subj "/C=FR/O=tb/OU=Domain Control Validated/CN=$TB_URL"       #  FIXME - copy host name from .env file
    cp /tmp/server.key /tmp/server.key.org
    openssl rsa -in /tmp/server.key.org -passin file:/tmp/passphrase.txt -out /tmp/server.key
    openssl x509 -req -days 36500 -in /tmp/server.csr -signkey /tmp/server.key -out /tmp/server.crt

    #  Move the new certificate and key to the Tech Bench directory
    mkdir -p /app/keystore/private
    mv /tmp/server.crt /app/keystore/server.crt
    mv /tmp/server.key /app/keystore/private/server.key

    #  Cleanup unneeded files
    rm -rf /tmp/server.csr /tmp/server.key.org /tmp/passphrase.txt
fi

#  Run the original entrypoint script
/opt/bitnami/scripts/nginx/entrypoint.sh /opt/bitnami/scripts/nginx/run.sh
