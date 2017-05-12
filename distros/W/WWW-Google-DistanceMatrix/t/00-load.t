#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;

BEGIN {
    use_ok( 'WWW::Google::DistanceMatrix' )         || print "Bail out!\n";
    use_ok( 'WWW::Google::DistanceMatrix::Params' ) || print "Bail out!\n";
    use_ok( 'WWW::Google::DistanceMatrix::Result' ) || print "Bail out!\n";
}

diag( "Testing WWW::Google::DistanceMatrix $WWW::Google::DistanceMatrix::VERSION, Perl $], $^X" );
