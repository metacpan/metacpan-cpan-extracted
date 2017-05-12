#!/usr/local/bin/perl -w

use Test::More tests => 1;
use BerkeleyDB;

cmp_ok( $BerkeleyDB::db_version, '>=', 3.0, 'Verify BerkeleyDB 3.x or later compatibility' );
#cmp_ok( substr($BerkeleyDB::db_version, 0, 3), 'ne', 4.4, 'Verify BerkeleyDB 4.x compatibility' );
