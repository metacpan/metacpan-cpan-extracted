#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::LongURL' ) || print "Bail out!
";
}

diag( "Testing WWW::LongURL $WWW::LongURL::VERSION, Perl $], $^X" );
