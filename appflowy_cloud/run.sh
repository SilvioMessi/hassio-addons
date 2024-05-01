#!/bin/bash
if [ ! -d /data/postgresql ]; then
    mkdir -p /data/postgresql
    chown postgres:postgres /data/postgresql
    su postgres -c 'initdb -D /data/postgresql'
fi
su postgres -c 'pg_ctl start -D /data/postgresql'
su postgres -c 'psql -f /appflowy_cloud/20230312043000_supabase_auth.sql'
redis-server &
minio server /data/minio &
sleep 15
cd /gotrue
./gotrue &
sleep 15
cd /appflowy_cloud
./appflowy_cloud &
./admin_frontend &
sleep 5
nginx -g "daemon off;"