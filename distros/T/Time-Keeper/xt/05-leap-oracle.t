#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Leap seconds against DateTime. Author only: DateTime is never a
# prerequisite.
BEGIN {
    eval { require DateTime; 1 } or plan skip_all => 'DateTime is not installed';
}
use Time::Keeper;

# Every day from 1972 to 2026: 23:59:60 is a time here exactly when it is
# one to DateTime.
my (@ours, @theirs);
for my $y (1972 .. 2026) {
    for my $m (1 .. 12) {
        my $last = Time::Keeper::_days_in_month($y, $m);
        for my $d (1 .. $last) {
            push @ours, "$y-$m-$d" if eval { Time::Keeper::_instant_from_civil($y, $m, $d, 23, 59, 60, 0); 1 };
            push @theirs, "$y-$m-$d" if eval {
                DateTime->new(year => $y, month => $m, day => $d, hour => 23, minute => 59,
                              second => 60, time_zone => 'UTC');
            };
        }
    }
}
is(scalar @ours, 27, '27 days from 1972 to 2026 end with 23:59:60 here');
is_deeply(\@ours, \@theirs, "and they are DateTime $DateTime::VERSION\'s 27");

# Differences in SI seconds against DateTime's, between random instants
# and the instants on either side of each leap second, to the nanosecond.
#
# DateTime's own leap-second arithmetic is what subtract_datetime_absolute
# does before it builds a Duration: utc_rd_as_seconds plus the leap seconds
# accumulated before the day, nanoseconds borrowed. That is repeated here and
# the Duration is not built, because DateTime::Duration 1.66 normalises
# with seconds + nanoseconds / 1e9 in floating point and truncates: past
# about 1e7 seconds a nanosecond count near 1e9 rounds the sum up a whole
# second (662774409 s and 999999999 ns come back as 662774410 s).
sub dt_minus_absolute {
    my ($x, $y) = @_;
    my $s = ($x->utc_rd_as_seconds + $x->_accumulated_leap_seconds($x->{utc_rd_days}))
          - ($y->utc_rd_as_seconds + $y->_accumulated_leap_seconds($y->{utc_rd_days}));
    my $n = $x->nanosecond - $y->nanosecond;
    if ($n < 0) { $s--; $n += 1_000_000_000 }
    return ($s, $n);
}
my @ends = Time::Keeper::_leap_ends();
my @points;
for my $e (@ends) {
    push @points, [$e - 1, 0], [$e - 1, 999_999_999], [$e - 1, 1_000_000_000],
                  [$e - 1, 1_999_999_999], [$e, 0];
}
srand(1972);
push @points, [63_072_000 + int(rand(1_800_000_000)), int(rand(1_000_000_000))] for 1 .. 100;

sub dt {
    my ($s, $n) = @_;
    my @c = Time::Keeper::_civil_from_instant($s, $n);
    return DateTime->new(year => $c[0], month => $c[1], day => $c[2], hour => $c[3],
                         minute => $c[4], second => $c[5], nanosecond => $c[6], time_zone => 'UTC');
}
my @dts = map { dt(@$_) } @points;

my ($n, $bad) = (0, 0);
for (1 .. 5000) {
    my ($i, $j) = (int rand @points, int rand @points);
    my ($s, $ns) = Time::Keeper::_minus_absolute(@{ $points[$i] }, @{ $points[$j] });
    my ($ds, $dn) = dt_minus_absolute($dts[$i], $dts[$j]);
    $n++;
    next if $s == $ds && $ns == $dn;
    diag("@{ $points[$i] } - @{ $points[$j] }: here $s $ns, DateTime $ds $dn") if $bad < 5;
    $bad++;
}
is($bad, 0, "$n differences agree with DateTime's to the nanosecond");

my $rbad = 0;
for my $k (0 .. $#points) {
    my @rd = Time::Keeper::_day_numbers(@{ $points[$k] });
    my @drd = $dts[$k]->utc_rd_values;
    $rbad++ unless "@rd[0 .. 2]" eq "@drd";
}
is($rbad, 0, 'and Rata Die values agree on every one, leap seconds included');

done_testing;
