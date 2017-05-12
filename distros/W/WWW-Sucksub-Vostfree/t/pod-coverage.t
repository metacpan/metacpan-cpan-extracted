#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
plan tests => 1;
pod_coverage_ok("WWW::Sucksub::Vostfree",
		{ also_private => [qw ( base site dbsearch savedbm vosftree_dlfile  parse_vostfree  					dlbase sstsav start_vostf )],},
        	"WWW::Sucksub::Vostfree ok",);

