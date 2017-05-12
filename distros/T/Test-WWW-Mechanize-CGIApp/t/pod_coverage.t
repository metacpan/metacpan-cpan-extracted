#!perl

use strict;
use warnings;
use Test::More;

use lib 'lib';

eval "use Test::Pod::Coverage 1.04";

plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

all_pod_coverage_ok( { also_private => ['_cleanup_request _do_request'] },
		     
		     "Test::WWW::Mechanize::CGIApp is covered",
	           );
