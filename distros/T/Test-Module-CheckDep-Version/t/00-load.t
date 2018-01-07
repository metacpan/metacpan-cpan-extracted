#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'Test::Module::CheckDep::Version' ) || print "Bail out!\n";
}

diag( "Testing Test::Module::CheckDep::Version $Test::Module::CheckDep::Version::VERSION, Perl $], $^X" );
