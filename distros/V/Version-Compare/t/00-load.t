#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Version::Compare' ) || print "Bail out!
";
}

diag( "Testing Version::Compare $Version::Compare::VERSION, Perl $], $^X" );
