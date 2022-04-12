FROM bitnami/nginx:latest

ENV TB_URL=localhost
ENV ENABLE_HTTPS=true

USER root

COPY ./http.conf /opt/bitnami/nginx/conf/server_blocks/tech_bench_http.conf
COPY ./https.conf /opt/bitnami/nginx/conf/server_blocks/tech_bench_https.conf
COPY ./entrypoint.sh /scripts/

WORKDIR /app

ENTRYPOINT [ "/scripts/entrypoint.sh" ]
