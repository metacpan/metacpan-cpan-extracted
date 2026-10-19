#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;

use Time::Keeper;

my $L = 'Time::Keeper::Locale';
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}

# The weekend.
{
    is_deeply([$L->weekend_start('en-US'), $L->weekend_end('en-US')], [6, 7], 'en-US: Saturday and Sunday');
    is_deeply([$L->weekend_start('en'), $L->weekend_end('en')], [6, 7], 'en, through likelySubtags, the same');
    is_deeply([$L->weekend_start('ar-EG'), $L->weekend_end('ar-EG')], [5, 6], 'ar-EG: Friday and Saturday');
    is_deeply([$L->weekend_start('he'), $L->weekend_end('he')], [5, 6], 'he: Friday and Saturday');
    is_deeply([$L->weekend_start('fa-AF'), $L->weekend_end('fa-AF')], [4, 5], 'fa-AF: Thursday and Friday');
    is_deeply([$L->weekend_start('hi-IN'), $L->weekend_end('hi-IN')], [7, 7], 'hi-IN: Sunday alone');
    is_deeply([$L->weekend_start('fr-CA'), $L->weekend_end('fr-CA')], [6, 7], 'a child locale');
    dies_like(sub { $L->weekend_start('xx-YY') }, qr/there is no locale 'xx-YY'/, 'a locale that is not there');
}

# Plural categories, against CLDR's own examples.
{
    my %want = (
        en => { one => [1], other => [0, 2, 16, 100, 1000] },
        fr => { one => [0, 1], many => [1_000_000, 2_000_000], other => [2, 17, 100, 1000] },
        ru => { one => [1, 21, 31, 101, 1001], few => [2, 3, 4, 22, 24, 102], many => [0, 5, 19, 100, 1000, 11, 14], other => [] },
        ar => { zero => [0], one => [1], two => [2], few => [3, 10, 103, 110, 1003], many => [11, 26, 111, 1011], other => [100, 102, 200, 1000] },
        ja => { other => [0, 1, 2, 100] },
        cy => { zero => [0], one => [1], two => [2], few => [3], many => [6], other => [4, 5, 7, 20, 100] },
        'pt-PT' => { one => [1], other => [0, 2, 100] },
        pt => { one => [0, 1], other => [2, 100] },
        pl => { one => [1], few => [2, 3, 4, 22, 24], many => [0, 5, 19, 100, 1000, 12, 14, 21 + 90], other => [] },
    );
    for my $loc (sort keys %want) {
        for my $cat (sort keys %{ $want{$loc} }) {
            is($L->plural_category($loc, $_), $cat, "$loc: $_ is $cat") for @{ $want{$loc}{$cat} };
        }
    }
    is($L->plural_category('en', -1), 'one', 'the sign is ignored');
    is($L->plural_category('en', '1000000000000'), 'other', 'a big number');
    dies_like(sub { $L->plural_category('en', 1.5) }, qr/the number is a whole number/, 'a fraction');
}

# Relative-time words.
{
    my $r = $L->relative_names('en', 'day');
    is($r->{display}, 'day', 'the field name');
    is_deeply($r->{at}, { -1 => 'yesterday', 0 => 'today', 1 => 'tomorrow' }, 'yesterday, today, tomorrow');
    is($r->{future}{one}, 'in {0} day', 'in a day');
    is($r->{future}{other}, 'in {0} days', 'in days');
    is($r->{past}{other}, '{0} days ago', 'days ago');
    ok(!exists $r->{future}{few}, 'English has no few');
    is($L->relative_names('en', 'hour')->{at}{0}, 'this hour', 'this hour');
    ok(!exists $L->relative_names('en', 'hour')->{at}{1}, 'but no next hour');
    is($L->relative_names('en', 'month', 'short')->{display}, 'mo.', 'short');
    is($L->relative_names('en', 'year', 'narrow')->{future}{one}, 'in {0}y', 'narrow');
    my $ja = $L->relative_names('ja', 'day');
    is_deeply($ja->{at}, { -2 => '一昨日', -1 => '昨日', 0 => '今日', 1 => '明日', 2 => '明後日' }, 'Japanese has the day before yesterday and after tomorrow');
    is($ja->{future}{other}, '{0} 日後', 'and one pattern');
    is($L->relative_names('fr', 'day')->{at}{-1}, 'hier', 'French');
    is($L->relative_names('fr-CA', 'day')->{at}{-1}, 'hier', 'inherited by a child');
    is($L->relative_names('ru', 'day')->{past}{many}, '{0} дней назад', 'Russian many');
    is($L->relative_names('ar', 'day')->{future}{two}, 'خلال يومين', 'Arabic two');
    dies_like(sub { $L->relative_names('en', 'fortnight') }, qr/the field is year, quarter, month, week, day, hour, minute, second, or a weekday mon to sun, not 'fortnight'/, 'a field it does not know');
    dies_like(sub { $L->relative_names('en', 'day', 'wide') }, qr/the width is 'long', 'short' or 'narrow', not 'wide'/, 'a width it does not know');
}

