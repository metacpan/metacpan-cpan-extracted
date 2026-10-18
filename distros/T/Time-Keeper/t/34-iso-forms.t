#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';
sub t { $K->new(@_) }
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}

my $t = t(year => 2026, month => 10, day => 15, hour => 9, minute => 5, second => 7);
is($t->iso8601(form => 'extended') . '', '2026-10-15T09:05:07Z', 'extended is the default');
is($t->iso8601(form => 'basic'), '20261015T090507Z', 'basic: no separators');
is($t->iso8601(form => 'week'), '2026-W42-4T09:05:07Z', 'the week date');
is($t->iso8601(form => 'ordinal'), '2026-288T09:05:07Z', 'the ordinal date');
for my $form (qw(extended basic week ordinal)) {
    is($K->parse($t->iso8601(form => $form)) . '', "$t", "parse reads the $form form back");
}

# With a fraction, an offset, and precision.
{
    my $f = t(year => 2026, month => 10, day => 15, hour => 9, minute => 5, second => 7, nanosecond => 123000000,
              zone => 'Asia/Tokyo');
    is($f->iso8601(form => 'basic'), '20261015T090507.123+0900', 'basic: the offset has no colon either');
    is($f->iso8601(form => 'week'), '2026-W42-4T09:05:07.123+09:00', 'week with an offset');
    is($f->iso8601(form => 'ordinal', precision => 6), '2026-288T09:05:07.123000+09:00', 'ordinal with precision');
    is($f->iso8601(precision => 0, form => 'basic'), '20261015T090507+0900', 'the options in either order');
    is($K->parse($f->iso8601(form => 'basic')) . '', "$f", 'basic with an offset reads back');
    is($K->parse($f->iso8601(form => 'week')) . '', "$f", 'week with an offset reads back');
    is(t(year => 2026, month => 10, day => 15, zone => 'floating')->iso8601(form => 'basic'), '20261015T000000', 'floating has no offset');
    is(t(year => 2026, month => 10, day => 15, zone => 'Europe/London')->iso8601(form => 'basic'), '20261015T000000+0100', 'a zone at an hour');
    is(t(year => 2026, month => 10, day => 15, zone => 'Asia/Kolkata')->iso8601(form => 'basic'), '20261015T000000+0530', 'and at a half hour');
}

# The week date at the edges of a year.
{
    is(t(year => 2026, month => 1, day => 1)->iso8601(form => 'week'), '2026-W01-4T00:00:00Z', '1 January 2026 is a Thursday, so it is in week 1 of its own year');
    is(t(year => 2024, month => 12, day => 30)->iso8601(form => 'week'), '2025-W01-1T00:00:00Z', '30 December 2024 is the Monday of 2025-W01');
    is(t(year => 2027, month => 1, day => 1)->iso8601(form => 'week'), '2026-W53-5T00:00:00Z', '1 January 2027 is in 2026-W53');
    is(t(year => 2026, month => 12, day => 31)->iso8601(form => 'ordinal'), '2026-365T00:00:00Z', 'the last day of a common year');
    is(t(year => 2028, month => 12, day => 31)->iso8601(form => 'ordinal'), '2028-366T00:00:00Z', 'and of a leap year');
}

# Expanded years.
{
    my $far = t(year => 12026, month => 10, day => 15);
    is($far->iso8601(form => 'basic'), '+0120261015T000000Z', 'basic with an expanded year');
    is($far->iso8601(form => 'ordinal'), '+012026-288T00:00:00Z', 'ordinal with an expanded year');
    dies_like(sub { $K->parse($far->iso8601(form => 'basic')) }, qr/expanded year has a sign and 4 to 9 digits/,
              'which no parser can read back: ISO 8601 leaves the number of year digits in the basic form to agreement');
    is($K->parse($far->iso8601(form => 'ordinal')) . '', "$far", 'the ordinal form with an expanded year reads back');
    is($K->parse($far->iso8601(form => 'week')) . '', "$far", 'and so does the week form');
    is(t(year => -1, month => 3, day => 1)->iso8601(form => 'basic'), '-0000010301T000000Z', 'a year before 0');
}

# Only iso8601 takes a form.
{
    dies_like(sub { $t->iso8601(form => 'roman') }, qr/form is extended, basic, week or ordinal, not 'roman'/, 'a form it does not know');
    dies_like(sub { $t->iso8601(shape => 'basic') }, qr/the options are precision => 0 to 9 and form => .*, not 'shape'/, 'an option it does not know');
    dies_like(sub { $t->iso8601('basic') }, qr/the options are precision/, 'pairs');
    dies_like(sub { $t->rfc3339(form => 'basic') }, qr/rfc3339: the options are precision => 0 to 9, not 'form'/, 'rfc3339 takes no form');
    dies_like(sub { $t->rfc9557(form => 'basic') }, qr/rfc9557: the options are precision => 0 to 9, not 'form'/, 'nor rfc9557');
    is($t->rfc3339(precision => 3), '2026-10-15T09:05:07.000Z', 'rfc3339 still takes precision');
    is("$t", '2026-10-15T09:05:07Z', 'and a value in a string is still the extended form');
}

done_testing;
