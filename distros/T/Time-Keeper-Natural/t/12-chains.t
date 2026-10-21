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
sub str {
    my ($code) = @_;
    my $v = eval { $code->() };
    return defined $v ? "$v" : "died: $@";
}
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}
my $anchor = Time::Keeper->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'Europe/London', locale => 'en-GB');
local $Time::Keeper::CLOCK = $anchor;
my $n = $N->new(zone => 'Europe/London', locale => 'en-GB');

# Parts joined by the list words, by commas, by spaces.
{
    is(str(sub { $n->parse('in 1 hour, 30 minutes and 10 seconds') }), '2026-10-15T10:30:10+01:00', 'three parts, the Oxford comma');
    is(str(sub { $n->parse('in 1 hour, 30 minutes, and 10 seconds') }), '2026-10-15T10:30:10+01:00', 'and with one');
    is(str(sub { $n->parse('in 1 hour and 30 minutes') }), '2026-10-15T10:30:00+01:00', 'two parts');
    is(str(sub { $n->parse('in 1 hour 30 minutes') }), '2026-10-15T10:30:00+01:00', 'joined by nothing');
    is(str(sub { $n->parse('in 2 weeks 3 days') }), '2026-11-01T09:00:00+00:00', 'date parts joined by nothing');
    is(str(sub { $n->parse('2 weeks and 3 days ago') }), '2026-09-28T09:00:00+01:00', 'the direction at the end');
    is(str(sub { $n->parse('1 hour, 30 minutes and 10 seconds ago') }), '2026-10-15T07:29:50+01:00', 'three parts ago');
    is(str(sub { $n->parse('in 1 hr 30 min') }), '2026-10-15T10:30:00+01:00', 'the short width');
    is(str(sub { $n->in_locale('en')->parse('in 1h 30m') }), '2026-10-15T10:30:00+01:00', 'the narrow one in en, m being minutes after hours');
    is(str(sub { $n->in_locale('en')->parse('in 2y 30m') }), '2031-04-15T09:00:00+01:00', 'in 2y 30m is months: the nearest unit below years, as a duration reads it');
    is(str(sub { $n->in_locale('en')->parse('in 2y 3mo') }), '2029-01-15T09:00:00+00:00', 'and 3mo is months');
    is(str(sub { $n->parse('in 1 year, 2 months and 3 days') }), '2027-12-18T09:00:00+00:00', 'a year, months and days');
    is(str(sub { $n->parse('in 2 days and 500 milliseconds') }), '2026-10-17T09:00:00.500+01:00', 'milliseconds');
}

# The order of the parts is plus's: months before days.
{
    my $jan = Time::Keeper->new(year => 2026, month => 1, day => 31, hour => 9, zone => 'UTC', locale => 'en-GB');
    my $p = $N->new(now => $jan);
    is($p->parse('in 1 month and 1 day')->epoch, $jan->plus(months => 1, days => 1)->epoch, 'as one plus');
    is($p->parse('in 1 day and 1 month')->epoch, $jan->plus(months => 1, days => 1)->epoch, 'whichever is written first');
    is(str(sub { $p->parse('in 1 month and 1 day') }), '' . $jan->plus(months => 1, days => 1), 'the same value');
}

# Other locales.
{
    is(str(sub { $n->in_locale('fr')->parse('dans 2 semaines et 3 jours') }), '2026-11-01T09:00:00+00:00', 'fr dans ... et ...');
    is(str(sub { $n->in_locale('fr')->parse('il y a 2 semaines et 3 jours') }), '2026-09-28T09:00:00+01:00', 'fr il y a ... et ...');
    is(str(sub { $n->in_locale('de')->parse('in 2 Wochen und 3 Tagen') }), '2026-11-01T09:00:00+00:00', 'de, the dative Tagen from the pattern, not the unit word');
    is(str(sub { $n->in_locale('de')->parse('vor 2 Wochen und 3 Tagen') }), '2026-09-28T09:00:00+01:00', 'de vor');
    is(str(sub { $n->in_locale('es')->parse('dentro de 2 semanas y 3 días') }), '2026-11-01T09:00:00+00:00', 'es');
    is(str(sub { $n->in_locale('ru')->parse('через 2 недели и 3 дня') }), '2026-11-01T09:00:00+00:00', 'ru');
    is(str(sub { $n->in_locale('ar')->parse('خلال يومين و3 ساعات') }), '2026-10-17T12:00:00+01:00', 'ar, the dual and a joined waw');
    is(str(sub { $n->in_locale('ja')->parse('2週間3日後') }), '2026-11-01T09:00:00+00:00', 'ja, the parts split where a number starts');
    is(str(sub { $n->in_locale('ja')->parse('2 週間 3 日後') }), '2026-11-01T09:00:00+00:00', 'ja with the spaces Time::Keeper writes');
    is(str(sub { $n->in_locale('zh')->parse('2周3天后') }), '2026-11-01T09:00:00+00:00', 'zh');
    is(str(sub { $n->in_locale('he')->parse('בעוד שבועיים ו-3 ימים') }), '2026-11-01T09:00:00+00:00', 'he, the dual week and a joined vav');
}

