#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Moviepilot' );
}

diag( "Testing WWW::Moviepilot $WWW::Moviepilot::VERSION, Perl $], $^X" );
