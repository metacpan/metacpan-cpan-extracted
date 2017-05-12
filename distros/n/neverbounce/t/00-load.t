#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 8;

BEGIN {
    use_ok( 'neverbounce' ) || print "Bail out!\n";
    use_ok( 'Data::Dumper' ) || print "Bail out!\n";
    use_ok( 'HTTP::Request::Common' ) || print "Bail out!\n";
    use_ok( 'JSON' ) || print "Bail out!\n";
    use_ok( 'LWP::UserAgent' ) || print "Bail out!\n";
    use_ok( 'LWP::Protocol::https' ) || print "Bail out!\n";
    use_ok( 'Test::Manifest' ) || print "Bail out!\n";
    use_ok( 'Test::More' ) || print "Bail out!\n";
}

diag( "Testing neverbounce $neverbounce::VERSION, Perl $], $^X" );
