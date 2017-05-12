#!perl -T

use strict;
use warnings;

use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 1;


BEGIN
{
	use_ok( 'Test::Dist::VersionSync' ) || print "Bail out!\n";
}

diag( "Testing Test::Dist::VersionSync $Test::Dist::VersionSync::VERSION, Perl $], $^X" );
