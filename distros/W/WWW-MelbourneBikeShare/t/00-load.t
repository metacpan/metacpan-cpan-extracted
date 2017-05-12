#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WWW::MelbourneBikeShare' ) || print "Bail out!\n";
}

diag( "Testing WWW::MelbourneBikeShare $WWW::MelbourneBikeShare::VERSION, Perl $], $^X" );
