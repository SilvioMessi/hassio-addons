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

bashio::log.info "Set SECRET"
SECRET="$(bashio::config 'SECRET')"
export GOTRUE_JWT_SECRET=$SECRET
export APPFLOWY_GOTRUE_JWT_SECRET=$SECRET

bashio::log.info "Set ADMIN_EMAIL and ADMIN_PASSWORD"
ADMIN_EMAIL="$(bashio::config 'ADMIN_EMAIL')"
ADMIN_PASSWORD="$(bashio::config 'ADMIN_PASSWORD')"
export APPFLOWY_GOTRUE_ADMIN_EMAIL=$ADMIN_EMAIL
export APPFLOWY_GOTRUE_ADMIN_PASSWORD=$ADMIN_PASSWORD

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

bashio::log.info "Initialize redis"
redis-server >>$LOG_FOLDER/redis.log 2>&1 &
check_port_availability "localhost" "6379" 15 "redis"

bashio::log.info "Initialize minio"
minio server /data/minio >>$LOG_FOLDER/minio.log 2>&1 &
check_port_availability "localhost" "9000" 15 "minio"

bashio::log.info "Initialize gotrue"
cd /gotrue
./gotrue >>$LOG_FOLDER/gotrue.log 2>&1 &
check_port_availability "localhost" "9999" 15 "gotrue"

bashio::log.info "Initialize appflowy cloud"
cd /appflowy_cloud
./appflowy_cloud >>$LOG_FOLDER/appflowy_cloud.log 2>&1 &
./admin_frontend >>$LOG_FOLDER/appflowy_fronted.log 2>&1 &
./appflowy_worker >>$LOG_FOLDER/appflowy_worker.log 2>&1 &

bashio::log.info "Initialize nginx"
nginx -g "daemon off;"
