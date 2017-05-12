#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Shorten::ShadyURL' ) || print "Bail out!
";
}

diag( "Testing WWW::Shorten::ShadyURL $WWW::Shorten::ShadyURL::VERSION, Perl $], $^X" );
