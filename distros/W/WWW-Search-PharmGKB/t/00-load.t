#!/usr/bin/env perl

use Test::More tests => 1;

BEGIN {
	use_ok( 'WWW::Search::PharmGKB' );
}

diag( "Testing WWW::Search::PharmGKB $WWW::Search::PharmGKB::VERSION, Perl $], $^X" );
