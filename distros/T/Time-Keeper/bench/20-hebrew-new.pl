#!perl
use strict; use warnings;
BEGIN { require './bench/common.pl' }
use Time::Keeper;

# A value in the Hebrew calendar against the same value in the Gregorian:
# the calendar's arithmetic runs on every construction and every read, since
# the fields are not cached. The mark is a call within three times the
# Gregorian's. DateTime::Calendar::Hebrew is measured where installed.
sub us { sprintf '%.2f', 1e6 / $_[0] }
my $greg = rate(sub { Time::Keeper->new(year => 2026, month => 10, day => 15) }, 'new, Gregorian');
my $heb  = rate(sub { Time::Keeper->new(year => 5787, month => 2, day => 4, calendar => 'hebrew') }, 'new, Hebrew');
mark_less('new in the Hebrew calendar, a call', us($heb), sprintf('%.2f', 3e6 / $greg), 1, 'thrice Gregorian', 'us');
my $t = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9);
my $h = $t->in_calendar('hebrew');
mark_less('month, a Hebrew value, a call', us(rate(sub { $h->month }, 'month, Hebrew')), sprintf('%.2f', 3e6 / rate(sub { $t->month }, 'month, Gregorian')), 1, 'thrice Gregorian', 'us');
mark_less("format('d MMMM y'), Hebrew, a call", us(rate(sub { $h->format('d MMMM y') }, 'format, Hebrew')), sprintf('%.2f', 3e6 / rate(sub { $t->format('d MMMM y') }, 'format, Gregorian')), 1, 'thrice Gregorian', 'us');
if (eval { require DateTime::Calendar::Hebrew; 1 }) {
    mark('new in the Hebrew calendar', $heb, rate(sub { DateTime::Calendar::Hebrew->new(year => 5787, month => 2, day => 4) }, 'DT::Calendar::Hebrew'), 10, 'DT::C::Hebrew');
}
else {
    print "info DateTime::Calendar::Hebrew is not installed: no mark against it\n";
}
done();
