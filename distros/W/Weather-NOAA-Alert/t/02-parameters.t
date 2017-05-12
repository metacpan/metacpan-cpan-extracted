#!perl -T

use strict;
use warnings;

use Test::More tests => 7;

use Weather::NOAA::Alert;
my $g = Weather::NOAA::Alert->new();

$g->zones(['TXC082', 'TXZ097']);
my @zones = $g->zones();
is_deeply(@zones, ['TXC082', 'TXZ097'], 'set and retrieve @zoneArray');

is( $g->atomURLZone(), 'http://alerts.weather.gov/cap/wwaatmget.php?x=', 'retreive default atom URL for Zones');
$g->atomURLZone( 'http://alerts.weather.gov/something/else.php?x=');
is( $g->atomURLZone(), 'http://alerts.weather.gov/something/else.php?x=', 'set and retreive atom URL for Zones');

is( $g->atomURLUS(), 'http://alerts.weather.gov/cap/us.atom', 'retreive default atom URL for US');
$g->atomURLUS( 'http://alerts.weather.gov/something/else.atom');
is( $g->atomURLUS(), 'http://alerts.weather.gov/something/else.atom', 'set and retreive atom URL for US');

is( ref $g->get_events(), 'HASH', 'retrieve events structure');

ok( defined(Weather::NOAA::Alert->VERSION), 'retrieve version');
