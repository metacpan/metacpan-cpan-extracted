#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Time::Keeper;

# The calendars' metadata: which calendars a territory or a locale prefers
# (CLDR's calendarPreferenceData, a locale's territory from its code or from
# likelySubtags), when an era began, and the -u-ca- extension of a locale
# code picking the calendar where none is given (R14i).

my $K = 'Time::Keeper';
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'did not die' : $@);
}
sub pref { join ' ', Time::Keeper::Calendar->preferred(shift) }

is(pref('TH'), 'buddhist gregory', 'TH prefers the Buddhist calendar');
is(pref('SA'), 'gregory islamic-umalqura islamic islamic-rgsa', 'SA');
is(pref('IR'), 'persian gregory islamic islamic-civil islamic-tbla', 'IR prefers the Persian');
is(pref('IL'), 'gregory hebrew islamic islamic-civil islamic-tbla', 'IL');
is(pref('JP'), 'gregory japanese', 'JP');
is(pref('TW'), 'gregory roc chinese', 'TW');
is(pref('KR'), 'gregory dangi', 'KR');
is(pref('ET'), 'gregory ethiopic', 'ET');
is(pref('EG'), 'gregory coptic islamic islamic-civil islamic-tbla', 'EG');
is(pref('IN'), 'gregory indian', 'IN');
is(pref('001'), 'gregory', 'the world');
is(pref('US'), 'gregory', 'a territory with no entry is the world');
dies_like(sub { pref('us') }, qr/neither a territory nor a locale/, 'two small letters are a language, and us is not one');
is(pref('th'), 'buddhist gregory', 'a locale with no territory: the one it is likely in');
is(pref('th-TH'), 'buddhist gregory', 'a locale with its territory');
is(pref('en-IL'), 'gregory hebrew islamic islamic-civil islamic-tbla', 'the territory, not the language');
is(pref('zh-Hant'), 'gregory roc chinese', 'zh-Hant is likely TW');
is(pref('zh'), 'gregory chinese', 'zh is likely CN');
is(pref('ko'), 'gregory dangi', 'ko is likely KR');
is(pref('fa'), 'persian gregory islamic islamic-civil islamic-tbla', 'fa is likely IR');
is(pref('he'), 'gregory hebrew islamic islamic-civil islamic-tbla', 'he is likely IL');
is(pref('ja'), 'gregory japanese', 'ja');
is(pref('am'), 'gregory ethiopic', 'am is likely ET');
is(pref('ar'), 'gregory coptic islamic islamic-civil islamic-tbla', 'ar is likely EG');
is(pref('en'), 'gregory', 'en is likely US');
is(pref('th-u-ca-buddhist'), 'buddhist gregory', 'an extension is stripped');
dies_like(sub { Time::Keeper::Calendar->preferred('xx-YY') }, qr/neither a territory nor a locale/, 'nonsense dies');
dies_like(sub { Time::Keeper::Calendar->preferred(undef) }, qr/territory or a locale code is wanted/, 'undef dies');
is(join(' ', Time::Keeper::Locale->calendars('th')), 'buddhist gregory', 'Locale->calendars is the same list');
is(join(' ', Time::Keeper::Locale->calendars('ar-SA')), pref('SA'), 'for a locale with a territory');
ok((grep { $_ eq 'buddhist' } Time::Keeper::Calendar->ids), 'every preferred id is a calendar id');
for my $t (qw(TH SA IR IL JP TW KR ET EG IN AF CN)) {
    my %ids = map { $_ => 1 } Time::Keeper::Calendar->ids;
    my @bad = grep { !$ids{$_} } Time::Keeper::Calendar->preferred($t);
    is(scalar @bad, 0, "$t names only calendars that exist") or diag(join ' ', @bad);
}

