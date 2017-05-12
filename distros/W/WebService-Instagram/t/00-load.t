#!perl -T

use Test::More tests => 2;

BEGIN {
    use_ok( 'WebService::Instagram' ) || print "Bail out!\n";
}

diag( "Testing WebService::Instagram $WebService::Instagram::VERSION, Perl $], $^X" );

my $instagram = WebService::Instagram->new;
ok( $instagram, 'creates new object' );
