use strict;
use warnings;

# NB: You will need to set the SMARTROW_USERNAME and
#     SMARTROW_PASSWORD environment variable before
#     calling the script.

use WebService::SmartRow;

my $workouts = WebService::SmartRow->new->get_workouts();

my %pbs = (
    1000 => { time => 9999 },
    2000 => { time => 9999 },
    4000 => { time => 9999 },
    5000 => { time => 9999 },
    6000 => { time => 9999 },
);

for my $session (@$workouts) {
    next unless exists $pbs{ $session->{distance} };

    if ( $pbs{ $session->{distance} }{time} > $session->{elapsed_seconds} ) {
        $pbs{ $session->{distance} }{time}  = $session->{elapsed_seconds};
        $pbs{ $session->{distance} }{power} = $session->{p_ave};
        $pbs{ $session->{distance} }{split} = $session->{calc_ave_split};
        $pbs{ $session->{distance} }{date} = $session->{created};

    }
}

print "Personal Bests\n";
for my $key ( sort keys %pbs ) {
    print sprintf(
        "%sM:  %.02f minutes  (%s, %d watts, %.02f/500m)\n",
        $key,              $pbs{$key}{time} / 60,
        $pbs{$key}{date},
        $pbs{$key}{power}, $pbs{$key}{split} / 60
    );
}

