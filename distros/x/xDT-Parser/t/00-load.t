#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 4;

BEGIN {
    use_ok( 'xDT::Parser' ) || print "Bail out!\n";
    use_ok( 'xDT::Object' ) || print "Bail out!\n";
    use_ok( 'xDT::Record' ) || print "Bail out!\n";
    use_ok( 'xDT::RecordType' ) || print "Bail out!\n";
}

diag( "Testing xDT::Parser $xDT::Parser::VERSION, Perl $], $^X" );
