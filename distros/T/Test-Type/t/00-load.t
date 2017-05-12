#!perl -T

use strict;
use warnings;

use Test::FailWarnings;
use Test::More tests => 1;


BEGIN
{
	use_ok( 'Test::Type' ) || print "Bail out!\n";
}

diag( "Testing Test::Type $Test::Type::VERSION, Perl $], $^X" );
