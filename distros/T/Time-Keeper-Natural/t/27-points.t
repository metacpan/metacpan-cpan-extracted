#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

# Relative to a point: a duration before or after it, a day and a part of
# it, the weekend. The clock is Thursday 15 October 2026, 09:00 in London;
# the clocks go back on Sunday 25 October.
my $N = 'Time::Keeper::Natural';
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
sub m_ {
    my ($loc, $text) = @_;
    my $m = $N->new(locale => $loc, zone => 'Europe/London')->match($text);
    return $m ? join(' ', $m->value, $m->precision, join(',', $m->assumed)) : 'undef';
}
sub p {
    my ($loc, $text) = @_;
    my $v = eval { $N->new(locale => $loc, zone => 'Europe/London')->parse($text) };
    return $v ? "$v" : "died: $@";
}

# Before and after.
is(m_('en', '3 days after tomorrow'), '2026-10-19T00:00:00+01:00 day time,zone', '3 days after tomorrow');
is(p('en-GB', '2 weeks before 15 October'), '2026-10-01T00:00:00+01:00', '2 weeks before 15 October');
is(p('en', 'the day after the 20th'), '2026-10-21T00:00:00+01:00', 'the day after the 20th');
is(p('en', 'the day after tomorrow'), '2026-10-17T00:00:00+01:00', 'the day after tomorrow, which English\'s CLDR has no word for');
is(p('en', 'the day before yesterday'), '2026-10-13T00:00:00+01:00', 'the day before yesterday');
is(m_('en', '2 hours after tomorrow at 3 pm'), '2026-10-16T17:00:00+01:00 minute zone', 'hours after a time');
is(p('en', 'a week after next Tuesday'), '2026-10-27T00:00:00+00:00', 'a week after next Tuesday');
is(p('en', '1.5 days after tomorrow'), '2026-10-17T12:00:00+01:00', 'a fraction of a day after');
is(p('en-GB', '3 days after 23 October'), '2026-10-26T00:00:00+00:00', 'across the clock change: three calendar days');
is(p('en-GB', '24 hours after 24 October 2026 12:00'), '2026-10-25T11:00:00+00:00', '  and 24 hours, which the change shortens on the clock');
like(p('en', 'the day after'), qr/cannot read 'the day after'/, 'the day after alone has no point');
like(p('en', '3 days after'), qr/cannot read '3 days after'/, 'nor 3 days after');

# A day and a part of it: the part's start by the locale's rules.
is(m_('en', 'tomorrow evening'), '2026-10-16T18:00:00+01:00 hour period start,zone', 'tomorrow evening');
is(p('en', 'tomorrow in the evening'), '2026-10-16T18:00:00+01:00', '  the format name');
is(p('en', 'tomorrow night'), '2026-10-16T21:00:00+01:00', 'tomorrow night');
is(p('en', 'tomorrow morning'), '2026-10-16T00:00:00+01:00', 'tomorrow morning: English\'s morning begins at midnight');
is(p('en', 'next Tuesday afternoon'), '2026-10-20T12:00:00+01:00', 'next Tuesday afternoon');
is(p('fr', 'demain matin'), '2026-10-16T04:00:00+01:00', 'fr demain matin: the longer of night and morning, both "matin"');
is(p('fr', 'demain soir'), '2026-10-16T18:00:00+01:00', 'fr demain soir');
is(p('de', 'morgen Abend'), '2026-10-16T18:00:00+01:00', 'de morgen Abend');
is(p('ja', '明日 夜'), '2026-10-16T19:00:00+01:00', 'ja 明日 夜');

# The weekend: the one under way, else the coming one; next and last a week
# either side.
is(m_('en-GB', 'this weekend'), '2026-10-17T00:00:00+01:00 day period start,zone', 'en-GB this weekend: Saturday');
is(p('en-GB', 'next weekend'), '2026-10-24T00:00:00+01:00', 'next weekend');
is(p('en-GB', 'last weekend'), '2026-10-10T00:00:00+01:00', 'last weekend');
is(p('en-US', 'this weekend'), '2026-10-17T00:00:00+01:00', 'en-US, whose week starts on Sunday');
is(p('en-IL', 'this weekend'), '2026-10-16T00:00:00+01:00', 'en-IL: Friday and Saturday');
is(p('en-IN', 'this weekend'), '2026-10-18T00:00:00+01:00', 'en-IN: Sunday alone, and its week starts on one');
is(p('en-SD', 'this weekend'), '2026-10-16T00:00:00+01:00', 'en-SD: Friday and Saturday across its week\'s start');
{
    local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 18, hour => 9, zone => 'Europe/London');
    is(p('en-GB', 'this weekend'), '2026-10-17T00:00:00+01:00', 'on a Sunday, this weekend is the one under way');
}
like(p('en', 'the weekend'), qr/cannot read 'the weekend'/, 'the weekend alone is not read');

done_testing;
