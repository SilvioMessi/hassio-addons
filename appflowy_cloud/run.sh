#!/bin/bash
su postgres -c 'pg_ctl start -D /var/lib/postgresql/data'
su postgres -c 'psql -f /appflowy_cloud/20230312043000_supabase_auth.sql'
redis-server &
minio server /minio &
sleep 2
cd /gotrue
./gotrue &
sleep 2
cd /appflowy_cloud
./appflowy_cloud &
./admin_frontend &
sleep 2
nginx -g "daemon off;"