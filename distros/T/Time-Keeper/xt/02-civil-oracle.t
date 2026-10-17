#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# DateTime as the oracle for the civil core. Author only: DateTime is never
# a prerequisite.
BEGIN {
    eval { require DateTime; 1 } or plan skip_all => 'DateTime is not installed';
}

use Time::Keeper;

srand(15102026);
my %bad;
my $n = 0;
for (1 .. 5000) {
    my $s = int(rand(2 * 300_000_000_000)) - 300_000_000_000;
    my $ns = int(rand(1_000_000_000));
    my $dt = DateTime->from_epoch(epoch => $s, time_zone => 'UTC')->set_nanosecond($ns);
    my ($y, $m, $d, $h, $mi, $se, $nsec, $dow, $doy) = Time::Keeper::_civil_from_instant($s, $ns);
    my ($wy, $w, undef, undef, $q, $doq) = Time::Keeper::_week_info($y, $m, $d);
    my ($rdd, $rds, $rdn, $jdi, $jdf, $mjdi, $mjdf) = Time::Keeper::_day_numbers($s, $ns);
    my ($drd, $drs, $drn) = $dt->utc_rd_values;
    $n++;

    my %check = (
        date     => ["$y-$m-$d $h:$mi:$se.$nsec", join('', $dt->year, '-', $dt->month, '-', $dt->day, ' ', $dt->hour, ':', $dt->minute, ':', $dt->second, '.', $dt->nanosecond)],
        dow      => [$dow, $dt->day_of_week],
        doy      => [$doy, $dt->day_of_year],
        quarter  => ["$q $doq", join(' ', $dt->quarter, $dt->day_of_quarter)],
        week     => ["$wy $w", join(' ', $dt->week)],
        rd       => ["$rdd $rds $rdn", "$drd $drs $drn"],
    );
    for my $k (sort keys %check) {
        next if $check{$k}[0] eq $check{$k}[1];
        diag("$s.$ns $k: got $check{$k}[0], DateTime $check{$k}[1]") if ($bad{$k} || 0) < 3;
        $bad{$k}++;
    }
    my $jd_diff = abs(($jdi - $dt->jd) + $jdf);
    my $mjd_diff = abs(($mjdi - $dt->mjd) + $mjdf);
    $bad{jd}++  if $jd_diff  > 1e-6;
    $bad{mjd}++ if $mjd_diff > 1e-6;
}

is($bad{$_} || 0, 0, "$_ agrees with DateTime $DateTime::VERSION on $n random instants over 19,000 years")
    for qw(date dow doy quarter week rd jd mjd);

done_testing;