# The weekdays are fields too (archive version 4).
{
    my $t = $L->relative_names('en', 'tue');
    ok(!defined $t->{display}, 'a weekday has no display name');
    is_deeply($t->{at}, { -1 => 'last Tuesday', 0 => 'this Tuesday', 1 => 'next Tuesday' }, 'last, this and next Tuesday');
    is($t->{future}{one}, 'in {0} Tuesday', 'in a Tuesday');
    is($t->{future}{other}, 'in {0} Tuesdays', 'in Tuesdays');
    is($t->{past}{other}, '{0} Tuesdays ago', 'Tuesdays ago');
    is($L->relative_names('en', 'tue', 'short')->{at}{1}, 'next Tue.', 'short');
    is($L->relative_names('en', 'tue', 'narrow')->{at}{1}, 'next Tu', 'narrow');
    is($L->relative_names('en', 'sun')->{at}{-1}, 'last Sunday', 'the seventh');
    is($L->relative_names('en', 'mon')->{at}{0}, 'this Monday', 'the first');
    is($L->relative_names('ja', 'tue')->{at}{1}, '来週の火曜日', 'Japanese, the day name inside');
    is($L->relative_names('ja', 'tue')->{future}{other}, '{0} 個後の火曜日', 'and its one pattern');
    is($L->relative_names('en-GB', 'tue')->{at}{1}, 'next Tuesday', 'inherited by a child');
    for my $loc (qw(fr de ru ar zh he)) {
        for my $d (qw(mon tue wed thu fri sat sun)) {
            my $r = $L->relative_names($loc, $d);
            is_deeply([sort { $a <=> $b } keys %{ $r->{at} }], [-1, 0, 1], "$loc $d: last, this and next, nothing further");
            ok($r->{future}{other} && $r->{past}{other}, "$loc $d: a future and a past pattern");
        }
    }
    is($L->relative_names('ru', 'tue')->{past}{many}, $L->relative_names('ru', 'tue')->{past}{many}, 'Russian has its categories');
    ok(exists $L->relative_names('ar', 'fri')->{future}{two}, 'Arabic has its dual');
}

# The parts of a day, and when they are.
{
    my $p = $L->day_periods('en');
    is($p->{noon}, 'noon', 'noon');
    is($p->{midnight}, 'midnight', 'midnight');
    is($p->{afternoon1}, 'in the afternoon', 'in the afternoon');
    is($p->{am}, 'AM', 'am, as names gives it');
    is_deeply([$L->names('en', 'am_pm')], [@{$p}{qw(am pm)}], 'the same two strings');
    ok(!exists $p->{morning2}, 'English has one morning');
    ok(exists $L->day_periods('zh')->{morning2}, 'Chinese has two');
    is($L->day_periods('en', 'abbreviated')->{noon}, 'noon', 'abbreviated');
    ok(defined $L->day_periods('en', 'narrow')->{noon}, 'narrow');
    dies_like(sub { $L->day_periods('en', 'long') }, qr/the width is 'wide', 'abbreviated' or 'narrow', not 'long'/, 'a width it does not know');
    my @r = $L->day_period_rules('en');
    ok(@r >= 5, 'English has rules: ' . scalar @r);
    my %by = map { $_->{period} => $_ } @r;
    is($by{noon}{at}, 720, 'noon is at 12:00');
    is_deeply([@{ $by{morning1} }{qw(from before)}], [0, 720], 'the morning is 00:00 to 12:00, as CLDR 48 has it');
    is_deeply([@{ $by{afternoon1} }{qw(from before)}], [720, 1080], 'the afternoon 12:00 to 18:00');
    is_deeply([@{ $by{night1} }{qw(from before)}], [1260, 1440], 'the night 21:00 to 24:00: nothing crosses midnight');
    my %zh = map { $_->{period} => $_ } $L->day_period_rules('zh');
    is_deeply([@{ $zh{morning2} }{qw(from before)}], [480, 720], 'Chinese: the second morning 08:00 to 12:00');
    ok(!exists $by{noon}{from}, 'an at rule has no span');
    is_deeply([$L->day_period_rules('en-GB')], [@r], 'shared with a child');
    dies_like(sub { $L->day_period_rules('xx-YY') }, qr/there is no locale 'xx-YY'/, 'a locale that is not there');
}

