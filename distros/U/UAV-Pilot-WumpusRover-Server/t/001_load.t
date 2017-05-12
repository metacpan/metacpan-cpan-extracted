use Test::More tests => 3;
use v5.14;
use warnings;

use_ok( 'UAV::Pilot::WumpusRover::Server' );
use_ok( 'UAV::Pilot::WumpusRover::Server::Backend' );
use_ok( 'UAV::Pilot::WumpusRover::Server::Backend::RaspberryPiI2C' );
