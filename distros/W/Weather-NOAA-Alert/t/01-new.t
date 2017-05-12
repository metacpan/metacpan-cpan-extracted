#!perl -T

use strict;
use warnings;

use Test::More tests => 6;

use Weather::NOAA::Alert;

my $w = Weather::NOAA::Alert->new();
ok( defined $w, 'new() returns a value' );
ok( $w->isa('Weather::NOAA::Alert'), 'The right class' );

ok ( my $g = Weather::NOAA::Alert->new(['TXC082', 'TXZ097']), 'new(@zoneArray)');
ok( defined $g );
ok( $g->isa('Weather::NOAA::Alert') );
my @zones = $g->zones();
is_deeply(@zones, ['TXC082', 'TXZ097'], 'retrieve @zoneArray');
