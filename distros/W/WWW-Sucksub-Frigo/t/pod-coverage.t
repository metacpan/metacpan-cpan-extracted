#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
plan tests => 1;
pod_coverage_ok(	"WWW::Sucksub::Frigo",
			{ also_private => [qw ( _init _search_direct_link _search_frigorifix _savedbm nbres loginpage srchadr sstsav )],},
        		"WWW::Sucksub::Frigo ok",);

