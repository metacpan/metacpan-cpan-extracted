#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Test::Mojo::Plack' ) || print "Bail out!\n";
}

diag( "Testing Test::Mojo::Plack $Test::Mojo::Plack::VERSION, Perl $], $^X" );
