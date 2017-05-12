#!perl -T
use 5.008;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 3;

BEGIN {
    use_ok( 'XML::OPDS' ) || print "Bail out!\n";
    use_ok( 'XML::OPDS::Navigation' ) || print "Bail out!\n";
    use_ok( 'XML::OPDS::Acquisition' ) || print "Bail out!\n";
}

diag( "Testing XML::OPDS $XML::OPDS::VERSION, Perl $], $^X" );
