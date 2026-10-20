#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper; use Time::Keeper::Business;
my $R = 'Time::Keeper::Business::Rule';
my $mk = sub { $R->fixed(calendar => 'islamic-umalqura', month_code => 'M10', day => 1, name => 'Eid al-Fitr') };
my ($r, $y) = ($mk->(), 1100);
mark_rate('a new year of an Umm al-Qura rule', rate(sub { if (++$y > 2900) { $y = 1100; $r = $mk->() } $r->holidays(year => $y) }, 'calendar rule'), 5e4);
done();
