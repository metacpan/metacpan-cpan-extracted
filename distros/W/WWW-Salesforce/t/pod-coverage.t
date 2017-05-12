use strict;
use Test::More;
use Test::Pod::Coverage;

plan skip_all => 'set TEST_POD to enable this test (developer only!)'
        unless $ENV{TEST_POD};

plan tests => 1;
pod_coverage_ok( "WWW::Salesforce" );
