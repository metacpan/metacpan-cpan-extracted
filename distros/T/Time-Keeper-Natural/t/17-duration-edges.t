#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

# Durations at the edges the C reader draws: a chain split where numbers
# start, a joiner word stuck to a number, the digital clock's digit counts
# and padding, and the text's own spaces.
sub d {
    my ($loc, $text) = @_;
    my $v = eval { Time::Keeper::Natural->new(locale => $loc)->parse_duration($text) };
    return "$v" if $v;
    (my $e = $@) =~ s/ at \S+ line \d+.*//s;
    return "died: $e";
}

is(d('en', '1h30m'), 'PT1H30M', 'en: parts with no space, split where the number starts');
is(d('en', '1 hour and30 minutes'), 'PT1H30M', 'en: a joiner word against the next number');
is(d('ja', '1時間30分'), 'PT1H30M', 'ja: a spaceless chain');
is(d('en', ' 1:05:09 '), 'PT1H5M9S', 'en: a digital clock with spaces round it');
is(d('en', '1:05:09.5'), 'PT1H5M9.5S', 'en: a fraction of a second, padded to nanoseconds');
like(d('en', '1:05:09.1234567890'), qr/^died: .*cannot read '1:05:09\.1234567890'/, 'en: ten digits of a fraction are not a clock');
like(d('en', '1:123'), qr/^died: .*cannot read '1:123'/, 'en: three digits of minutes are not a clock');
like(d('en', '2 hours and 3 hours'), qr/hour is given twice/, 'en: a unit twice');
like(d('en', '0:00:00'), qr/^died: .*cannot read '0:00:00'/, 'en: a clock of nothing is no duration, as 0.01 read it');
like(d('ta-SG', '0 ம.'), qr/^died: /, 'ta-SG: nor nought hours');

done_testing;
