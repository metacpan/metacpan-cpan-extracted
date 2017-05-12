#!/usr/bin/perl -w

# Compile testing for only::matching

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use vars qw{$VERSION $LOADED};
BEGIN {
	$VERSION = '0.02';
	$LOADED  = 0;
}

use Test::More tests => 33;

# Test that the module matches the version for this test
use_ok( 'only::matching', 't::lib::MyTestModule' );
is( $LOADED, 10, 'Called ->import ok' );

# Call with no params
use_ok( 'only::matching', 't::lib::MyTestModule', [] );
is( $LOADED, 10, 'Called ->import ok' );

# Call with params
use_ok( 'only::matching', 't::lib::MyTestModule', 'foo', 'bar', 'bar' );
is( $LOADED, 23, 'Called ->import ok' );

# Check for various failing cases
$VERSION = undef;
my $rv = eval "use only::matching 't::lib::MyTestModule';";
ok( $@, 'Bad call errored' );
ok( $@ =~ /Calling package main does not have a version/,
	"Bad call errored with expected message" );
is( $LOADED, 33, '->import was not called' );

my $counter = 33;
my @evil = ( '', 1, '0.010', '0.01_01', );
foreach my $bad ( @evil ) {
	$VERSION = $bad;
	my $rv = eval "use only::matching 't::lib::MyTestModule';";
	ok( $@, 'Bad call errored' );
	ok( $@ =~ /t::lib::MyTestModule version 0.02 does not match caller main/,
		"Bad call errored with expected message" );
	is( $LOADED, ($counter += 10), '->import was not called' );
}

# Test various bits of evil
@evil = ( {}, \"constant", \*foo::bar, \*foo::bar ); # *foo::bar twice to squash warning
foreach my $bad ( @evil ) {
	$VERSION = $bad;
	SCOPE: {
		local $^W = 0; # To ignore a spurious version warning
		my $rv = eval "use only::matching 't::lib::MyTestModule';";
	}
	ok( $@, 'Bad call errored' );
	ok( $@ =~ /Caller main and module t::lib::MyTestModule version ref type mismatch/,
		"Bad call errored with expected message" );
	is( $LOADED, ($counter += 10), '->import was not called' );
}

1;
