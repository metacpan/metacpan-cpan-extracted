#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More tests => 6;

BEGIN {
    use_ok( 'WWW::Google::PageSpeedOnline'               ) || print "Bail out!\n";
    use_ok( 'WWW::Google::PageSpeedOnline::Params'       ) || print "Bail out!\n";
    use_ok( 'WWW::Google::PageSpeedOnline::Stats'        ) || print "Bail out!\n";
    use_ok( 'WWW::Google::PageSpeedOnline::Advise'       ) || print "Bail out!\n";
    use_ok( 'WWW::Google::PageSpeedOnline::Result'       ) || print "Bail out!\n";
    use_ok( 'WWW::Google::PageSpeedOnline::Result::Rule' ) || print "Bail out!\n";
}

diag( "Testing WWW::Google::PageSpeedOnline $WWW::Google::PageSpeedOnline::VERSION, Perl $], $^X" );
