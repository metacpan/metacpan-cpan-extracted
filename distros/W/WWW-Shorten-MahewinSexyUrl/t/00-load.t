#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Shorten::MahewinSexyUrl' ) || print "Bail out!\n";
}

diag( "Testing WWW::Shorten::MahewinSexyUrl $WWW::Shorten::MahewinSexyUrl::VERSION, Perl $], $^X" );
