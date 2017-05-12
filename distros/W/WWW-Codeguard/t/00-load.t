use strict;
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'WWW::Codeguard' ) || print "Bail out!\n";
}

diag( "Testing WWW::Codeguard $WWW::Codeguard::VERSION, Perl $], $^X" );