# Duration units.
{
    my $u = $L->unit_patterns('en', 'hour');
    is($u->{display}, 'hours', 'the unit name');
    is($u->{count}{one}, '{0} hour', 'one');
    is($u->{count}{other}, '{0} hours', 'other');
    is($L->unit_patterns('en', 'hour', 'short')->{count}{other}, '{0} hr', 'short');
    is($L->unit_patterns('en', 'minute', 'narrow')->{count}{other}, '{0}m', 'narrow');
    is($L->unit_patterns('de', 'hour', 'short')->{display}, 'Std.', 'German');
    is($L->unit_patterns('fr', 'nanosecond')->{count}{other}, "{0}\x{a0}nanosecondes", 'nanoseconds in French, with its no-break space');
    is($L->unit_patterns('ru', 'minute')->{count}{few}, '{0} минуты', 'Russian few');
    my $d = $L->duration_patterns('en');
    is_deeply($d, { hm => 'h:mm', hms => 'h:mm:ss', ms => 'm:ss' }, 'the digital patterns');
    dies_like(sub { $L->unit_patterns('en', 'fortnight') }, qr/the unit is year, month, .*nanosecond, not 'fortnight'/, 'a unit it does not know');
}

# List patterns.
{
    my $l = $L->list_patterns('en');
    is($l->{two}, '{0} and {1}', 'standard: and');
    is($l->{end}, '{0}, and {1}', 'with the Oxford comma');
    is($L->list_patterns('en', 'unit')->{two}, '{0}, {1}', 'unit: a comma');
    is($L->list_patterns('en', 'unit-narrow')->{two}, '{0} {1}', 'narrow: a space');
    is($L->list_patterns('en-GB')->{end}, '{0} and {1}', 'en-GB: no Oxford comma');
    is($L->list_patterns('de')->{two}, '{0} und {1}', 'German');
    dies_like(sub { $L->list_patterns('en', 'or') }, qr/the type is 'standard', 'unit', 'unit-short' or 'unit-narrow', not 'or'/, 'a type it does not know');
}

# Interval formats.
{
    my $i = $L->interval_formats('en', 'yMMMd');
    my $dash = "\x{2009}\x{2013}\x{2009}";
    is_deeply($i, { M => "MMM d${dash}MMM d, y", d => "MMM d${dash}d, y", y => "MMM d, y${dash}MMM d, y" }, 'yMMMd by the greatest difference, with thin spaces round the dash');
    is($L->interval_formats('en', 'hm')->{a}, "h:mm\x{202f}a${dash}h:mm\x{202f}a", 'hm across noon, a narrow no-break space before the a');
    is_deeply($L->interval_formats('en', 'nothing'), {}, 'a skeleton the locale has not');
    my $all = $L->interval_formats('en');
    ok(scalar(keys %$all) >= 30, 'every skeleton: ' . scalar(keys %$all));
    is($all->{yMMMd}{d}, "MMM d${dash}d, y", 'the same patterns inside');
    is($L->interval_fallback('en'), "{0}${dash}{1}", 'the fallback');
    is($L->interval_formats('fr', 'yMMMd')->{d}, 'd–d MMM y', 'French');
    is($L->interval_formats('fr-CA', 'yMMMd')->{d}, $L->interval_formats('fr', 'yMMMd')->{d}, 'inherited unless overridden');
    is($L->interval_formats('ja', 'yMMMd')->{d}, 'y年M月d日～d日', 'Japanese');
}

# The archive still answers everything else, and English loads nothing.
{
    is(Time::Keeper->new(year => 2026, month => 10, day => 15, locale => 'fr')->format_date('full'), 'jeudi 15 octobre 2026', 'formats still read');
    is(join(',', $L->names('de', 'months', 'abbreviated')), 'Jan.,Feb.,März,Apr.,Mai,Juni,Juli,Aug.,Sept.,Okt.,Nov.,Dez.', 'names still read');
}

done_testing;
