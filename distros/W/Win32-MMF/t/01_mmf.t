use strict;
use warnings;
use Test::More tests => 6;

BEGIN {
    use_ok( 'Win32::MMF' );
}

my $ns = new Win32::MMF;
isa_ok( $ns, 'Win32::MMF', 'Constructor OK' );

ok( $ns->setvar('simple', 'Hello world'), 'Setvar OK' ) or die "Can't setvar";

is($ns->findvar('simple'), 1, 'Findvar OK');

is( $ns->getvar('simple'), 'Hello world', 'Getvar OK' );

$ns->deletevar('simple');
is( $ns->getvar('simple'), undef, 'Deletevar Ok' );

