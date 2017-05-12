#!/usr/bin/perl

use strict;
use warnings;

#use Test::More 'no_plan';
use Test::More tests => 3;

use FindBin qw($Bin);
use lib "$Bin/lib";

BEGIN {
    use_ok ( 'Universe::ObservableUniverse::Filament::SuperCluster::Cluster::Group::Galaxy::Arm::Bubble::InterstellarCloud::SolarSystem::Earth' ) or exit;
}

exit main();

sub main {
    ok(
        Universe::ObservableUniverse::Filament::SuperCluster::Cluster::Group::Galaxy::Arm::Bubble::InterstellarCloud::SolarSystem::Earth->info,
        'Get Earth information'
    );
    
    is(
        Universe::ObservableUniverse::Filament::SuperCluster::Cluster::Group::Galaxy::Arm::Bubble::InterstellarCloud::SolarSystem::Earth->ultimate_answer,
        42,
        'Check ultimate answer to the ultimate question'
    );
    
    return 0;
}
