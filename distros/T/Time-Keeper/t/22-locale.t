#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;

use Time::Keeper;
use Time::Keeper::Locale;

binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);

my $K = 'Time::Keeper';
my $L = 'Time::Keeper::Locale';
my $t = $K->new(year => 2026, month => 10, day => 15, hour => 21, minute => 5, second => 7,
                zone => 'America/New_York');

# Codes, aliases, names.
my @codes = $L->codes;
cmp_ok(scalar @codes, '>=', 1100, 'every locale and default-content code');
is($codes[0], 'en', 'English first');
is($L->cldr_version, '48.2.3', 'the CLDR release');
is($L->code('fr_ca'), 'fr-CA', 'a code in any case, with _');
is($L->code('EN-gb'), 'en-GB', 'and upper case');
is($L->code('iw'), 'he', 'a retired code is its replacement');
is($L->code('in'), 'id', 'another');
is($L->code('fr-FR'), 'fr-FR', 'a default-content code is its own');
ok(!defined $L->code('xx-YY'), 'an unknown code is undef from code');
ok(!defined $L->code(''), 'and nothing');
ok(!defined $L->code('en us'), 'and a code with a space');
ok(!eval { $L->name('xx'); 1 }, 'and an error elsewhere');
like($@, qr/there is no locale 'xx'/, 'that names it');
ok(!eval { $K->now(locale => 'Klingon'); 1 }, 'as a value\'s locale too');
is($L->name('fr-CA'), 'French (Canada)', 'a name in English');
is($L->native_name('fr-CA'), 'français (Canada)', 'and in its own language');
is($L->name('zh-Hant-TW'), 'Chinese (Traditional, Taiwan)', 'with a script and a territory');
is($L->native_name('ja'), '日本語', 'Japanese in Japanese');
my %seen;
$seen{$_}++ for @codes;
is(scalar(grep { $seen{$_} > 1 } keys %seen), 0, 'no code twice');
is(scalar(grep { $L->code($_) ne $_ } @codes), 0, 'every code is found as itself');

# What a locale holds.
is_deeply([$L->names('fr', 'months')],
          [qw(janvier février mars avril mai juin juillet août septembre octobre novembre décembre)],
          'French months');
is_deeply([$L->names('fr', 'days', 'short')], [qw(lu ma me je ve sa di)], 'short days, Monday first');
is_deeply([$L->names('en', 'eras', 'abbreviated')], ['BC', 'AD'], 'eras');
is_deeply([$L->names('en', 'am_pm')], ['AM', 'PM'], 'am and pm');
is_deeply([$L->names('ru', 'months', 'wide', 'stand-alone')]->[0], 'январь', 'a stand-alone month');
is_deeply([$L->names('ru', 'months', 'wide', 'format')]->[0], 'января', 'differs from the format one');
ok(!eval { $L->names('en', 'months', 'short'); 1 }, 'short is for days only');
ok(!eval { $L->names('en', 'weeks'); 1 }, 'what must be one it has');
ok(!eval { $L->names('en', 'days', 'wide', 'sideways'); 1 }, 'and the context one of two');
is(scalar(() = $L->formats('ja', 'date')), 4, 'four date formats');
is(($L->formats('en', 'datetime'))[3], '{1}, {0}', 'a datetime format joins the date and the time');
ok(!eval { $L->formats('en', 'week'); 1 }, 'formats of a kind it has');
is($L->available_formats('en')->{yMMMd}, 'MMM d, y', 'available formats by skeleton');
is_deeply([$L->digits('en')], [0 .. 9], 'ASCII digits');
is(join('', $L->digits('ar-EG')), join('', map { chr(0x660 + $_) } 0 .. 9), 'Arabic-Indic digits');
is(join('', $L->digits('bn')), join('', map { chr(0x9E6 + $_) } 0 .. 9), 'Bengali digits');
is($L->first_day_of_week('en'), 7, 'the week starts on Sunday in the United States');
is($L->first_day_of_week('en-GB'), 1, 'and Monday in the United Kingdom');
is($L->first_day_of_week('fa'), 6, 'and Saturday in Iran');
is($L->min_days_in_first_week('en'), 1, 'any day of January makes week 1 in the United States');
is($L->min_days_in_first_week('de'), 4, 'four in Germany, as ISO 8601');
ok(!$L->prefers_24_hour_time('en'), 'a 12-hour clock in English');
ok($L->prefers_24_hour_time('de'), 'a 24-hour clock in German');

