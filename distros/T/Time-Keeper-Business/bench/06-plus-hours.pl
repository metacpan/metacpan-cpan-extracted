#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Business;
my $b = Time::Keeper::Business->new(holidays => Time::Keeper::Business::Rule->uk, weekend => 'en-GB', zone => 'Europe/London',
                                    hours => { default => ['09:00-12:30', '13:30-17:30'], fri => ['09:00-13:00'] });
my $t = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 11, zone => 'Europe/London');
$b->plus_business_hours($t, hours => 4);
my $mine = rate(sub { $b->plus_business_hours($t, hours => 4) }, 'plus_business_hours');
mark_rate('plus_business_hours($t, hours => 4)', $mine, 1e6);
printf "info plus_business_hours(hours => 40): %s\n", fmt_rate(rate(sub { $b->plus_business_hours($t, hours => 40) }, '40 hours'));
if (eval { require Business::Hours; 1 }) {
    my $bh = Business::Hours->new;
    $bh->business_hours(map { $_ => { Name => $_, Start => ($_ >= 1 && $_ <= 5 ? '9:00' : undef), End => ($_ >= 1 && $_ <= 5 ? '17:00' : undef) } } 0 .. 6);
    my $e = $t->epoch;
    mark('plus_business_hours', $mine, rate(sub { $bh->add_seconds($e, 4 * 3600) }, 'Business::Hours'), 20, 'Business::Hours add_seconds');
}
else { absent('Business::Hours', 'add_seconds') }
done();
