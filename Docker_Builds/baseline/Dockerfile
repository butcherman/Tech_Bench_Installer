#################################################################################################
#                                                                                               #
#            Baseline Tech Bench build does not have Tech Bench App, only                       #
#                  basic install point in which to build app off of                             #
#                all versions of Tech Bench start with this OS build                            #
#                         scripts and app copied later                                          #
#                                                                                               #
#################################################################################################

FROM bitnami/php-fpm:8.1

ENV TB_URL=localhost
ENV ENABLE_HTTPS=true

WORKDIR /tmp

#  Entrypoint and update scripts along with any other necessary shell scripts will be copied here
RUN mkdir /scripts

#  Basic scripts for Starting, Initializing and Updating Tech Bench App
COPY ./download_tb.sh /scripts/
COPY ./entrypoint.sh /scripts/
COPY ./update.sh /scripts/
COPY ./setup.sh /scripts/
COPY ./scheduler.sh /scripts/

RUN apt update && apt upgrade -y --no-install-recommends

#  Install php modules
RUN apt install -yq php-dom \
        php-zip \
        php-gd \
        php-pdo \
        php-mbstring \
        php-redis \
        unzip \
        zip \
        curl \
        git \
        nano \
        supervisor \
        cron

#  Copy over Supervisor config files
COPY worker.conf /etc/supervisor/conf.d/worker.conf
COPY supervisord.conf /etc/supervisor/supervisord.confcc

#  Install and update NodeJS and NPM
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && apt install -y nodejs
RUN npm install -g npm@latest

#  Update Composer
RUN composer self-update --2

WORKDIR /app

ENTRYPOINT [ "/scripts/entrypoint.sh" ]