# A parent's data, under a child's own.
{
    my $same = 0;
    for my $w (qw(wide abbreviated narrow)) {
        for my $c ('format', 'stand-alone') {
            my @a = $L->names('fr', 'months', $w, $c);
            my @b = $L->names('fr-CA', 'months', $w, $c);
            $same += grep { $a[$_] eq $b[$_] } 0 .. 11;
        }
    }
    cmp_ok($same, '>=', 60, 'fr-CA has most of fr\'s month names');
    isnt(join(',', $L->names('fr-CA', 'months', 'abbreviated')), join(',', $L->names('fr', 'months', 'abbreviated')),
         'and its own where CLDR gives them');
    is_deeply([$L->names('fr-FR', 'months')], [$L->names('fr', 'months')], 'fr-FR is fr');
    is_deeply($L->available_formats('fr-FR'), $L->available_formats('fr'), 'all of it');
    isnt(($L->formats('en-AU', 'date'))[3], ($L->formats('en', 'date'))[3], 'en-AU writes short dates its own way');
    is(($L->formats('en-AU', 'date'))[0], ($L->formats('en-GB', 'date'))[0], 'and its full date as en-001 does');
}

# A value's locale.
is($t->locale, 'en', 'English by default');
my $f = $t->in_locale('fr');
is($f->locale, 'fr', 'in_locale');
is($f->epoch, $t->epoch, 'the same instant');
is($f->zone_name, 'America/New_York', 'in the same zone');
is($t->locale, 'en', 'the old value is as it was');
is($t->in_locale('fr_fr')->locale, 'fr-FR', 'a code in any form is written as CLDR writes it');
is($t->in_locale('iw')->locale, 'he', 'an alias as its replacement');
is($K->new(year => 2026, locale => 'de')->locale, 'de', 'new takes a locale');
is($K->now(locale => 'ja')->locale, 'ja', 'and now');
is($K->today(locale => 'ja')->locale, 'ja', 'and today');
is($K->from_epoch(0, locale => 'ko')->locale, 'ko', 'and from_epoch');
is($K->last_day_of_month(year => 2026, month => 2, locale => 'ko')->locale, 'ko', 'and last_day_of_month');
is($K->parse('2026-10-15', locale => 'pl')->locale, 'pl', 'and parse');
is($f->with(day => 1)->locale, 'fr', 'with keeps it');
is($f->in_zone('Asia/Tokyo')->locale, 'fr', 'and in_zone');
is($f->plus(days => 1)->locale, 'fr', 'and plus');
is($f->truncate(to => 'day')->locale, 'fr', 'and truncate');
is($f->as_utc->locale, 'fr', 'and as_utc');
ok($f == $t, 'the locale is not part of the instant');

# Names in a locale.
is($f->month_name, 'octobre', 'month_name in French');
is($f->day_abbr, 'jeu.', 'day_abbr');
is($f->format('EEEE d MMMM y'), 'jeudi 15 octobre 2026', 'a pattern in French');
is($f->format('EEEEEE'), 'je', 'EEEEEE is the short day');
is($f->format_date('full'), 'jeudi 15 octobre 2026', 'format_date');
is($f->strftime('%A %d %B'), 'jeudi 15 octobre', 'strftime names');
is($t->in_locale('ja')->format_date('full'), '2026年10月15日木曜日', 'Japanese');
is($t->in_locale('de')->format_time('short'), '21:05', 'a 24-hour locale');
ok(utf8::is_utf8($t->in_locale('ja')->format_date('full')), 'characters, not bytes');

