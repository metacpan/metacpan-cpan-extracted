#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;

use Time::Keeper;

my $D = 'Time::Keeper::Duration';
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

# English, the three styles.
{
    is($D->new(hours => 1, minutes => 30)->format, '1 hour, 30 minutes', 'an hour and a half');
    is($D->new(hours => 1, minutes => 30)->format(style => 'short'), '1 hr, 30 min', 'short');
    is($D->new(hours => 1, minutes => 30)->format(style => 'narrow'), '1h 30m', 'narrow');
    is($D->new(hours => 2)->format, '2 hours', 'plural');
    is($D->new(hours => 1)->format, '1 hour', 'singular');
    is($D->new(days => 2, hours => 3, minutes => 4)->format, '2 days, 3 hours, 4 minutes', 'three parts');
    is($D->new(days => 2, hours => 3, minutes => 4, seconds => 5)->format, '2 days, 3 hours, 4 minutes, 5 seconds', 'four');
    is($D->new(years => 1, months => 2, weeks => 3, days => 4)->format, '1 year, 2 months, 3 weeks, 4 days', 'the calendar parts');
    is($D->new(months => 14)->format, '1 year, 2 months', 'months fold into years');
    is($D->new(days => 10)->format, '1 week, 3 days', 'days into weeks');
    is($D->new(seconds => 90)->format, '1 minute, 30 seconds', 'seconds into minutes');
    is($D->new(minutes => 90)->format, '1 hour, 30 minutes', 'and minutes into hours');
    is($D->new(seconds => 1, nanoseconds => 500_000)->format, '1 second, 500 microseconds', 'nanoseconds into microseconds');
    is($D->new(nanoseconds => 1_500_000_000)->format, '1 second, 500 milliseconds', 'and milliseconds');
    is($D->new->format, '0 seconds', 'nothing is 0 seconds');
    is($D->new(hours => -1, minutes => -30)->format, '1 hour, 30 minutes', 'a negative duration is written without its sign');
    is($D->new(months => 1, days => -1)->format, '1 month, 1 day', 'as are mixed signs, part by part');
    is($D->new(hours => 0, seconds => 7)->format, '7 seconds', 'zero parts are left out');
}

# Units and largest.
{
    is($D->new(minutes => 90)->format(units => ['hours', 'minutes']), '1 hour, 30 minutes', 'the units given');
    is($D->new(minutes => 90)->format(units => ['minutes']), '90 minutes', 'minutes alone: hours fold in');
    is($D->new(minutes => 90, seconds => 15)->format(units => ['hours', 'minutes']), '1 hour, 30 minutes', 'the seconds below are dropped');
    is($D->new(hours => 1)->format(units => ['minutes']), '60 minutes', 'an hour in minutes');
    is($D->new(hours => 1)->format(units => ['seconds']), '3600 seconds', 'or seconds');
    is($D->new(days => 10)->format(units => ['days']), '10 days', 'days without weeks');
    is($D->new(months => 14)->format(units => ['months']), '14 months', 'months without years');
    is($D->new(months => 14)->format(units => ['years']), '1 year', 'years without months: the months below are dropped');
    is($D->new(minutes => 90)->format(units => ['hour', 'minute']), '1 hour, 30 minutes', 'singular names too');
    is($D->new(days => 2, hours => 3, minutes => 4)->format(largest => 1), '2 days', 'the largest part');
    is($D->new(days => 2, hours => 3, minutes => 4)->format(largest => 2), '2 days, 3 hours', 'the two largest');
    is($D->new(hours => 3, minutes => 4)->format(largest => 1), '3 hours', 'counting from the first that is not zero');
    is($D->new->format(units => ['minutes']), '0 minutes', 'nothing, in the smallest unit given');
    dies_like(sub { $D->new(months => 1)->format(units => ['days']) }, qr/a duration of months cannot be written in the units given/, 'months need years or months');
    dies_like(sub { $D->new(days => 1)->format(units => ['hours']) }, qr/a duration of days cannot be written in the units given/, 'days need weeks or days');
    dies_like(sub { $D->new(hours => 1)->format(units => ['days']) }, qr/a duration of clock time cannot be written in the units given/, 'and clock time a clock unit');
    dies_like(sub { $D->new->format(units => []) }, qr/units is empty/, 'an empty list');
    dies_like(sub { $D->new->format(units => 'hours') }, qr/units is a list of unit names/, 'not a list');
    dies_like(sub { $D->new->format(units => ['fortnights']) }, qr/'fortnights' is not a unit/, 'a unit it does not know');
    dies_like(sub { $D->new->format(largest => 0) }, qr/largest 0 is out of range/, 'largest 0');
    dies_like(sub { $D->new->format(style => 'wide') }, qr/style is 'long', 'short', 'narrow' or 'digital', not 'wide'/, 'a style it does not know');
}

# Digital.
{
    is($D->new(hours => 1, minutes => 30)->format(style => 'digital'), '1:30:00', 'h:mm:ss');
    is($D->new(minutes => 5, seconds => 9)->format(style => 'digital'), '0:05:09', 'with no hours');
    is($D->new(hours => 25, seconds => 7)->format(style => 'digital'), '25:00:07', 'over a day');
    is($D->new(seconds => -90)->format(style => 'digital'), '0:01:30', 'without its sign');
    is($D->new->format(style => 'digital'), '0:00:00', 'nothing');
    dies_like(sub { $D->new(days => 1)->format(style => 'digital') }, qr/months or days has no fixed length to write as digits/, 'not with days');
}

# Other locales.
{
    is($D->new(hours => 1, minutes => 30)->format(locale => 'de'), '1 Stunde, 30 Minuten', 'German');
    is($D->new(hours => 1, minutes => 30)->format(locale => 'de', style => 'short'), '1 Std., 30 Min.', 'German short');
    is($D->new(hours => 1, minutes => 30)->format(locale => 'de', style => 'narrow'), '1h, 30 Min.', 'German narrow, as CLDR has it');
    is($D->new(hours => 1, minutes => 30)->format(locale => 'fr'), "1\x{a0}heure et 30 minutes", 'French joins with et (and a no-break space after the 1)');
    is($D->new(days => 2, hours => 3, minutes => 4)->format(locale => 'fr'), "2\x{a0}jours, 3\x{a0}heures et 4 minutes", 'and commas before');
    is($D->new(minutes => 5)->format(locale => 'ru'), '5 минут', 'Russian many');
    is($D->new(minutes => 2)->format(locale => 'ru'), '2 минуты', 'Russian few');
    is($D->new(minutes => 21)->format(locale => 'ru'), '21 минута', 'Russian one for 21');
    is($D->new(hours => 2)->format(locale => 'ar-EG'), 'ساعتان', 'Arabic two, in the dual, with no digit');
    is($D->new(hours => 3)->format(locale => 'ar-EG'), '٣ ساعات', 'Arabic few, in Arabic digits');
    is($D->new(hours => 1, minutes => 5)->format(locale => 'ja'), '1 時間 5 分', 'Japanese');
    is($D->new(hours => 1, minutes => 5)->format(locale => 'ja', style => 'digital'), '1:05:00', 'digital is the same shape');
    is($D->new(hours => 1)->format(locale => 'fr-CA'), "1\x{a0}heure", 'a child locale');
    dies_like(sub { $D->new->format(locale => 'xx-YY') }, qr/there is no locale 'xx-YY'/, 'a locale that is not there');
}

done_testing;
