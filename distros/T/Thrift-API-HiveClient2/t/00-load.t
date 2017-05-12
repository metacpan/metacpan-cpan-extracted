#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

use_ok( 'Thrift::API::HiveClient2' ) || print "Bail out!\n";

diag( "Testing Thrift::API::HiveClient2 $Thrift::API::HiveClient2::VERSION, Perl $], $^X" );
