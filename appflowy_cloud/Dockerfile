ARG BUILD_FROM
FROM $BUILD_FROM as build
WORKDIR /appflowy_cloud
RUN apk add --no-cache git=2.43.0-r0
RUN git clone https://github.com/AppFlowy-IO/AppFlowy-Cloud.git --depth 1 --branch 0.3.22
WORKDIR /gotrue
RUN apk add --no-cache go=1.21.9-r0
RUN git clone https://github.com/supabase/gotrue.git --depth 1 --branch v2.117.0
WORKDIR /gotrue/gotrue
RUN cp /appflowy_cloud/AppFlowy-Cloud/docker/gotrue.patch .
RUN git apply gotrue.patch
ENV CGO_ENABLED=0
RUN go build -o /gotrue/gotrue/build/gotrue .

FROM $BUILD_FROM
# add redis
RUN apk add --no-cache redis=7.2.4-r0
# add postgresql
RUN apk add --no-cache postgresql13=13.14-r0 postgresql13-contrib==13.14-r0
# add minio
RUN apk add --no-cache minio=0.20240131.202033-r2
# add nginx
RUN apk add --no-cache nginx=1.24.0-r15
# add gotrue
RUN mkdir /gotrue
COPY --from=build /gotrue/gotrue/build/gotrue /gotrue
COPY --from=build /gotrue/gotrue/migrations /gotrue/migrations
# add appflowy cloud
RUN mkdir /appflowy_cloud
COPY aarch64-unknown-linux-gnu-appflowy_cloud /appflowy_cloud/appflowy_cloud
COPY aarch64-unknown-linux-gnu-admin_frontend /appflowy_cloud/admin_frontend
COPY --from=build /appflowy_cloud/AppFlowy-Cloud/admin_frontend/assets /appflowy_cloud/assets
COPY --from=build /appflowy_cloud/AppFlowy-Cloud/migrations/before /appflowy_cloud
# setup postgresql
# https://luppeng.wordpress.com/2020/02/28/install-and-start-postgresql-on-alpine-linux/
RUN mkdir /run/postgresql
RUN chown postgres:postgres /run/postgresql/
USER postgres
RUN mkdir /var/lib/postgresql/data
RUN initdb -D /var/lib/postgresql/data
USER root
# setup nginx
COPY nginx.conf /etc/nginx/nginx.conf
# add entrypoint script
COPY run.sh run.sh
RUN chmod +x run.sh
ENTRYPOINT ["sh", "run.sh"]
