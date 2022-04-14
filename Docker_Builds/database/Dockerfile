FROM bitnami/mysql:latest

ENV MYSQL_ROOT_PASSWORD=tbRootPassword
ENV MYSQL_USER=tbUser
ENV MYSQL_PASSWORD=techBenchDatabase
ENV MYSQL_DATABASE=tech-bench

USER root

RUN apt update && apt upgrade -y --no-install-recommends

COPY ./my_custom.cnf /opt/bitnami/mysql/conf/bitnami/my_custom.cnf

USER 1001

WORKDIR /app
