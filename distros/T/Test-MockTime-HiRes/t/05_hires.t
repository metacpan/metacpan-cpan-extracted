use strict;
use warnings;

use Test::More tests => 201;
use Test::MockTime::HiRes qw/set_relative_time set_absolute_time/;

my @warnings;
$SIG{__WARN__} = sub {push @warnings, @_};
my $base_time = time;

for my $step (1 .. 100) {
    set_relative_time($step/100);
    is time, int(Time::HiRes::time), "time() equal to Time::HiRes::time() in set_relative_time to 0.$step sec";
    set_absolute_time($base_time + $step/100);
    is time, int(Time::HiRes::time), "time() equal to Time::HiRes::time() in set_absolute_time to $base_time + 0.$step sec";
}

is 0+@warnings, 0, 'no warnings';

done_testing;
