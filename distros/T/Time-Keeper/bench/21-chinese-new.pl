#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper;

# A value in the Chinese calendar against the Gregorian: the calendar is read
# from a table of what ICU computes, so a construction or a read is a binary
# search, not astronomy. The mark is a call within three times the
# Gregorian's. DateTime::Calendar::Chinese is measured where installed.
sub us { sprintf '%.2f', 1e6 / $_[0] }
my $greg = rate(sub { Time::Keeper->new(year => 2026, month => 10, day => 15) }, 'new, Gregorian');
my $chi  = rate(sub { Time::Keeper->new(year => 2026, month => 9, day => 6, calendar => 'chinese') }, 'new, Chinese');
mark_less('new in the Chinese calendar, a call', us($chi), sprintf('%.2f', 3e6 / $greg), 1, 'thrice Gregorian', 'us');
my $t = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9);
my $c = $t->in_calendar('chinese');
mark_less('month, a Chinese value, a call', us(rate(sub { $c->month }, 'month, Chinese')), sprintf('%.2f', 3e6 / rate(sub { $t->month }, 'month, Gregorian')), 1, 'thrice Gregorian', 'us');
mark_less("format('U r MMMM d'), Chinese, a call", us(rate(sub { $c->format('U r MMMM d') }, 'format, Chinese')), sprintf('%.2f', 3e6 / rate(sub { $t->format('G y MMMM d') }, 'format, Gregorian')), 1, 'thrice Gregorian', 'us');
if (eval { require DateTime::Calendar::Chinese; 1 }) {
    mark('new in the Chinese calendar', $chi, rate(sub { DateTime::Calendar::Chinese->new(cycle => 78, cycle_year => 43, month => 9, day => 6) }, 'DT::Calendar::Chinese'), 10, 'DT::C::Chinese');
}
else {
    print "info DateTime::Calendar::Chinese is not installed: no mark against it\n";
}
done();
