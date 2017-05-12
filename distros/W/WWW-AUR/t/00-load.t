#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::AUR' ) || print "Bail out!
";
}

diag( "Testing WWW::AUR $WWW::AUR::VERSION, Perl $], $^X" );
