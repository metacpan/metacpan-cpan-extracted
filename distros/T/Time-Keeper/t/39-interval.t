#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;

use Time::Keeper;

my $K = 'Time::Keeper';
sub t { $K->new(@_) }
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'it did not die' : "died with: $@");
}
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);
my $dash = "\x{2009}\x{2013}\x{2009}";
my $nnb = "\x{202f}";

my $a = t(year => 2026, month => 10, day => 15, hour => 9, minute => 0);

# English, by the greatest field that differs.
{
    is($a->format_interval($a->plus(days => 2), skeleton => 'yMMMd'), "Oct 15${dash}17, 2026", 'the same month: the day differs');
    is($a->format_interval($a->plus(months => 1), skeleton => 'yMMMd'), "Oct 15${dash}Nov 15, 2026", 'the month differs');
    is($a->format_interval($a->plus(years => 1), skeleton => 'yMMMd'), "Oct 15, 2026${dash}Oct 15, 2027", 'the year differs');
    is($a->format_interval($a->plus(hours => 2), skeleton => 'yMMMd'), 'Oct 15, 2026', 'no difference in the fields the skeleton shows: one date');
    is($a->format_interval($a, skeleton => 'yMMMd'), 'Oct 15, 2026', 'the same instant');
    is($a->format_interval($a->plus(days => 2), skeleton => 'yMMMEd'), "Thu, Oct 15${dash}Sat, Oct 17, 2026", 'with the weekday');
    is($a->format_interval($a->plus(days => 2), skeleton => 'MMMd'), "Oct 15${dash}17", 'no year in the skeleton');
    is($a->format_interval($a->plus(years => 1), skeleton => 'MMMd'), "Oct 15, 2026${dash}Oct 15, 2027", 'the years differ but the skeleton has none: the skeleton is widened to the year, as formatRange does');
    is($a->format_interval($a->plus(hours => 1, minutes => 30), skeleton => 'hm'), "9:00${dash}10:30${nnb}AM", 'hm: the hour differs, one AM');
    is($a->format_interval($a->plus(hours => 5), skeleton => 'hm'), "9:00${nnb}AM${dash}2:00${nnb}PM", 'across noon: both periods');
    is($a->format_interval($a->plus(minutes => 15), skeleton => 'hm'), "9:00${dash}9:15${nnb}AM", 'minutes');
    is($a->format_interval($a->plus(hours => 5), skeleton => 'Hm'), "09:00${dash}14:00", '24-hour: no period to differ');
    is($a->format_interval($a->plus(seconds => 30), skeleton => 'hm'), "9:00${nnb}AM", 'seconds do not show: one time');
    is($a->format_interval($a->plus(days => 1, hours => 5), skeleton => 'hm'), "10/15/2026, 9:00${nnb}AM${dash}10/16/2026, 2:00${nnb}PM", 'a day apart: a time skeleton gains the date, both ends in full');
    is($a->format_interval($a->plus(days => 1, hours => 5), skeleton => 'Hm'), "10/15/2026, 09:00${dash}10/16/2026, 14:00", 'in 24-hour time too');
    is($a->format_interval($a->plus(years => 1), skeleton => 'hm'), "10/15/2026, 9:00${nnb}AM${dash}10/15/2027, 9:00${nnb}AM", 'or a year apart');
    is($a->format_interval($a->plus(months => 2), skeleton => 'yMMM'), "Oct${dash}Dec 2026", 'months');
    is($a->format_interval($a->plus(years => 3), skeleton => 'y'), "2026${dash}2029", 'years');
    is($a->format_interval($a->plus(hours => 2), skeleton => 'yMMMd'), 'Oct 15, 2026', 'two hours apart on one date');
    is($a->format_interval($a->plus(days => 2), skeleton => 'd'), "15${dash}17", 'days alone');
}

# The two ends in either order, zones and floating time.
{
    is($a->plus(days => 2)->format_interval($a, skeleton => 'yMMMd'), "Oct 17${dash}15, 2026", 'in the order given, as Intl writes it');
    my $tokyo = $a->plus(days => 2)->in_zone('Asia/Tokyo');
    is($a->format_interval($tokyo, skeleton => 'yMMMd'), "Oct 15${dash}17, 2026", 'the end is brought into the start\'s zone');
    is($tokyo->format_interval($a, skeleton => 'yMMMd'), "Oct 17${dash}15, 2026", 'and the other way: 09:00 London on the 15th is 17:00 Tokyo on the 15th');
    my $f = t(year => 2026, month => 10, day => 15, zone => 'floating');
    is($f->format_interval($f->plus(days => 2), skeleton => 'yMMMd'), "Oct 15${dash}17, 2026", 'floating time');
    dies_like(sub { $f->format_interval($a, skeleton => 'yMMMd') }, qr/one value is in floating time and the other is not/, 'floating and not do not mix');
    dies_like(sub { $a->format_interval($f, skeleton => 'yMMMd') }, qr/one value is in floating time and the other is not/, 'either way');
}

# Other locales.
{
    is($a->in_locale('fr')->format_interval($a->plus(days => 2), skeleton => 'yMMMd'), "15–17 oct. 2026", 'French');
    is($a->in_locale('fr')->format_interval($a->plus(months => 1), skeleton => 'yMMMd'), "15 oct.${dash}15 nov. 2026", 'French, the month differs');
    is($a->in_locale('de')->format_interval($a->plus(days => 2), skeleton => 'yMMMd'), "15.–17. Okt. 2026", 'German');
    is($a->in_locale('ja')->format_interval($a->plus(days => 2), skeleton => 'yMMMd'), '2026年10月15日～17日', 'Japanese');
    is($a->in_locale('ja')->format_interval($a->plus(years => 1), skeleton => 'yMMMd'), '2026年10月15日～2027年10月15日', 'Japanese, the year differs');
    is($a->in_locale('ar-EG')->format_interval($a->plus(days => 2), skeleton => 'yMMMd'), "١٥–١٧ أكتوبر ٢٠٢٦", 'Arabic digits');
    is($a->in_locale('en-GB')->format_interval($a->plus(days => 2), skeleton => 'yMMMd'), "15${dash}17 Oct 2026", 'British, with the thin spaces');
    is($a->in_locale('fr-CA')->format_interval($a->plus(days => 2), skeleton => 'yMMMd'), $a->in_locale('fr-CA')->format_interval($a->plus(days => 2), skeleton => 'yMMMd'), 'a child locale answers');
}

# Bad arguments.
{
    dies_like(sub { $a->format_interval($a, skeleton => 'nothing') }, qr/the locale en has no interval formats for the skeleton 'nothing'/, 'a skeleton the locale has not');
    dies_like(sub { $a->format_interval($a) }, qr/say skeleton =>/, 'the skeleton is required');
    dies_like(sub { $a->format_interval('tomorrow', skeleton => 'yMMMd') }, qr/not a Time::Keeper value/, 'the end is a value');
    dies_like(sub { $a->format_interval($a, pattern => 'yMMMd') }, qr/unknown argument 'pattern'/, 'only the keys it knows');
}

done_testing;
