#!perl

use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 7;

BEGIN {
    use_ok( 'WWW::Google::CustomSearch' )          || print "Bail out!\n";
    use_ok( 'WWW::Google::CustomSearch::Params' )  || print "Bail out!\n";
    use_ok( 'WWW::Google::CustomSearch::Item' )    || print "Bail out!\n";
    use_ok( 'WWW::Google::CustomSearch::Page' )    || print "Bail out!\n";
    use_ok( 'WWW::Google::CustomSearch::Request' ) || print "Bail out!\n";
    use_ok( 'WWW::Google::CustomSearch::Result' )  || print "Bail out!\n";
    use_ok( 'WWW::Google::CustomSearch::Params' )  || print "Bail out!\n";
}

diag( "Testing WWW::Google::CustomSearch $WWW::Google::CustomSearch::VERSION, Perl $], $^X" );

done_testing();
