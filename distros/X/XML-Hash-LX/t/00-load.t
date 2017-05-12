#!/usr/bin/env perl -w

use strict;
use Test::More;
use lib::abs '../lib';
BEGIN {
	my $w = 0;
	eval {require Test::NoWarnings;Test::NoWarnings->import; 1} and $w = 1;
	plan tests => 2+$w;
	use_ok( 'XML::Hash::LX' );
	use_ok( 'XML::Hash::LX', 'xml2hash', 'hash2xml' );
};
diag( "Testing XML::Hash::LX $XML::Hash::LX::VERSION, Perl $], $^X" );
