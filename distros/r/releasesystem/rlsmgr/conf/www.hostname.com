#!/bin/sh

cd /opt/ims/ahp-bin
#access database
#exec ./rlsmgrd www.host.com -H www.host.com -t 3 -T /opt/ims/www.host.com/logs/rlsmgr/TRACELOG -f
#below line uses config file instead of database
exec ./rlsmgrd www.host.com -H www.host.com -t 3 -T /opt/ims/projects/www.host.com/logs/rlsmgr/TRACELOG -f -c /opt/ims/ahp-bin/www.host.com

# Just in case
exit
# Default file-based config for www.host.com
CGI_ROOT=$SERVER_ROOT/cgi-bin
DOCUMENT_ROOT=$SERVER_ROOT/htdocs
FCGI_ROOT=$SERVER_ROOT/fcgi-bin
GROUP_GID=idsweb
HTTP_AUTH_PASSWD=xxx
HTTP_AUTH_USER=user
INCOMING_DIR=$SERVER_ROOT/incoming
LOGGING_DIR=$SERVER_ROOT/logs
MAX_CHILD_PROCS=10
MIRROR_NAME=www.host.com
OWNER_UID=idsweb
PKG_LOGGING_DIR=$LOGGING_DIR/Pushes
SCAN_PERIOD_SECS=30
SERVER_ROOT=/opt/ims/projects/www.host.com/content
SIGNATURE_TYPE=md5
STAGE_1_TOOL=rlsmgrd
STAGE_2_TOOL=deploy_content
STAGE_3_TOOL=process_content
STAGING_DIR=$SERVER_ROOT/staging
UPLOAD_REALM=IMS-Host
UPLOAD_URL=/cgi-bin/upload.pl
WEBLIST_FILE=weblist
WEBMASTER=webmaster@host.com
