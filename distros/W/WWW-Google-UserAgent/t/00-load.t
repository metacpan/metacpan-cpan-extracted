#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 3;

BEGIN {
    use_ok( 'WWW::Google::UserAgent'            ) || print "Bail out!\n";
    use_ok( 'WWW::Google::UserAgent::DataTypes' ) || print "Bail out!\n";
    use_ok( 'WWW::Google::UserAgent::Exception' ) || print "Bail out!\n";
}

diag( "Testing WWW::Google::UserAgent $WWW::Google::UserAgent::VERSION, Perl $], $^X" );
