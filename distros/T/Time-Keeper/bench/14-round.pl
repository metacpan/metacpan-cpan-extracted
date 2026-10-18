#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use DateTime;
my ($t, $dt) = (Time::Keeper->from_epoch(1760000000)->plus(nanoseconds => 123456789), DateTime->from_epoch(epoch => 1760000000));
my $tk = rate(sub { $t->round(to => 'minute') }, 'Time::Keeper');
mark('round(to => minute)', $tk, rate(sub { $dt->clone->truncate(to => 'minute') }, 'DateTime truncate'), 20, 'DateTime');
my $tk15 = rate(sub { $t->round(to => 'minute', increment => 15, mode => 'half_even') }, 'Time::Keeper 15');
mark('round(to => minute, increment => 15)', $tk15, rate(sub { $dt->clone->truncate(to => 'minute') }, 'DateTime truncate'), 20, 'DateTime');
my $tke = rate(sub { $t->end_of(to => 'month') }, 'Time::Keeper end_of');
mark('end_of(to => month)', $tke, rate(sub { $dt->clone->truncate(to => 'month')->add(months => 1)->subtract(nanoseconds => 1) }, 'DateTime'), 20, 'DateTime');
done();
