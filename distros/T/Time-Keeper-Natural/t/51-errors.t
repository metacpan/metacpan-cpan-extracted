#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;

my $N = 'Time::Keeper::Natural';
my $anchor = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London', locale => 'en-GB');
local $Time::Keeper::CLOCK = $anchor;
my $n = $N->new(zone => 'Europe/London', locale => 'en-GB');
my $us = $n->in_locale('en-US');

# Every reason, produced once, with the token named as typed.
my @cases = (
    [ $n,  'parse',          '',                              '',          'the text is empty' ],
    [ $n,  'parse',          'next Tuesdy at 3',              'next',      'no such word in en-GB' ],
    [ $n,  'parse',          'in 2 weeks and 3 days ago',     undef,       'one direction a phrase' ],
    [ $n,  'parse',          '2 weeks',                       '2',         'a duration, not a time; parse_duration reads it' ],
    [ $n,  'parse_duration', 'tomorrow',                      'tomorrow',  'a time, not a duration' ],
    [ $n,  'parse_duration', '1 hour and 2 hours',            '2 hours',   'hour is given twice' ],
    [ $n,  'parse_duration', '-1 hour',                       '-',         'a sign; a duration is unsigned' ],
    [ $us, 'parse',          'tomorrow 3',                    '3',         'a bare hour; say am, pm or pass bare_hour' ],
    [ $n,  'parse',          'Tuesday 15 October',            'Tuesday',   '2026-10-15 was a Thursday' ],
    [ $n,  'parse',          'in 3 hours 5 pm',               'in',        'a time on a time' ],
    [ $n,  'parse',          'end of in 3 hours',             'in',        'a moment, not a period' ],
    [ $n,  'parse',          'end of',                        'end of',    "nothing left after 'end of'" ],
    [ $n,  'parse',          'the second Tuesday of next week', 'of',      'an ordinal weekday is counted in a month, not a week' ],
    [ $n,  'parse',          'the sixth Friday of November',  'sixth',     'no month has a sixth friday' ],
    [ $n,  'parse',          'the fifth Friday of November',  'fifth',     '2026-11 has no fifth friday' ],
    [ $n->in_locale('sw'), 'parse', 'end of last month',      'end of',    "coverage of sw is data; 'end of' needs its words" ],
    [ $n,  'parse_interval', 'tomorrow to yesterday',         'tomorrow',  'the interval ends before it starts' ],
    [ $n,  'parse_interval', 'tomorrow',                      'tomorrow',  'a single time, not an interval' ],
);
for my $c (@cases) {
    my ($p, $method, $text, $token, $reason) = @$c;
    my $ok = eval { $p->$method($text); 1 };
    my $err = $@;
    ok(!$ok, "'$text' dies: $reason");
    like($err, qr/^\Q$N->$method: cannot read '$text' at '\E/, '  in the shape');
    like($err, qr/: \Q$reason\E at /, '  with the reason');
    like($err, qr/ at '\Q$token\E': /, "  naming '$token'") if defined $token;
}

# A long text dies in the shape too: 0.01 gave Time::Keeper 0.07's panic when
# a text ran past its 256-byte buffer for the reason.
{
    my $long = '15 October ' . ('x' x 400);
    ok(!eval { $n->parse($long); 1 }, 'a 411-character text dies');
    like($@, qr/^\Q$N->parse: cannot read '\E/, '  in the shape, not with a panic');
    my $ccp = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 15, minute => 5, zone => 'America/New_York', locale => 'ccp')
        ->format_datetime('full');
    ok(defined $N->new(locale => 'ccp', zone => 'Europe/London')->try_parse($ccp), 'a long full date and time in Chakma reads');
}

# The deaths that are not reading.
{
    ok(!eval { $n->parse(undef); 1 }, 'no text dies');
    like($@, qr/^\Q$N->parse: the text is undefined\E/, '  outside the reading shape');
    ok(!eval { $N->new(colour => 1); 1 }, 'a bad option dies from new');
}

# try_ gives undef for every one, and leaves $@ alone.
{
    local $@ = 'left alone';
    for my $c (@cases) {
        my ($p, $method, $text) = @$c;
        my $try = "try_$method";
        is($p->$try($text), undef, "$try('$text')");
    }
    is($@, 'left alone', '$@ is left alone');
}

# The parser gives no reason off its list: every death goes through
# _cannot, which refuses one.
{
    ok(!eval { $n->_cannot('parse', 'tomorrow', 'tomorrow', 'a reason nobody wrote down'); 1 }, 'a reason off the list');
    like($@, qr/'a reason nobody wrote down' is not one of the reasons/, '  is refused by name');
}

done_testing;
