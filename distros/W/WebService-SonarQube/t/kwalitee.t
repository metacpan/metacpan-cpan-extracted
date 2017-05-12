#!/usr/bin/perl

use strict;
use warnings;

if ( not $ENV{TEST_AUTHOR} ) {
	require Test::More;
	Test::More->import;
	my $msg = 'Author test.  Set TEST_AUTHOR environment variable to a true value to run.';
	plan( skip_all => $msg );
}

eval { require Test::Kwalitee; Test::Kwalitee->import() };

if ($@) {
    require Test::More;
    Test::More->import;
    plan( skip_all => 'Test::Kwalitee not installed; skipping' );
}