# era starts
my $d = Time::Keeper::Calendar->era_start('japanese', 'reiwa');
isa_ok($d, 'Time::Keeper::Date', 'era_start');
is("$d", '2019-05-01', 'Reiwa began on 1 May 2019');
is(Time::Keeper::Calendar->era_start('japanese', 'heisei')->iso8601, '1989-01-08', 'Heisei');
is(Time::Keeper::Calendar->era_start('japanese', 'Reiwa')->iso8601, '2019-05-01', 'any case');
is(Time::Keeper::Calendar->era_start('gregory', 'ce')->iso8601, '0001-01-01', 'the common era');
ok(!defined Time::Keeper::Calendar->era_start('gregory', 'bce'), 'an era with no beginning is undef');
is(Time::Keeper::Calendar->era_start('roc', 'roc')->iso8601, '1912-01-01', 'Minguo');
ok(!defined Time::Keeper::Calendar->era_start('roc', 'broc'), 'before Minguo');
is(Time::Keeper::Calendar->era_start('buddhist', 'be')->year, -542, 'the Buddhist era began in 543 BCE');
is(Time::Keeper::Calendar->era_start('hebrew', 'am')->year, -3760, 'Anno Mundi began in 3761 BCE');
is(Time::Keeper::Calendar->era_start('islamic', 'ah')->iso8601, '0622-07-19', 'the Hijra, 19 July 622 (proleptic Gregorian)');
is(Time::Keeper::Calendar->era_start('coptic', 'am')->iso8601, '0284-08-29', 'the Era of the Martyrs');
is(Time::Keeper::Calendar->era_start('persian', 'ap')->iso8601, '0622-03-21', 'Anno Persico, as ICU has it');
is($K->new(year => 2019, month => 5, day => 1, calendar => 'japanese')->era, 'reiwa', 'the day it began is in the era');
is($K->new(year => 2019, month => 4, day => 30, calendar => 'japanese')->era, 'heisei', 'the day before is not');
dies_like(sub { Time::Keeper::Calendar->era_start('japanese', 'foo') }, qr/the japanese calendar has no era 'foo'/, 'an unknown era dies');
dies_like(sub { Time::Keeper::Calendar->era_start('klingon', 'ce') }, qr/klingon/, 'an unknown calendar dies');

# the -u-ca- extension
my $t = $K->new(year => 2569, month => 10, day => 15, locale => 'th-u-ca-buddhist');
is($t->calendar, 'buddhist', 'new reads the calendar from the locale code');
is($t->locale, 'th', 'and the locale is the code before it');
is($t->iso8601, '2026-10-15T00:00:00Z', 'the year given was the Buddhist one');
is($K->new(year => 2026, month => 1, day => 1, locale => 'th-u-ca-buddhist', calendar => 'gregory')->calendar, 'gregory', 'calendar => wins over the extension');
is($K->now(locale => 'ja-u-ca-japanese')->calendar, 'japanese', 'now');
is($K->today(locale => 'he-u-ca-hebrew')->calendar, 'hebrew', 'today');
is($K->from_epoch(0, locale => 'he-u-ca-hebrew')->year, 5730, 'from_epoch');
is($K->from_epoch(0, locale => 'ar-EG-u-ca-islamic-civil')->calendar, 'islamic-civil', 'an id with a hyphen');
is($K->from_epoch(0, locale => 'ar_EG_u_ca_islamic-civil')->locale, 'ar-EG', 'underscores for the marker');
is($K->from_epoch(0, locale => 'EN-U-CA-GREGORIAN')->calendar, 'gregory', 'any case, an alias');
my $h = $K->now->in_locale('th-u-ca-buddhist');
is($h->calendar . ' ' . $h->locale, 'buddhist th', 'in_locale sets both');
is($h->in_locale('en')->calendar, 'buddhist', 'in_locale without an extension keeps the calendar');
is(Time::Keeper::Locale->code('th-u-ca-buddhist'), 'th', 'Locale->code strips the extension');
is(Time::Keeper::Locale->code('th_u_ca_buddhist'), 'th', 'with underscores');
is(Time::Keeper::Locale->name('th-u-ca-buddhist'), 'Thai', 'the other Locale methods too');
ok(!defined Time::Keeper::Locale->code('xx-u-ca-buddhist'), 'a code that is not a locale is still not one');
dies_like(sub { $K->now(locale => 'th-u-ca-klingon') }, qr/names a calendar that is not known/, 'an unknown calendar in the extension dies');
dies_like(sub { $K->now(locale => 'th-u-ca-') }, qr/names a calendar that is not known/, 'an empty one dies');
is($K->parse('2026-10-15T00:00:00Z', locale => 'he-u-ca-hebrew')->calendar, 'hebrew', 'parse');
is($K->parse('2026-10-15T00:00:00Z[u-ca=hebrew]', locale => 'he-u-ca-hebrew')->calendar, 'hebrew', 'an annotation that agrees');
dies_like(sub { $K->parse('2026-10-15T00:00:00Z[u-ca=japanese]', locale => 'he-u-ca-hebrew') }, qr/names the japanese calendar and calendar => names hebrew/, 'one that disagrees dies');
is($K->parse_cldr('5 Tishri 5787', 'd MMMM y', locale => 'en-u-ca-hebrew')->iso8601, '2026-09-16T00:00:00Z', 'parse_cldr reads the extension as calendar =>');
is($K->strptime('5786-01-17', '%Y-%m-%d', locale => 'en-u-ca-hebrew')->iso8601, '2025-10-09T00:00:00Z', 'strptime too');
is(Time::Keeper::Date->new(year => 2026, month => 10, day => 15, locale => 'th-u-ca-buddhist')->locale, 'th', 'a plain date takes the locale and ignores the extension');
is(Time::Keeper::Locale->first_day_of_week('en-US-u-ca-hebrew'), Time::Keeper::Locale->first_day_of_week('en-US'), 'the locale data is the code\'s');

done_testing;
