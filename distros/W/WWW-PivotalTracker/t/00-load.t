#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::PivotalTracker' );
}

note( "Testing WWW::PivotalTracker $WWW::PivotalTracker::VERSION, Perl $], $^X\n" );
