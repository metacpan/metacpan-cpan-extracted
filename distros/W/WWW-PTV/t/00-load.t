#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::PTV' ) || print "Bail out!
";
}

diag( "Testing WWW::PTV $WWW::PTV::VERSION, Perl $], $^X" );
