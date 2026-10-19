#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $now = $K->new(year => 2026, month => 10, day => 18, hour => 9, zone => 'Europe/London');
sub rel { my ($t, @o) = @_; $t->format_relative(to => $now, @o) }

# The unit chosen, and the words.
{
    is(rel($now->minus(hours => 3)), '3 hours ago', '3 hours ago');
    is(rel($now->plus(hours => 3)), 'in 3 hours', 'in 3 hours');
    is(rel($now->minus(hours => 1)), '1 hour ago', 'one hour');
    is(rel($now->minus(days => 1)), 'yesterday', 'a day ago is yesterday');
    is(rel($now->plus(days => 1)), 'tomorrow', 'and a day on is tomorrow');
    is(rel($now->minus(days => 2)), '2 days ago', 'English has no word for two days ago');
    is(rel($now->plus(days => 2)), 'in 2 days', 'nor two days on');
    is(rel($now->minus(hours => 10)), 'yesterday', '23:00 yesterday is yesterday: days are counted on the dates');
    is(rel($now->minus(hours => 10), unit => 'hour'), '10 hours ago', 'unless hours are asked for');
    is(rel($now->minus(hours => 23)), 'yesterday', 'as is 10:00 yesterday');
    is(rel($now->minus(hours => 8)), '8 hours ago', 'but 01:00 today is hours');
    is(rel($now->minus(weeks => 1)), 'last week', 'a week ago');
    is(rel($now->plus(weeks => 2)), 'in 2 weeks', 'two weeks on');
    is(rel($now->minus(months => 1)), 'last month', 'a month ago');
    is(rel($now->plus(months => 3)), 'in 3 months', 'three months on');
    is(rel($now->minus(years => 1)), 'last year', 'a year ago');
    is(rel($now->plus(years => 2)), 'in 2 years', 'two years on');
    is(rel($now->minus(months => 13)), 'last year', '13 months is a year');
    is(rel($now->minus(days => 10)), 'last week', '10 days is a week');
    is(rel($now->minus(days => 14)), '2 weeks ago', '14 days is two weeks');
    is(rel($now->minus(minutes => 5)), '5 minutes ago', 'minutes');
    is(rel($now->minus(seconds => 30)), '30 seconds ago', 'seconds');
    is(rel($now), 'now', 'the same instant is now');
    is(rel($now->minus(nanoseconds => 1)), 'now', 'a nanosecond ago is now');
    is(rel($now, numeric => 'always'), 'in 0 seconds', 'or in 0 seconds when numbers are wanted');
    is(rel($now->minus(days => 1), numeric => 'always'), '1 day ago', 'numeric always');
    is(rel($now->minus(hours => 10), unit => 'day', numeric => 'always'), '1 day ago', 'with a unit');
    is(rel($now->minus(hours => 3), unit => 'day'), 'today', 'today');
    is(rel($now->minus(hours => 3), unit => 'day', numeric => 'always'), 'in 0 days', 'as a number: 0 counts as the future, as Intl has it');
    is(rel($now->minus(hours => 3), unit => 'hour', numeric => 'always'), '3 hours ago', 'hours as a number');
    is(rel($now->minus(months => 3), unit => 'quarter'), 'last quarter', 'quarters');
    is(rel($now->minus(months => 8), unit => 'quarter'), '2 quarters ago', 'two quarters');
    is(rel($now->minus(months => 8), unit => 'year'), 'this year', 'this year');
    is(rel($now->minus(days => 3), unit => 'week'), 'this week', 'this week: the dates are 3 days apart but within 7');
    is(rel($now->minus(days => 3), unit => 'month'), 'this month', 'this month');
    is(rel($now->plus(hours => 1), unit => 'hour'), 'in 1 hour', 'in 1 hour');
    is(rel($now->plus(minutes => 1), unit => 'minute'), 'in 1 minute', 'in 1 minute');
    is(rel($now, unit => 'hour'), 'this hour', 'this hour');
    is(rel($now, unit => 'minute'), 'this minute', 'this minute');
}

# Styles.
{
    is(rel($now->minus(hours => 3), style => 'short'), '3 hr. ago', 'short');
    is(rel($now->minus(hours => 3), style => 'narrow'), '3h ago', 'narrow');
    is(rel($now->minus(days => 1), style => 'short'), 'yesterday', 'yesterday is yesterday in every style');
    is(rel($now->plus(months => 2), style => 'short'), 'in 2 mo.', 'short months');
    is(rel($now->plus(years => 2), style => 'narrow'), 'in 2y', 'narrow years');
}

