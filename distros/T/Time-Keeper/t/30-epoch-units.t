#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Config;

use Time::Keeper;

my $K = 'Time::Keeper';
sub t { $K->new(@_) }
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}
my $iv64 = $Config{ivsize} >= 8;

# A value today.
{
    my $t = t(year => 2026, month => 10, day => 15, hour => 9, minute => 41, second => 17, nanosecond => 123456789);
    my $e = $t->epoch;
    is($t->epoch_millis, "${e}123", 'milliseconds');
    is($t->epoch_micros, "${e}123456", 'microseconds');
    is($t->epoch_nanos, "${e}123456789", 'nanoseconds');
    is($K->from_epoch_millis($t->epoch_millis) . '', '2026-10-15T09:41:17.123Z', 'and back from the milliseconds, to the millisecond');
    is($K->from_epoch_micros($t->epoch_micros) . '', '2026-10-15T09:41:17.123456Z', 'from the microseconds');
    is($K->from_epoch_nanos($t->epoch_nanos) . '', "$t", 'from the nanoseconds, exactly');
    is($K->from_epoch_nanos("${e}123456789") . '', "$t", 'a string of digits');
    is($K->from_epoch_millis("${e}123") . '', '2026-10-15T09:41:17.123Z', 'for milliseconds too');
    is($K->from_epoch_millis($t->epoch_millis, zone => 'Asia/Tokyo')->zone_name, 'Asia/Tokyo', 'in a zone');
    is($K->from_epoch_millis($t->epoch_millis, zone => 'Asia/Tokyo') . '', '2026-10-15T18:41:17.123+09:00', 'the same instant there');
    is($K->from_epoch_micros($t->epoch_micros, locale => 'fr')->locale, 'fr', 'in a locale');
    is($t->with(nanosecond => 999999999)->epoch_millis, "${e}999", 'the fraction below the unit is dropped');
    is($t->with(nanosecond => 0)->epoch_nanos, "${e}000000000", 'and zero pads');
    SKIP: {
        skip 'a 64-bit perl holds nanoseconds as an integer', 2 unless $iv64;
        ok(!ref($t->epoch_nanos) && $t->epoch_nanos == $e * 1e9 + 123456789, 'the nanoseconds are a plain integer');
        is($t->epoch_millis + 1, $e * 1000 + 124, 'and arithmetic works on the milliseconds');
    }
}

# Around zero.
{
    is($K->from_epoch_millis(0) . '', '1970-01-01T00:00:00Z', 'zero');
    is($K->from_epoch_millis(1) . '', '1970-01-01T00:00:00.001Z', 'one millisecond');
    is($K->from_epoch_millis(-1) . '', '1969-12-31T23:59:59.999Z', 'minus one millisecond counts back');
    is($K->from_epoch_micros(-1) . '', '1969-12-31T23:59:59.999999Z', 'minus one microsecond');
    is($K->from_epoch_nanos(-1) . '', '1969-12-31T23:59:59.999999999Z', 'minus one nanosecond');
    is($K->from_epoch_millis(-1)->epoch_millis, -1, 'and back');
    is($K->from_epoch_nanos(-1)->epoch_nanos, -1, 'in nanoseconds too');
    is($K->from_epoch_nanos(-1)->epoch_millis, -1, 'a nanosecond before the epoch is in millisecond -1');
    is($K->from_epoch_nanos(-1)->epoch, -1, 'and in second -1, as epoch floors');
    is($K->from_epoch_millis('-1500') . '', '1969-12-31T23:59:58.500Z', 'a negative string');
    is($K->from_epoch_millis(-1500)->epoch_millis, -1500, 'round trip');
    is($K->from_epoch_millis(-1000)->epoch_millis, -1000, 'a whole negative second');
    is($K->from_epoch_millis(-1000) . '', '1969-12-31T23:59:59Z', 'is one');
}

# Leap seconds.
{
    my $leap = t(year => 2016, month => 12, day => 31, hour => 23, minute => 59, second => 60, nanosecond => 500000000);
    is($leap->epoch, 1483228800, 'the leap second has the epoch of the midnight after');
    is($leap->epoch_millis, '1483228800500', 'and so do its milliseconds, with the fraction');
    is($leap->epoch_nanos, '1483228800500000000', 'and nanoseconds');
    is($K->from_epoch_millis(1483228800500) . '', '2017-01-01T00:00:00.500Z', 'which name the moment after midnight: the epoch cannot name a leap second');
}

