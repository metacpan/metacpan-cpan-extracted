#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Wappalyzer' ) || print "Bail out!\n";
}

diag( "Testing WWW::Wappalyzer $WWW::Wappalyzer::VERSION, Perl $], $^X" );
