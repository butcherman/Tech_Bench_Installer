#################################################################################################
#                                                                                               #
#                      Tech Bench build for main Tech Bench Application                         #
#                                                                                               #
#################################################################################################

FROM butcherman/tech_bench_baseline:1.0

ARG BRANCH=false
ARG VERSION=latest

#  Make sure image is up to date
RUN apt update && apt upgrade -y --no-install-recommends

#  Update npm and composer
RUN npm install -g npm@latest
RUN composer self-update

#  Download application files
RUN /scripts/download_tb.sh ${BRANCH} ${VERSION}

#  Create a group and user to run the file permissions
RUN addgroup --gid 1024 tbgroup
RUN adduser --disabled-password --gecos "" --force-badname --ingroup tbgroup tbuser
RUN usermod -a -G root tbuser
RUN chmod 775 /var/log

#  Set directory permissions
RUN chown -R tbuser:tbgroup /app
RUN find /app/ -type f -exec chmod 644 {} \;
RUN find /app/ -type d -exec chmod 755 {} \;
RUN chmod -R 777 /app/storage
RUN chmod -R 777 /app/keystore

#  Set same directory permissions for staging directory
RUN chown -R tbuser:tbgroup /staging
RUN find /staging/ -type f -exec chmod 644 {} \;
RUN find /staging/ -type d -exec chmod 755 {} \;
RUN chmod -R 777 /staging/storage

USER tbuser

WORKDIR /app

#  Install dependencies
RUN composer install --no-dev --no-interaction --optimize-autoloader
RUN npm install --only-production
RUN npm run production

#  Place a version file in the staging directory to note what version this image is
RUN echo $(php /app/artisan version --format=compact | sed -e 's/Tech Bench //g') > /staging/version
