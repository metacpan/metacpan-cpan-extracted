#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
plan tests => 1;
pod_coverage_ok("WWW::Sucksub::Attila",
		{ also_private => [qw (get_all_result parse_attila save_dbm sstsav start_attila text_attila )],},
        	"WWW::Sucksub::Attila ok",);
