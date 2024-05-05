#!/usr/bin/env bashio

check_port_availability() {
    local HOST="$1"
    local PORT="$2"
    local MAX_TRIES="$3"
    local TRIES=0
    while [ $TRIES -lt $MAX_TRIES ]; do
        if timeout 1 bash -c "</dev/tcp/$HOST/$PORT"; then
            bashio::log.info "Port $PORT is available"
            echo "0"
            return
        else
            bashio::log.warning "Port $PORT not yet available"
            TRIES=$((TRIES + 1))
            sleep 1
        fi
    done
    bashio::log.error "Port $PORT is not available after maximum attempts"
    echo "1"
}

LOG_FOLDER=/data/logs

bashio::log.info "Set SECRET"
SECRET="$(bashio::config 'SECRET')"
SECRET=change_me
export GOTRUE_JWT_SECRET=$SECRET
export APPFLOWY_GOTRUE_JWT_SECRET=$SECRET

bashio::log.info "Set ADMIN_EMAIL and ADMIN_PASSWORD"
bashio::log.warning "This only takes effect during the initial startup. Once the database is initialized, only the password can be changed via the web UI"
ADMIN_EMAIL="$(bashio::config 'ADMIN_EMAIL')"
ADMIN_PASSWORD="$(bashio::config 'ADMIN_PASSWORD')"
ADMIN_EMAIL='admin@example.com'
ADMIN_PASSWORD='password'
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
su postgres -c 'psql -f /appflowy_cloud/20230312043000_supabase_auth.sql' >>$LOG_FOLDER/postgres.log 2>&1

bashio::log.info "Initialize redis"
redis-server >>$LOG_FOLDER/redis.log 2>&1 &

bashio::log.info "Initialize minio"
minio server /data/minio >>$LOG_FOLDER/minio.log 2>&1 &

bashio::log.info "Initialize gotrue"
cd /gotrue
result=$(check_port_availability "localhost" "6379" 15)
if [ "$result" -eq 0 ]; then
    ./gotrue >>$LOG_FOLDER/gotrue.log 2>&1 &
else
    bashio::log.error "Cannot start gotrue due error with redis plese see $LOG_FOLDER/redis.log"
    exit 1
fi

bashio::log.info "Initialize appflowy cloud"
cd /appflowy_cloud
result=$(check_port_availability "localhost" "9999" 15)
if [ "$result" -eq 0 ]; then
    ./appflowy_cloud >>$LOG_FOLDER/appflowy_cloud.log 2>&1 &
    ./admin_frontend >>$LOG_FOLDER/appflowy_fronted.log 2>&1 &
else
    bashio::log.error "Cannot start appflowy cloud due error with gotrue plese see $LOG_FOLDER/gotrue.log"
    exit 1
fi

bashio::log.info "Initialize nginx"
nginx -g "daemon off;"
