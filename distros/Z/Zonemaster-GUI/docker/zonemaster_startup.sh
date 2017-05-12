# zonemaster_startup.sh
#postgres -D /postgresql_data >/tmp/postgres.log 2>&1 &
su - postgres -c "postgres -D /postgresql_data" & 

sleep 5

su - postgres -c "psql -c \"create user travis_zonemaster WITH PASSWORD 'travis_zonemaster';\""
su - postgres -c "psql -c 'create database travis_zonemaster OWNER travis_zonemaster;'"

cd /zonemaster-backend
ZONEMASTER_BACKEND_CONFIG_FILE=./share/travis_postgresql_backend_config.ini perl -I./lib ./script/create_db_postgresql_9.3.pl
ZONEMASTER_RECORD=0 ZONEMASTER_BACKEND_CONFIG_FILE=./share/travis_postgresql_backend_config.ini starman --port 50000 -I./lib -I../zonemaster-engine/lib ./script/zonemaster_webbackend.psgi &
ZONEMASTER_BACKEND_CONFIG_FILE=./share/travis_postgresql_backend_config.ini perl -I./lib ./script/zm_wb_daemon start

cd /zonemaster-gui
ZONEMASTER_RECORD=0 ZONEMASTER_BACKEND_PORT=50000 starman --port 50080 -I./lib ./zm_app/bin/app.pl &
/bin/bash