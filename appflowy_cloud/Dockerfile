ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base:3.20

FROM node:20.12.0 AS build-web
ARG APPFLOWY_WEB_VERSION=v0.1.18
WORKDIR /app
RUN npm install -g pnpm@8.5.0
RUN git clone https://github.com/AppFlowy-IO/AppFlowy-Web.git --depth 1 --branch $APPFLOWY_WEB_VERSION .
RUN pnpm install
RUN sed -i 's|https://test.appflowy.cloud||g' src/components/main/app.hooks.ts
RUN pnpm run build

FROM $BUILD_FROM AS build
ARG BUILD_VERSION=main
WORKDIR /appflowy_cloud
RUN apk add --no-cache git
RUN git clone https://github.com/AppFlowy-IO/AppFlowy-Cloud.git --depth 1 --branch $BUILD_VERSION
WORKDIR /go/src/supabase
RUN apk add --no-cache go
RUN git clone https://github.com/AppFlowy-IO/auth.git --depth 1 --branch 0.8.0
WORKDIR /go/src/supabase/auth
RUN CGO_ENABLED=0 go build -o /auth .
WORKDIR /pgvector
RUN apk add --no-cache build-base
RUN apk add --no-cache postgresql16-dev
RUN git clone --branch v0.7.0  https://github.com/pgvector/pgvector.git
WORKDIR /pgvector/pgvector
RUN make
RUN make install

FROM $BUILD_FROM
# add redis
RUN apk add --no-cache redis
# add postgresql
RUN apk add --no-cache postgresql16 postgresql16-contrib
COPY --from=build /usr/lib/postgresql16/bitcode/vector.index.bc /usr/lib/postgresql16/bitcode/vector.index.bc
COPY --from=build /usr/lib/postgresql16/vector.so /usr/lib/postgresql16/vector.so
COPY --from=build /usr/share/postgresql16/extension /usr/share/postgresql16/extension
# add minio
RUN apk add --no-cache minio
# add nginx
RUN apk add --no-cache nginx
# add auth
RUN mkdir /auth 
COPY --from=build /auth /auth
COPY --from=build /go/src/supabase/auth/migrations /auth/migrations
COPY --from=build /appflowy_cloud/AppFlowy-Cloud/docker/gotrue/start.sh /auth
# add appflowy cloud
RUN mkdir /appflowy_cloud
COPY appflowy_cloud /appflowy_cloud
RUN chmod +x /appflowy_cloud/appflowy_cloud
COPY admin_frontend /appflowy_cloud
RUN chmod +x /appflowy_cloud/admin_frontend
COPY appflowy_worker /appflowy_cloud
RUN chmod +x /appflowy_cloud/appflowy_worker
COPY --from=build /appflowy_cloud/AppFlowy-Cloud/admin_frontend/assets /appflowy_cloud/assets
COPY --from=build /appflowy_cloud/AppFlowy-Cloud/migrations /appflowy_cloud/migrations
# add appflowy web
RUN mkdir /appflowy_web
COPY --from=build-web /app/dist /usr/share/nginx/html/
# setup postgresql
# https://luppeng.wordpress.com/2020/02/28/install-and-start-postgresql-on-alpine-linux/
RUN mkdir /run/postgresql
RUN chown postgres:postgres /run/postgresql/
# setup nginx
COPY nginx.conf /etc/nginx/nginx.conf
# add entrypoint script
COPY run.sh run.sh
RUN chmod +x run.sh
ENTRYPOINT ["bashio", "run.sh"]