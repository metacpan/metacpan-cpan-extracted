#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use DateTime;
my ($a, $b) = (Time::Keeper->from_epoch(1760000000), Time::Keeper->from_epoch(1790000000)->plus(nanoseconds => 5));
my ($da, $db) = (DateTime->from_epoch(epoch => 1760000000), DateTime->from_epoch(epoch => 1790000000));
my $tk = rate(sub { $a->until($b, largest => 'hours') }, 'Time::Keeper');
mark('until(largest => hours)', $tk, rate(sub { $db->subtract_datetime_absolute($da) }, 'DateTime'), 20, 'DateTime');
my $tkd = rate(sub { $a->until($b, largest => 'days', smallest => 'hours') }, 'Time::Keeper days');
mark('until(largest => days, smallest => hours)', $tkd, rate(sub { $db->subtract_datetime($da) }, 'DateTime'), 20, 'DateTime');
my $tkn = rate(sub { $a->next(day_of_week => 1) }, 'Time::Keeper next');
mark('next(day_of_week => 1)', $tkn, rate(sub { my $d = $da->clone; $d->add(days => 1) until $d->day_of_week == 1 }, 'DateTime'), 20, 'DateTime');
done();
