#!/bin/sh
WEBDYNE_CONF=. perl -I../lib ./maketest.pl
WEBDYNE_CONF=./webdyne_meta.conf.pl WEBDYNE_TEST_FILE_PREFIX=03 perl -I../lib ./maketest.pl ./meta.psp 
WEBDYNE_CONF=. QUERY_STRING='name=Andrew&words=moe&color=blue' REQUEST_METHOD=GET WEBDYNE_TEST_FILE_PREFIX=04 perl -I../lib ./maketest.pl ./cgi.psp