# Other locales.
{
    is(rel($now->minus(hours => 3)->in_locale('fr')), 'il y a 3 heures', 'French');
    is(rel($now->minus(hours => 3)->in_locale('fr'), style => 'short'), "il y a 3\x{a0}h", 'French, short, with its no-break space');
    is(rel($now->minus(days => 1)->in_locale('fr')), 'hier', 'hier');
    is(rel($now->plus(days => 2)->in_locale('fr')), 'après-demain', 'French has the day after tomorrow');
    is(rel($now->plus(days => 2)->in_locale('ja')), '明後日', 'as has Japanese');
    is(rel($now->minus(days => 2)->in_locale('ja')), '一昨日', 'and the day before yesterday');
    is(rel($now->plus(days => 2)->in_locale('ja'), numeric => 'always'), '2 日後', 'or as a number');
    is(rel($now->minus(hours => 3)->in_locale('ja')), '3 時間前', 'Japanese hours');
    is(rel($now->minus(days => 5)->in_locale('ru')), '5 дней назад', 'Russian many');
    is(rel($now->minus(days => 2)->in_locale('ru')), 'позавчера', 'Russian has the day before yesterday too');
    is(rel($now->minus(days => 3)->in_locale('ru')), '3 дня назад', 'Russian few');
    is(rel($now->minus(days => 21)->in_locale('ru'), unit => 'day'), '21 день назад', 'Russian one for 21');
    is(rel($now->minus(days => 2)->in_locale('ar-EG'), numeric => 'always'), 'قبل يومين', 'Arabic two, in the dual');
    is(rel($now->minus(days => 3)->in_locale('ar-EG')), 'قبل ٣ أيام', 'Arabic few, in Arabic digits');
    is(rel($now->minus(days => 3)->in_locale('ar')), 'قبل 3 أيام', 'ar alone writes ASCII digits');
    is(rel($now->minus(hours => 3)->in_locale('de')), 'vor 3 Stunden', 'German');
    is(rel($now->minus(hours => 3)->in_locale('fr-CA')), 'il y a 3 heures', 'a child locale');
}

# Zones, floating time, and the default to.
{
    my $tokyo = $now->in_zone('Asia/Tokyo');
    is(rel($tokyo->minus(hours => 3)), '3 hours ago', 'the same instants in another zone');
    is($tokyo->minus(hours => 10)->format_relative(to => $tokyo), '10 hours ago', '07:00 and 17:00 Tokyo are the same date: hours');
    is($tokyo->minus(hours => 18)->format_relative(to => $tokyo), 'yesterday', '23:00 and 17:00 Tokyo are not: yesterday, by the dates in the value\'s zone');
    is($now->minus(hours => 10)->format_relative(to => $tokyo), 'yesterday', 'to in another zone is brought into the value\'s');
    my $f = $K->new(year => 2026, month => 10, day => 18, hour => 9, zone => 'floating');
    is($f->minus(days => 1)->format_relative(to => $f), 'yesterday', 'floating time');
    local $Time::Keeper::CLOCK = $K->parse('2026-10-18T12:00:00Z');
    is($K->now->in_zone('UTC')->minus(hours => 3)->format_relative, '3 hours ago', 'to defaults to now');
    like($K->now->in_zone('UTC')->plus(days => 400)->format_relative, qr/^in 1 year$|^next year$/, 'and the words follow');
}

# Bad arguments.
{
    dies_like(sub { rel($now, unit => 'fortnight') }, qr/unit is auto, year, quarter, month, week, day, hour, minute or second, not 'fortnight'/, 'a unit it does not know');
    dies_like(sub { rel($now, style => 'wide') }, qr/style is 'long', 'short' or 'narrow', not 'wide'/, 'a style it does not know');
    dies_like(sub { rel($now, numeric => 'sometimes') }, qr/numeric is 'auto' or 'always', not 'sometimes'/, 'a numeric it does not know');
    dies_like(sub { $now->format_relative(to => 'yesterday') }, qr/not a Time::Keeper value/, 'to is a value');
    dies_like(sub { $now->format_relative(from => $now) }, qr/unknown argument 'from'/, 'only the keys it knows');
}

done_testing;