# The ends of int64 in nanoseconds.
{
    my $last = $K->from_epoch_nanos('9223372036854775807');
    is("$last", '2262-04-11T23:47:16.854775807Z', 'the last nanosecond an int64 holds');
    is($last->epoch_nanos, '9223372036854775807', 'as a number or digits');
    SKIP: {
        skip 'a 64-bit perl', 1 unless $iv64;
        ok(!ref($last->epoch_nanos) && $last->epoch_nanos == 9223372036854775807, 'an integer on a 64-bit perl');
    }
    my $over = $last->plus(nanoseconds => 1);
    is($over->epoch_nanos, '9223372036854775808', 'one more is a string of digits');
    is($K->from_epoch_nanos('9223372036854775808') . '', "$over", 'which reads back');
    my $first = $K->from_epoch_nanos('-9223372036854775808');
    is("$first", '1677-09-21T00:12:43.145224192Z', 'the first nanosecond an int64 holds');
    is($first->epoch_nanos, '-9223372036854775808', 'back');
    my $under = $first->minus(nanoseconds => 1);
    is($under->epoch_nanos, '-9223372036854775809', 'one less is a string');
    is($K->from_epoch_nanos('-9223372036854775809') . '', "$under", 'which reads back');
    is($K->from_epoch_nanos('-9223372036854775809000')->epoch_nanos, '-9223372036854775809000', 'and a much longer one');
}

# The ends of the range.
{
    my ($max, $min) = ($K->max, $K->min);
    like($max->epoch_nanos, qr/^\d{25,}$/, 'max in nanoseconds is a long string of digits');
    like($max->epoch_millis, qr/^\d{19,}$/, 'and in milliseconds, past int64, so too');
    like($min->epoch_nanos, qr/^-\d{25,}$/, 'min likewise, negative');
    is($K->from_epoch_nanos($max->epoch_nanos) . '', "$max", 'max round-trips through nanoseconds');
    is($K->from_epoch_micros($max->epoch_micros) . '', $max->truncate(to => 'microsecond') . '', 'through microseconds, to the microsecond');
    is($K->from_epoch_millis($max->epoch_millis) . '', $max->truncate(to => 'millisecond') . '', 'and milliseconds, to the millisecond');
    is($K->from_epoch_nanos($min->epoch_nanos) . '', "$min", 'min round-trips');
    is($K->from_epoch_millis($min->epoch_millis) . '', "$min", 'in milliseconds too');
    is($K->from_epoch_nanos($min->plus(nanoseconds => 1)->epoch_nanos) . '', $min->plus(nanoseconds => 1) . '', 'a nanosecond after min round-trips');
    dies_like(sub { $K->from_epoch_nanos($max->epoch_nanos . '0') }, qr/out of range/, 'past the range');
    dies_like(sub { $K->from_epoch_millis('99999999999999999999999') }, qr/out of range/, 'in milliseconds too');
}

# Bad arguments.
{
    dies_like(sub { $K->from_epoch_millis(1.5) }, qr/from_epoch_millis takes a whole number; from_epoch takes a fraction/, 'a fraction');
    dies_like(sub { $K->from_epoch_nanos('1.5') }, qr/'1\.5' is not a whole number/, 'as a string');
    dies_like(sub { $K->from_epoch_millis('abc') }, qr/'abc' is not a whole number/, 'letters');
    dies_like(sub { $K->from_epoch_millis('') }, qr/is not a whole number/, 'nothing');
    dies_like(sub { $K->from_epoch_millis(undef) }, qr/a number is needed|not a whole number/, 'undef');
    dies_like(sub { $K->from_epoch_millis([]) }, qr/a number is needed/, 'a reference');
    dies_like(sub { $K->from_epoch_millis(1, gap => 'forward') }, qr/unknown argument 'gap'/, 'only zone and locale');
    dies_like(sub { $K->from_epoch_millis(1, zone => 'Mars/Olympus') }, qr/Mars\/Olympus/, 'a zone it does not know');
}

done_testing;
