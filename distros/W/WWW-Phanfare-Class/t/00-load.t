#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'WWW::Phanfare::Class' ) || print "Bail out!\n";
}

diag( "Testing WWW::Phanfare::Class $WWW::Phanfare::Class::VERSION, Perl $], $^X" );