# Digits.
my $a = $t->in_locale('ar-EG');
my $ar = sub { join '', map { /\d/ ? chr(0x660 + $_) : $_ } split //, $_[0] };
is($a->format('d/M/y'), $ar->('15/10/2026'), 'a CLDR pattern in the locale\'s digits');
is($a->format('HH:mm:ss.SSS'), $ar->('21:05:07.000'), 'and the fraction');
is($a->format("'2026' y"), '2026 ' . $ar->('2026'), 'quoted digits stay as they are');
is($a->strftime('%Y-%m-%d'), '2026-10-15', 'strftime writes ASCII');
is($a->strftime('%Od/%Om/%OY'), $ar->('15/10/2026'), 'and the locale\'s digits with %O');
is($a->strftime('%Ed'), '15', '%E is read and passed over');
is($a->format('X'), '-04', 'ISO offsets are ASCII');
is($a->iso8601, '2026-10-15T21:05:07-04:00', 'and iso8601');
is($t->in_locale('fr')->format('d/M/y'), '15/10/2026', 'a locale with ASCII digits');

# Day periods.
my $at = sub { $K->new(year => 2026, month => 10, day => 15, hour => $_[0], minute => $_[1] // 0, locale => $_[2]) };
is($at->(12, 0, 'en')->format('b'), 'noon', 'b at noon');
is($at->(0, 0, 'en')->format('b'), 'midnight', 'and midnight');
is($at->(12, 1, 'en')->format('b'), 'PM', 'b a minute after noon is PM');
is($K->new(year => 2026, hour => 12, second => 1)->format('b'), 'PM', 'and a second after');
is($at->(21, 5, 'en')->format('B'), 'at night', 'B in the evening');
is($at->(6, 30, 'en')->format('B'), 'in the morning', 'B in the morning');
is($at->(15, 0, 'en')->format('B'), 'in the afternoon', 'B in the afternoon');
is($at->(21, 5, 'fr')->format('h:mm BBBB'), '9:05 du soir', 'in French');
is($at->(3, 0, 'de')->format('B'), 'nachts', 'German has the night');
is($at->(12, 0, 'de')->format('b'), 'PM', 'and no noon');
is($at->(12, 0, 'de')->format('B'), 'mittags', 'but a midday');
is($at->(12, 0, 'yo')->format('B'), $at->(12, 0, 'yo')->format('a'), 'a locale with no periods writes AM or PM');
is($at->(21, 5, 'en')->format('BBBBB'), 'at night', 'the narrow form');

# Weeks as the locale counts them.
my $wk = sub { $K->new(year => $_[0], month => $_[1], day => $_[2], locale => $_[3])->format('Y-w-W') };
is($wk->(2026, 1, 1, 'en'), '2026-1-1', 'the 1st of January 2026 in the United States');
is($wk->(2027, 1, 1, 'en'), '2027-1-1', '2027 starts week 1 there');
is($wk->(2027, 1, 1, 'de'), '2026-53-0', 'and is in week 53 of 2026 in Germany, week 0 of the month');
is($wk->(2026, 12, 31, 'en'), '2027-1-5', 'the last day of 2026 is in week 1 of 2027 in the United States');
is($wk->(2026, 12, 31, 'en-GB'), '2026-53-5', 'and week 53 in the United Kingdom');
is($wk->(2026, 11, 1, 'de'), '2026-44-0', 'a Sunday before the month\'s first week');
is($K->new(year => 2027, month => 1, day => 1, locale => 'en')->week, 53, 'the week method stays ISO');
is($K->new(year => 2026, month => 10, day => 15, locale => 'en')->format('e c'), '5 5', 'e counts from Sunday in English');
is($K->new(year => 2026, month => 10, day => 15, locale => 'de')->format('e c'), '4 4', 'and from Monday in German');

# Zone names.
my $names = sub { my ($v, @p) = @_; join ' | ', map { $v->format($_) } @p };
is($names->($t, qw(z zzzz v vvvv)), 'EDT | Eastern Daylight Time | ET | Eastern Time', 'the specific and generic names');
is($names->($t, qw(V VV VVV VVVV)), 'usnyc | America/New_York | New York | New York Time', 'the four V forms');
is($names->($t, qw(O OOOO ZZZZ)), 'GMT-4 | GMT-04:00 | GMT-04:00', 'the GMT format');
is($names->($t->in_zone('Europe/London'), qw(z zzzz v VVVV)),
   'GMT+1 | British Summer Time | United Kingdom Time | United Kingdom Time', 'a zone with its own name');
is($names->($t->in_zone('UTC'), qw(z zzzz v vvvv)), 'UTC | Coordinated Universal Time | UTC | Coordinated Universal Time',
   'UTC');
is($names->($t->in_zone('Asia/Kolkata'), qw(z zzzz v vvvv)),
   'GMT+5:30 | India Standard Time | India Time | India Standard Time', 'a zone with no daylight time');
is($names->($t->in_zone('+05:30'), qw(z zzzz v VVV)), 'GMT+5:30 | GMT+05:30 | GMT+5:30 | +05:30', 'an offset');
is($names->($t->in_zone('Australia/Lord_Howe'), qw(VVV)), 'Lord Howe Island', 'a city CLDR names');
is($names->($t->in_zone('America/Indiana/Knox'), qw(VVV)), 'Knox, Indiana', 'and another');
is($names->($t->in_zone('America/Argentina/Buenos_Aires'), qw(VVV V)), 'Buenos Aires | arbue', 'a city of a nested name');
is($names->($K->new(year => 1995, month => 7, day => 1, zone => 'America/Indiana/Knox'), qw(zzzz)),
   'Eastern Standard Time', 'the metazone a zone was in then: Eastern, and no daylight time in Indiana');
is($names->($K->new(year => 2026, month => 7, day => 1, zone => 'America/Indiana/Knox'), qw(zzzz)),
   'Central Daylight Time', 'and Central now');
is($names->($f, qw(z zzzz vvvv VVVV)),
   "UTC\x{2212}4 | heure d’été de l’Est nord-américain | heure de l’Est nord-américain | heure : New York",
   'in French, with its own GMT format');
is($names->($t->in_zone('UTC')->in_locale('fr'), qw(O)), 'UTC', 'and its word for zero');
is($names->($a, qw(O)), "غرينتش" . chr(0x2D) . chr(0x664), 'in Arabic, with its digits');
is($names->($t->in_zone('+05:30:15'), qw(O OOOO)), 'GMT+5:30:15 | GMT+05:30:15', 'seconds of an offset');
is($K->new(year => 2026, zone => 'floating')->format('z v'), 'floating floating', 'floating time has no name');

# Reading names back.
my $rt = 0;
for my $l (qw(en fr de ja ar-EG fa bn he ru zh-Hant hi my)) {
    for my $z ('America/New_York', 'Europe/Paris', 'Asia/Kolkata', 'Pacific/Chatham', 'UTC') {
        my $v = $t->in_zone($z)->in_locale($l);
        for my $p ('EEEE d MMMM y HH:mm:ss zzzz', 'EEEEEE d/M/y H:mm:ss O', 'y-MM-dd HH:mm:ss vvvv',
                   'y-MM-dd HH:mm:ss z', 'GGGG y MMM d hh:mm:ss a OOOO', 'y-MM-dd HH:mm:ss VVVV',
                   'y-MM-dd HH:mm:ss v', 'y-MM-dd HH:mm:ss VVV', 'ccc LLLL d y hh:mm:ss B zzzz') {
            my $s = $v->format($p);
            my $back = eval { $K->parse_cldr($s, $p, locale => $l) };
            $rt++ unless $back && $back->epoch == $v->epoch;
            diag("$l $z '$p': '$s': " . ($back ? $back->iso8601 : $@)) unless $back && $back->epoch == $v->epoch;
        }
    }
}
is($rt, 0, 'zone names, GMT formats and day periods read back in 12 locales and 5 zones');
is($K->parse_cldr('2026-10-15 21:05 ' . $ar->('1') . 'x', 'y-MM-dd HH:mm d\'x\'', locale => 'en')->day, 1,
   'digits of any script are read in any locale');
is($K->parse_cldr($ar->('15/10/2026'), 'd/M/y', locale => 'ar-EG')->ymd, '2026-10-15', 'Arabic-Indic digits');
is($K->parse_cldr('15/10/2026', 'd/M/y', locale => 'ar-EG')->ymd, '2026-10-15', 'and ASCII in the same locale');
is($K->strptime($ar->('15') . ' octobre 2026', '%d %B %Y', locale => 'fr')->ymd, '2026-10-15',
   'strptime reads them too, with French names');
my $short_fa = ($L->names('fa', 'days', 'short'))[3];
is($K->parse_cldr("$short_fa 2026-10-15", 'EEEEEE y-MM-dd', locale => 'fa')->ymd, '2026-10-15',
   'a name with a digit in it');
like((eval { $K->parse_cldr($ar->('15/13/2026'), 'd/M/y', locale => 'ar-EG') } // $@), qr/no month 13/,
     'an error in Arabic digits');
like((eval { $K->parse_cldr($ar->('15/10/2026') . 'x', 'd/M/y', locale => 'ar-EG') } // $@), qr/at offset 10:/,
     'at an offset counted in characters');
is($K->parse_cldr('2026-11-01 01:30 Eastern Standard Time', 'y-MM-dd HH:mm zzzz')->offset, -5 * 3600,
   'a standard name picks the later reading of an overlap');
is($K->parse_cldr('2026-11-01 01:30 Eastern Daylight Time', 'y-MM-dd HH:mm zzzz')->offset, -4 * 3600,
   'and a daylight name the earlier');
is($K->parse_cldr('2026-10-15 9:05 at night', 'y-MM-dd h:mm B')->hour, 21, 'B makes a 12-hour time PM');
is($K->parse_cldr('2026-10-15 9:05 in the morning', 'y-MM-dd h:mm B')->hour, 9, 'or AM');
is($K->parse_cldr('2026-10-15 12:00 noon', 'y-MM-dd h:mm b')->hour, 12, 'noon');
is($K->parse_cldr('2026-10-15 12:00 midnight', 'y-MM-dd h:mm b')->hour, 0, 'midnight');
is($K->parse_cldr('2026-10-15 2:00 du matin', 'y-MM-dd h:mm B', locale => 'fr')->hour, 2, 'in French');
is($K->parse_cldr('2026-10-15 GMT+5:30', 'y-MM-dd O')->offset, 19800, 'a short GMT offset');
is($K->parse_cldr('2026-10-15 UTC' . chr(0x2212) . '04:00', 'y-MM-dd OOOO', locale => 'fr')->offset, -14400,
   'with a minus sign');

# Freezing keeps the locale by its code.
SKIP: {
    skip 'Storable is not installed', 3 unless eval { require Storable; 1 };
    my $back = Storable::thaw(Storable::freeze([$f]))->[0];
    is($back->locale, 'fr', 'a frozen value keeps its locale');
    is($back->epoch, $f->epoch, 'and its instant');
    is(Storable::thaw(Storable::freeze([$t]))->[0]->locale, 'en', 'and English');
}

done_testing;
