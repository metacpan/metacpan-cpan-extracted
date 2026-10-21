#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode $_, ':encoding(UTF-8)' for Test::More->builder->output, Test::More->builder->failure_output, Test::More->builder->todo_output;

use Time::Keeper;
use Time::Keeper::Natural;
use Time::Keeper::Natural::Words;

# find: every mention in a text. The clock is Thursday 15 October 2026,
# 09:00 in London.
my $N = 'Time::Keeper::Natural';
local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London');
sub f {
    my ($loc, $text, @opt) = @_;
    my $n = $N->new(locale => $loc, zone => 'Europe/London');
    return join ' | ', map {
        '[' . substr($text, $_->start, $_->end - $_->start) . '] ' . $_->kind . ' ' . $_->value . ($_->kind eq 'interval' ? ' .. ' . $_->to : '')
    } $n->find($text, @opt);
}
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}

# Where mentions are.
is(f('en', 'Can we meet next Tuesday at 3 pm, or on the 20th?'),
   '[next Tuesday at 3 pm] point 2026-10-20T15:00:00+01:00 | [on the 20th] point 2026-10-20T00:00:00+01:00',
   'two in a sentence, the longest of each');
is(f('en', 'tomorrow works for me'), '[tomorrow] point 2026-10-16T00:00:00+01:00', 'at the start');
is(f('en', 'I am free tomorrow'), '[tomorrow] point 2026-10-16T00:00:00+01:00', 'at the end');
is(f('en', 'today and tomorrow'), '[today] point 2026-10-15T00:00:00+01:00 | [tomorrow] point 2026-10-16T00:00:00+01:00', 'two side by side');
is(f('en', 'today tomorrow'), '[today] point 2026-10-15T00:00:00+01:00 | [tomorrow] point 2026-10-16T00:00:00+01:00', 'touching, they do not overlap');
is(f('en', '"tomorrow at noon" she said'), '[tomorrow at noon] point 2026-10-16T12:00:00+01:00', 'inside quotes, without them');
is(f('en', 'Café “tomorrow at 9 pm” — then'), '[tomorrow at 9 pm] point 2026-10-16T21:00:00+01:00', 'offsets in characters after a non-ASCII word');
is(f('en', 'next Tuesday at 3 pm.'), '[next Tuesday at 3 pm] point 2026-10-20T15:00:00+01:00', 'a sentence\'s full stop is not part of it');
is(f('en', '3 pm EST tomorrow'), '[3 pm EST tomorrow] point 2026-10-16T21:00:00+01:00', 'a zone in it');
is(f('en-GB', 'Deadline: 2026-10-30. Kickoff on 1 October 2026 at 9:30.'),
   '[2026-10-30] point 2026-10-30T00:00:00+00:00 | [on 1 October 2026 at 9:30] point 2026-10-01T09:30:00+01:00', 'dates and times');

# What is not one (M8).
is(f('en', 'I bought 3 apples yesterday.'), '[yesterday] point 2026-10-14T00:00:00+01:00', '3 apples is not a time');
is(f('en', 'See you in May.'), '', 'a month name alone is not one');
is(f('en', 'See you in May.', names => 1), '[May] point 2026-05-01T00:00:00+01:00', 'unless names says so');
is(f('en', 'Sunday'), '', 'nor a weekday name');
is(f('en', 'Sunday', names => 1), '[Sunday] point 2026-10-18T00:00:00+01:00', 'with names');
is(f('en', 'call me at 3'), '', 'a bare hour in a twelve-hour locale is not one');
is(join(' ', map { $_->value } $N->new(locale => 'en', zone => 'Europe/London', bare_hour => 'pm')->find('call me at 3')),
   '2026-10-15T15:00:00+01:00', 'the parser\'s options apply');
is(f('en', 'Hi all, thanks for joining.'), '', 'nothing');
is(f('en', ''), '', 'an empty text');

# The kinds.
is(f('en', 'It takes about 2 hours to get there'), '[2 hours] duration PT2H', 'a duration');
is(f('en', 'Remind me in 2 hours'), '[in 2 hours] point 2026-10-15T11:00:00+01:00', 'a point first');
is(f('en', 'Remind me in 2 hours', kinds => ['duration']), '[2 hours] duration PT2H', 'only durations');
is(f('en', 'open from 9 am to 5 pm on weekdays'), '[from 9 am to 5 pm] interval 2026-10-15T09:00:00+01:00 .. 2026-10-15T17:00:00+01:00', 'an interval');
is(f('en', 'Oct 15 – 17, 2026 is the conference'),
   '[Oct 15 – 17, 2026] interval 2026-10-15T00:00:00+01:00 .. 2026-10-17T23:59:59.999999999+01:00', 'as format_interval writes it');
is(f('en', 'closed Monday to Friday next week'), '[next week] point 2026-10-18T00:00:00+01:00', 'two names are not an interval');
is(f('en', 'closed Monday to Friday next week', names => 1),
   '[Monday to Friday] interval 2026-10-19T00:00:00+01:00 .. 2026-10-23T23:59:59.999999999+01:00 | [next week] point 2026-10-18T00:00:00+01:00',
   'with names they are');
