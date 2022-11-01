use strict;
use warnings;
use v5.010;

# Run like this in my dev dir:
# SMARTROW_USERNAME=xxxx \
# SMARTROW_PASSWORD=yyyy \
# carton exec perl -Ilib examples/total_distance.pl

use WebService::SmartRow;

use Data::Dumper;

my $srv = WebService::SmartRow->new;

my $workouts = $srv->get_workouts;

my $total_distance = 0;
for my $workout (@$workouts) {
    $total_distance += $workout->{distance};
}

say "Total distace across all workouts: $total_distance meters";

