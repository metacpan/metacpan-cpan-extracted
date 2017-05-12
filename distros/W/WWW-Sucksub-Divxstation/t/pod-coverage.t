#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
plan tests => 1;
pod_coverage_ok(	"WWW::Sucksub::Divxstation",
			{ also_private => [qw ( cookies_file open_html parse_divxstation save_dbm search_dbm sstsav)],},
        		"WWW::Sucksub::Divxstation ok",);


