#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Comic::Plugin::DinosaurComics' ) || print "Bail out!
";
}

diag( "Testing WWW::Comic::Plugin::DinosaurComics $WWW::Comic::Plugin::DinosaurComics::VERSION, Perl $], $^X" );
