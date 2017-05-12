#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WebService::Amazon::ElasticBeanstalk' ) || print "Bail out!\n";
}

diag( "Testing WebService::Amazon::ElasticBeanstalk $WebService::Amazon::ElasticBeanstalk::VERSION, Perl $], $^X" );
