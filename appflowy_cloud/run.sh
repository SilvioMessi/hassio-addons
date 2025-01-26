#!/usr/bin/env bashio

check_port_availability() {
    local HOST="$1"
    local PORT="$2"
    local MAX_TRIES="$3"
    local NAME="$4"
    local TRIES=0
    while [ $TRIES -lt $MAX_TRIES ]; do
        if timeout 1 bash -c "</dev/tcp/$HOST/$PORT"; then
            bashio::log.info "Port $PORT is available"
            return
        else
            bashio::log.warning "Port $PORT not yet available"
            TRIES=$((TRIES + 1))
            sleep 1
        fi
    done
    bashio::log.error "Port $PORT is not available after maximum attempts"
    bashio::log.error "Cannot start $NAME, plese see $LOG_FOLDER/$NAME.log"
    exit 1
}

LOG_FOLDER=/data/logs

bashio::log.info "Set parameters"
SECRET="$(bashio::config 'SECRET')"
ADMIN_EMAIL="$(bashio::config 'ADMIN_EMAIL')"
ADMIN_PASSWORD="$(bashio::config 'ADMIN_PASSWORD')"
PUBLIC_URL="$(bashio::config 'PUBLIC_URL')"
SMTP_HOST="$(bashio::config 'SMTP_HOST')"
SMTP_PORT="$(bashio::config 'SMTP_PORT')"
SMTP_USER="$(bashio::config 'SMTP_USER')"
SMTP_PASSWORD="$(bashio::config 'SMTP_PASSWORD')"

export GOTRUE_JWT_SECRET=$SECRET
export APPFLOWY_GOTRUE_JWT_SECRET=$SECRET
export GOTRUE_ADMIN_EMAIL=$ADMIN_EMAIL
export APPFLOWY_GOTRUE_ADMIN_EMAIL=$ADMIN_EMAIL
export GOTRUE_ADMIN_PASSWORD=$ADMIN_PASSWORD
export APPFLOWY_GOTRUE_ADMIN_PASSWORD=$ADMIN_PASSWORD
export GOTRUE_JWT_ADMIN_GROUP_NAME=supabase_admin
export GOTRUE_SMTP_HOST=$SMTP_HOST
export GOTRUE_SMTP_PORT=$SMTP_PORT
export GOTRUE_SMTP_USER=$SMTP_USER
export GOTRUE_SMTP_PASS=$SMTP_PASSWORD
export GOTRUE_SMTP_ADMIN_EMAIL=$SMTP_USER
export API_EXTERNAL_URL="$PUBLIC_URL/gotrue"
export APPFLOWY_GOTRUE_EXT_URL="$PUBLIC_URL/gotrue"
export AF_GOTRUE_URL="$PUBLIC_URL/gotrue"
export GOTRUE_SITE_URL=$PUBLIC_URL
export APPFLOWY_WEB_URL=$PUBLIC_URL
export AF_BASE_URL=$PUBLIC_URL

bashio::log.info "Log cleanup"
if [ -d $LOG_FOLDER ]; then
    rm -rf $LOG_FOLDER
fi
mkdir -p $LOG_FOLDER

bashio::log.info "Initialize database"
if [ ! -d /data/postgresql ]; then
    mkdir -p /data/postgresql >>$LOG_FOLDER/postgres.log 2>&1
    chown postgres:postgres /data/postgresql >>$LOG_FOLDER/postgres.log 2>&1
    su postgres -c 'initdb -D /data/postgresql' >>$LOG_FOLDER/postgres.log 2>&1
fi
su postgres -c 'pg_ctl start -D /data/postgresql' >>$LOG_FOLDER/postgres.log 2>&1
sh /appflowy_cloud/migrations/before/supabase_auth.sh >>$LOG_FOLDER/postgres.log 2>&1

bashio::log.info "Initialize redis"
redis-server >>$LOG_FOLDER/redis.log 2>&1 &
check_port_availability "localhost" "6379" 15 "redis"

bashio::log.info "Initialize minio"
minio server /data/minio >>$LOG_FOLDER/minio.log 2>&1 &
check_port_availability "localhost" "9000" 15 "minio"

bashio::log.info "Initialize auth"
cd /auth
./start.sh >>$LOG_FOLDER/auth.log 2>&1 &
check_port_availability "localhost" "9999" 15 "auth"

bashio::log.info "Initialize appflowy cloud"
cd /appflowy_cloud
./appflowy_cloud >>$LOG_FOLDER/appflowy_cloud.log 2>&1 &
./admin_frontend >>$LOG_FOLDER/appflowy_fronted.log 2>&1 &
./appflowy_worker >>$LOG_FOLDER/appflowy_worker.log 2>&1 &

bashio::log.info "Initialize appflowy web"
cd /appflowy_web
sh ./env.sh >>$LOG_FOLDER/appflowy_web.log 2>&1 &

bashio::log.info "Initialize nginx"
nginx -g "daemon off;"
