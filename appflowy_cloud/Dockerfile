ARG BUILD_FROM
FROM $BUILD_FROM as build
RUN apk add --no-cache git
RUN apk add --no-cache openssl-dev
RUN apk add --no-cache protobuf-dev
RUN apk add --no-cache cargo
WORKDIR /appflowy_cloud
ARG BUILD_VERSION
RUN git clone https://github.com/AppFlowy-IO/AppFlowy-Cloud.git --depth 1 --branch $BUILD_VERSION
WORKDIR /appflowy_cloud/AppFlowy-Cloud
ENV RUST_BACKTRACE=1
ENV OPENSSL_NO_VENDOR=Y
ENV PROTOC=/usr/bin/protoc
RUN rm /appflowy_cloud/AppFlowy-Cloud/libs/collab-rt-entity/build.rs
RUN cargo build --release --bin appflowy_cloud
WORKDIR /appflowy_cloud/AppFlowy-Cloud/admin_frontend
RUN cargo build --release --bin admin_frontend
WORKDIR /gotrue
RUN apk add --no-cache go
RUN git clone https://github.com/supabase/gotrue.git --depth 1 --branch v2.117.0
WORKDIR /gotrue/gotrue
RUN cp /appflowy_cloud/AppFlowy-Cloud/docker/gotrue.patch .
RUN git apply gotrue.patch
ENV CGO_ENABLED=0
RUN go build -o /gotrue/gotrue/build/gotrue .

FROM $BUILD_FROM
# add redis
RUN apk add --no-cache redis
# add postgresql
RUN apk add --no-cache postgresql13 postgresql13-contrib
# add minio
RUN apk add --no-cache minio
# add nginx
RUN apk add --no-cache nginx
# add gotrue
RUN mkdir /gotrue
COPY --from=build /gotrue/gotrue/build/gotrue /gotrue
COPY --from=build /gotrue/gotrue/migrations /gotrue/migrations
# add appflowy cloud
RUN mkdir /appflowy_cloud
COPY --from=build /appflowy_cloud/AppFlowy-Cloud/target/release/appflowy_cloud /appflowy_cloud
COPY --from=build /appflowy_cloud/AppFlowy-Cloud/target/release/admin_frontend /appflowy_cloud
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
