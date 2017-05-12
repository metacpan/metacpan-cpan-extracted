#!/usr/bin/perl

# Test specific functions in Devel::Pler

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 11;
use File::Spec::Functions ':ALL';
use pler;

# Can we find the current perl executable ok
ok( pler::perl(), 'Got perl() ok' );
ok( pler::perl,   'Got perl   ok' );
ok( -f pler::perl, 'perl exists'  );
ok( file_name_is_absolute( pler::perl ), 'perl path is absolute' );

# Can we find the mandated make
ok( pler::make(), 'Got make() ok' );
ok( pler::make,   'Got make   ok' );
ok( -f pler::make, 'make exists'  );
ok( file_name_is_absolute( pler::make ), 'make path is absolute' );

# Filter tests
my @tests = qw{
	t/01_compile.t
	t/02_functions.t
	t/22_something.t
};

is_deeply(
	pler::filter(
		[ 'functions' ],
		[ @tests   ],
	),
	[ 't/02_functions.t' ],
	'Simple term ok',
);

is_deeply(
	pler::filter(
		[ '22' ],
		[ @tests ],
	),
	[ 't/22_something.t' ],
);

is_deeply(
	pler::filter(
		[ '2' ],
		[ @tests ],
	),
	[ 't/02_functions.t' ],
);
