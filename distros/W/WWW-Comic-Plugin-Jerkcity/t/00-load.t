#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Comic::Plugin::Jerkcity' ) || print "Bail out!
";
}

diag( "Testing WWW::Comic::Plugin::Jerkcity $WWW::Comic::Plugin::Jerkcity::VERSION, Perl $], $^X" );