# A day across a clock change is a day; 24 hours are 24 hours.
{
    my $before = Time::Keeper->new(year => 2026, month => 10, day => 24, hour => 12, zone => 'Europe/London', locale => 'en-GB');
    my $p = $N->new(now => $before);
    is(str(sub { $p->parse('in 1 day') }), '2026-10-25T12:00:00+00:00', 'in 1 day keeps the wall clock');
    is(str(sub { $p->parse('in 24 hours') }), '2026-10-25T11:00:00+00:00', 'in 24 hours is an hour earlier on the wall');
    is(str(sub { $p->parse('tomorrow') }), '2026-10-25T00:00:00+01:00', 'tomorrow starts before the change');
    my $spring = Time::Keeper->new(year => 2027, month => 3, day => 27, hour => 1, minute => 30, zone => 'Europe/London', locale => 'en-GB');
    is(str(sub { $N->new(now => $spring)->parse('in 1 day') }), '2027-03-28T02:30:00+01:00', 'a day into a gap moves forward');
    is(str(sub { $N->new(now => $spring)->parse('in 1 week and 0 days') }), '2027-04-03T01:30:00+01:00', 'a week on');
}

# Spaceless chains cut where a number word starts as well as digits, the
# longest piece that reads first, every piece read.
{
    my $p = sub { my ($loc, $t) = @_; str(sub { $N->new(zone => 'Europe/London', locale => $loc)->parse($t) }) };
    is($p->('ja', '二週間三日後'), '2026-11-01T09:00:00+00:00', 'ja: two weeks three days, in words');
    is($p->('ja', '二週間三日後'), $p->('ja', '2週間3日後'), 'as in digits');
    is($p->('ja', '2週間三日後'), '2026-11-01T09:00:00+00:00', 'digits and words mixed');
    is($p->('ja', '一時間三十分後'), '2026-10-15T10:30:00+01:00', 'thirty is one word, not three and ten');
    is($p->('zh', '两周三天后'), '2026-11-01T09:00:00+00:00', 'zh');
    is($p->('zh', '两天三小时前'), '2026-10-13T06:00:00+01:00', 'zh, the past');
    is($p->('yue', '兩個星期三日後'), '2026-11-01T09:00:00+00:00', 'yue: 星期三 (Wednesday) inside the chain is not one');
    is($p->('ja', '一昨日'), '2026-10-13T00:00:00+01:00', 'a fixed phrase that begins with a number character reads whole');
    is($p->('th', 'ในอีก 2 ชั่วโมง และ 30 นาที'), '2026-10-15T11:30:00+01:00', 'th: a piece that begins with its direction word');
    like($p->('ja', '一二三四五六七八九十一二三四五六七八九十'), qr/no such word in ja/, 'number words alone are no chain');
    like($p->('zh', '一个星期三天后'), qr/no such word in zh/, 'a piece CLDR does not write (个星期) still dies');
}

# Deaths.
{
    dies_like(sub { $n->parse('in 2 weeks and 3 days ago') }, qr/one direction a phrase/, 'both directions');
    dies_like(sub { $n->parse('in 2 weeks and in 3 days ago') }, qr/cannot read 'in 2 weeks and in 3 days ago' at 'ago': no such word/, 'a part marked at both ends is not a part');
    dies_like(sub { $n->parse('2 weeks and 3 days') }, qr/a duration, not a time; parse_duration reads it/, 'no direction');
    dies_like(sub { $n->parse('in 2 weeks and 3 Tuesdays') }, qr/no such word in en-GB/, 'a weekday in a chain');
    dies_like(sub { $n->parse('in 2 weeks and 3 fortnights') }, qr/cannot read 'in 2 weeks and 3 fortnights' at '(?:and|3|fortnights)': no such word/, 'a word it has not, named');
    dies_like(sub { $n->parse('in 2 weeks and') }, qr/no such word/, 'a joiner with nothing after it');
}

done_testing;
