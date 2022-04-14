FROM bitnami/redis:latest

ENV REDIS_PASSWORD=tbRootPassword

USER root

RUN apt update && apt upgrade -y --no-install-recommends

USER 1001

WORKDIR /app
