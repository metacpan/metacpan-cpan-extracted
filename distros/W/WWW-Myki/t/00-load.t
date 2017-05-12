#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Myki' ) || print "Bail out!
";
}

diag( "Testing WWW::Myki $WWW::Myki::VERSION, Perl $], $^X" );
