package main;

use strict;
use warnings;

BEGIN {
    eval {
	require Test::More;
	Test::More->import();
	1;
    } or do {
	print "1..0 # skip Test::More required to test pod coverage.\n";
	exit;
    };

}

BEGIN {
    eval {
	require lib;
	lib->import( 'inc' );
	require My::Module::Test;
	My::Module::Test->import();
	1;
    } or do {
	diag $@;
	print "1..0 # skip My::Module::Test required to test pod coverage.\n";
	exit;
    };
    eval {
	require Test::Pod::Coverage;
	Test::Pod::Coverage->VERSION( 1.00 );
	Test::Pod::Coverage->import();
	1;
    } or do {
	print <<eod;
1..0 # skip Test::Pod::Coverage 1.00 or greater required.
eod
	exit;
    };
}

all_pod_coverage_ok ({coverage_class => 'Pod::Coverage::CountParents'});

1;