is(f('en', 'from 9 am to 5 pm', kinds => ['point']), '[9 am] point 2026-10-15T09:00:00+01:00 | [5 pm] point 2026-10-15T17:00:00+01:00', 'without intervals, its ends');
{
    my ($m) = $N->new(locale => 'en', zone => 'Europe/London')->find('next Tuesday', kinds => ['date']);
    is(ref $m->value, 'Time::Keeper::Date', 'a date');
    is($m->kind, 'date', 'of kind date');
}

# The Match.
{
    my $text = 'Can we meet next Tuesday at 3 pm?';
    my @m = $N->new(locale => 'en', zone => 'Europe/London')->find($text);
    is(scalar @m, 1, 'one');
    isa_ok($m[0], 'Time::Keeper::Natural::Match');
    is($m[0]->text, $text, 'its text is the whole text');
    is($m[0]->start, 12, 'start');
    is($m[0]->end, 32, 'end');
    is($m[0]->precision, 'hour', 'precision');
    is_deeply([$m[0]->assumed], ['zone'], 'assumed');
    is($m[0]->locale, 'en', 'locale');
    is(scalar($N->new(locale => 'en', zone => 'Europe/London')->find('today and tomorrow')), 2, 'a count in scalar context');
    is(join(' ', map { $_->value } $N->find('tomorrow at noon', locale => 'en', zone => 'Europe/London')), '2026-10-16T12:00:00+01:00', 'as a class method');
}

# Other languages.
is(f('fr', 'On se voit demain à 15 h ou mardi prochain ?'),
   '[demain à 15 h] point 2026-10-16T15:00:00+01:00 | [mardi prochain] point 2026-10-20T00:00:00+01:00', 'fr');
is(f('de', 'Treffen wir uns morgen um 15:30 oder am Dienstag?'),
   '[morgen um 15:30] point 2026-10-16T15:30:00+01:00', 'de, a lone weekday without names');
is(f('de', 'Treffen wir uns morgen um 15:30 oder am Dienstag?', names => 1),
   '[morgen um 15:30] point 2026-10-16T15:30:00+01:00 | [am Dienstag] point 2026-10-20T00:00:00+01:00', 'and with');
is(f('ja', '来週の火曜日でもいいです。二週間三日後に会いましょう'),
   '[来週の火曜日] point 2026-10-20T00:00:00+01:00 | [二週間三日後に] point 2026-11-01T09:00:00+00:00', 'ja, in characters');
is(f('ja', '難しければ10月20日でも構いません。'), '[10月20日] point 2026-10-20T00:00:00+01:00', 'ja, a date');

# The vocabulary: every table test line is found whole, and so is what
# the formats write, inside other words, in a sample of locales (xt/16:
# every locale).
{
    my ($n_ok, @bad) = (0);
    for my $code (Time::Keeper::Natural::Words->locales) {
        my $w = Time::Keeper::Natural::Words->for($code);
        local $Time::Keeper::CLOCK = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London', locale => $code);
        my $n = $N->new(zone => 'Europe/London', locale => $code);
        for my $t ($w->tests) {
            my ($x, $want) = @$t;
            my @m = $n->find($x, names => 1);
            my $got = @m == 1 && $m[0]->start == 0 && $m[0]->end == length($x)
                ? ($m[0]->kind eq 'interval' ? $m[0]->value . ' / ' . $m[0]->to : '' . $m[0]->value) : 'not whole';
            $got eq $want ? $n_ok++ : push @bad, "$code '$x': $got";
        }
    }
    ok(!@bad, "every table test line, $n_ok, found whole") or diag(join "\n", @bad);
    my ($asks, @miss) = (0);
    for my $loc (qw(en en-GB fr de es it pt nl ru pl ja zh zh-Hant ko ar he hi bn th vi tr sv fi el uk cs hu ro id fa)) {
        my $n = $N->new(zone => 'Europe/London', locale => $loc);
        my $v = Time::Keeper->new(year => 2026, month => 11, day => 3, hour => 15, minute => 5, zone => 'Europe/London', locale => $loc);
        for my $t (map { my $m = $_; eval { $v->$m('long') } } qw(format_date format_datetime)) {
            my $p = eval { '' . $n->parse($t) };
            next unless defined $p;
            $asks++;
            my $x = "\x{a7}\x{a7} $t \x{a7}\x{a7}";
            my @m = $n->find($x);
            push @miss, "$loc '$t'" unless @m == 1 && substr($x, $m[0]->start, $m[0]->end - $m[0]->start) eq $t && '' . $m[0]->value eq $p;
        }
    }
    ok($asks > 50 && !@miss, "what $asks formats write, found whole inside other words") or diag(join "\n", @miss);
}

# Errors.
dies_like(sub { $N->new(locale => 'en')->find(undef) }, qr/^\QTime::Keeper::Natural->find: the text is undefined\E/, 'no text');
dies_like(sub { $N->new(locale => 'en')->find('x', kinds => ['week']) }, qr/'week' is not a kind; the kinds are point, date, duration and interval/, 'a kind that is not one');
dies_like(sub { $N->new(locale => 'en')->find('x', kinds => 'point') }, qr/kinds is a list of point, date, duration and interval/, 'kinds not a list');
dies_like(sub { $N->new(locale => 'en')->find('x', 'names') }, qr/options come in pairs/, 'an odd option');
dies_like(sub { $N->new(locale => 'en')->find('x', zone => 'UTC') }, qr/options go to new, not to find/, 'a parser option on an object');

done_testing;
