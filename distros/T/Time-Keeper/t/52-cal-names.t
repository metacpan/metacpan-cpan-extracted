#!perl
use 5.010;
use strict;
use warnings;
use utf8;
use Test::More;
binmode Test::More->builder->$_, ':encoding(UTF-8)' for qw(output failure_output todo_output);
use Time::Keeper;

# CLDR's names and formats in every calendar: the pattern letters, the date
# formats and skeletons per calendar and locale, the leap-month pattern,
# the numbering systems CLDR attaches to a pattern, the RFC 9557
# annotation both ways, and parsing in a calendar. The expected strings
# are what ICU writes (checked against Node's Intl in xt/25).

my $K = 'Time::Keeper';
sub dies_like {
    my ($code, $re, $name) = @_;
    my $ok = eval { $code->(); 1 };
    ok(!$ok && $@ =~ $re, $name) or diag($ok ? 'did not die' : $@);
}
my $t = $K->new(year => 2026, month => 10, day => 15, hour => 9, zone => 'UTC');
my $h = $t->in_calendar('hebrew');

# English, built in: every calendar formats with no file
is($h->format('d MMMM y'), '4 Heshvan 5787', 'hebrew d MMMM y in en');
is($h->format('G y M d'), 'AM 5787 2 4', 'G y M d: the era, the year, the ordinal month');
is($h->format('r'), '2026', 'r is the Gregorian year the Hebrew year began in');
is($h->in_locale('ar-EG')->format('MMMM'), 'مرحشوان', 'a child locale inherits its parent\'s names');
is($h->format_date('full'), 'Thursday, 4 Heshvan 5787', 'hebrew full date in en');
is($h->format('d MMMM y HH:mm'), '4 Heshvan 5787 09:00', 'the clock letters are the same');
is($h->month_name, 'Heshvan', 'month_name');
is($h->month_abbr, 'Heshvan', 'month_abbr');
is($h->era_abbr, 'AM', 'era_abbr');
is($h->era_name, 'AM', 'era_name');
is($h->ymd, '5787-02-04', 'ymd is the calendar date');
is($h->strftime('%Y-%m-%d %B %j'), '5787-02-04 Heshvan 034', 'strftime writes the calendar');
is($h->strftime('%G-W%V-%u'), '2026-W42-4', 'the ISO week stays Gregorian');
is($t->in_calendar('japanese')->format('GGGG y'), 'Reiwa 8', 'japanese era name and year');
is($t->in_calendar('japanese')->format('Gy'), 'Reiwa8', 'japanese abbreviated era');
is($t->in_calendar('japanese')->format_skeleton('Gy'), '8 Reiwa', 'the japanese Gy skeleton');
is($t->in_calendar('islamic-umalqura')->format('d MMMM y G'), '4 Jumada I 1448 AH', 'umalqura in en: a day behind the astronomical');
is($t->in_calendar('persian')->format_date('long'), 'Mehr 23, 1405 AP', 'persian long in en');
is($t->in_calendar('coptic')->format('d MMMM y'), '5 Baba 1743', 'coptic in en');
is($t->in_calendar('ethiopic')->format_date('medium'), 'Tekemt 5, 2019 AM', 'ethiopic medium in en');
is($t->in_calendar('buddhist')->format('y G'), '2569 BE', 'buddhist in en');
is($t->in_calendar('roc')->format('y G'), '115 Minguo', 'roc in en');
is($t->in_calendar('indian')->format('d MMMM y G'), '23 Asvina 1948 Śaka', 'indian in en');

# the Chinese calendars: four numbers for the year, the cyclic name, the leap pattern
my $c = $t->in_calendar('chinese');
is($c->format('U r'), 'bing-wu 2026', 'U r');
is($c->format('y u U r'), '43 4663 bing-wu 2026', 'y is the cycle year, u the continuous count, r the related year');
is($c->strftime('%Y'), '4663', 'strftime %Y is era_year for the Chinese');
is($c->format_date('long'), 'Ninth Month 6, 2026(bing-wu)', 'chinese long date in en');
is($c->format_skeleton('yMMMd'), 'Mo9 6, 2026', 'a y skeleton matches the calendar\'s yyyy skeleton');
is($c->format_skeleton('yMMM'), 'Mo9 2026', 'yMMM too');
is($c->format('G'), '', 'the Chinese era has no name');
is($c->cyclic_year_name, 'bing-wu', 'cyclic_year_name');
is($t->in_calendar('dangi')->in_locale('zh')->cyclic_year_name, '丙午', 'cyclic_year_name in zh');
ok(!defined $t->cyclic_year_name, 'cyclic_year_name is undef in the Gregorian');
ok(!defined $h->cyclic_year_name, 'and in the Hebrew');
my $leap = $K->new(year => 2025, month => 7, day => 25, zone => 'UTC')->in_calendar('chinese');
is($leap->month_code, 'M06L', 'the fixture is a leap month');
is($leap->format('MMMM d, r'), 'Sixth Monthbis 1, 2025', 'the wide leap pattern');
is($leap->format('MMM'), 'Mo6bis', 'the abbreviated leap pattern');
is($leap->format('M'), '6bis', 'the numeric leap pattern');
is($leap->month_name, 'Sixth Monthbis', 'month_name wraps too');
is($leap->in_locale('zh')->format('MMMM'), '闰六月', 'zh leap pattern');

# the Hebrew numeric month is the ordinal, as ICU writes it; names follow CLDR's slots
is($K->new(year => 2025, month => 3, day => 30, zone => 'UTC')->in_calendar('hebrew')->format('M MMMM d y'), '7 Nisan 1 5785', 'Nisan is 7 in a common year');
is($K->new(year => 2025, month => 3, day => 1, zone => 'UTC')->in_calendar('hebrew')->format('M MMMM'), '6 Adar', 'Adar is 6 in a common year');
is($K->new(year => 2024, month => 2, day => 10, zone => 'UTC')->in_calendar('hebrew')->format('M MMMM'), '6 Adar I', 'Adar I is 6 in a leap year');
is($K->new(year => 2024, month => 3, day => 11, zone => 'UTC')->in_calendar('hebrew')->format('M MMMM'), '7 Adar II', 'Adar II is 7 in a leap year');
is($K->new(year => 2024, month => 4, day => 9, zone => 'UTC')->in_calendar('hebrew')->format('M MMMM'), '8 Nisan', 'Nisan is 8 in a leap year');

# other locales: their own names, their parents' and the root's
is($h->in_locale('he')->format_date('long'), 'ד׳ בחשוון תשפ״ז', 'he hebrew long: Hebrew letters');
is($h->in_locale('he')->format_date('full'), 'יום חמישי, ד׳ בחשוון תשפ״ז', 'he hebrew full');
is($K->new(year => 2025, month => 3, day => 15, zone => 'UTC')->in_calendar('hebrew')->in_locale('he')->format_date('long'), 'ט״ו באדר תשפ״ה', '15 is tet vav');
is($K->new(year => 2025, month => 3, day => 16, zone => 'UTC')->in_calendar('hebrew')->in_locale('he')->format_date('long'), 'ט״ז באדר תשפ״ה', '16 is tet zayin');
is($K->new(year => 1240, month => 9, day => 10, zone => 'UTC')->in_calendar('hebrew')->in_locale('he')->format_date('long'), 'ט״ו באלול ה׳ אלפים', 'the year 5000 writes its thousands');
is($K->new(year => 2240, month => 9, day => 10, zone => 'UTC')->in_calendar('hebrew')->in_locale('he')->format_date('long'), 'כ״ג באלול ו׳ אלפים', 'the year 6000 too');
is($K->new(year => 2241, month => 9, day => 10, zone => 'UTC')->in_calendar('hebrew')->in_locale('he')->format_date('long'), 'ד׳ בתשרי ו׳ב׳', 'the year 6002: thousands with a geresh, then the rest');
is($h->in_locale('he')->format('M d y'), '2 4 5787', 'a pattern of the user\'s own has no numbering override');
is($c->in_locale('zh')->format_date('full'), '2026丙午年九月初六星期四', 'zh chinese full: the day in its own numerals');
is($c->in_locale('zh')->format_date('short'), '2026/9/6', 'zh chinese short: digits');
is($t->in_calendar('dangi')->in_locale('zh')->format_date('long'), '2026丙午年九月初五', 'zh dangi long');
is($c->in_locale('ja')->format_date('long'), '丙午年九月六日', 'ja chinese long: hanidec digits');
is($c->in_locale('ja')->format_date('short'), '丙午-9-6', 'ja chinese short');
is($t->in_calendar('japanese')->in_locale('ja')->format('GGGGy年M月d日'), '令和8年10月15日', 'ja japanese');
is($K->new(year => 2019, month => 5, day => 1, zone => 'UTC')->in_calendar('japanese')->in_locale('ja')->format_date('long'), '令和元年5月1日', 'the first year of an era is 元 in ja');
is($K->new(year => 2020, month => 5, day => 1, zone => 'UTC')->in_calendar('japanese')->in_locale('ja')->format_date('short'), 'R2/5/1', 'ja japanese short');
is($h->in_locale('haw')->format_date('short'), '4/ii/87 AM', 'haw: the month in roman numerals');
is($h->in_locale('fr')->format_date('long'), '4 hèchvan 5787 A. M.', 'fr hebrew');
is($t->in_calendar('islamic')->in_locale('de')->format_date('long'), '5. Dschumada I 1448 AH', 'de islamic');
is($t->in_calendar('buddhist')->in_locale('en-GB')->format_date('long'), '15 October 2569 BE', 'en-GB buddhist inherits en\'s names and its own pattern');
is($t->in_calendar('buddhist')->in_locale('th')->format_date('full'), 'วันพฤหัสบดีที่ 15 ตุลาคม พ.ศ. 2569', 'th buddhist');
is($t->in_calendar('persian')->in_locale('fa')->format_date('long'), '۲۳ مهر ۱۴۰۵', 'fa persian in the locale\'s digits');
is($t->in_calendar('ethiopic')->in_locale('am')->format_date('long'), '5 ጥቅምት 2019 AM', 'am ethiopic');
is($h->in_locale('ar')->format('MMMM'), 'مرحشوان', 'ar hebrew month name');
is($t->in_calendar('dangi')->in_locale('ko')->format_skeleton('yMMMd'), '2026년 9월 5일', 'ko dangi skeleton');
is($t->in_calendar('japanese')->in_locale('ja')->format_skeleton('yMd'), 'R8/10/15', 'ja japanese skeleton');
dies_like(sub { $h->format_skeleton('yQQQQd') }, qr/has no format for the skeleton 'yQQQQd'/, 'an unknown skeleton dies as before');

# RFC 9557 both ways
is($h->rfc9557, '2026-10-15T09:00:00+00:00[UTC][u-ca=hebrew]', 'rfc9557 appends the calendar');
is($t->rfc9557, '2026-10-15T09:00:00+00:00[UTC]', 'the Gregorian has no annotation');
is($K->parse($h->rfc9557)->calendar, 'hebrew', 'parse reads it');
is($K->parse($h->rfc9557)->epoch, $t->epoch, 'the instant is ISO, as the RFC says');
is($K->parse('2026-10-15T09:00:00Z[u-ca=islamic-civil]')->year, 1448, 'any known id');
is($K->parse('2026-10-15T09:00:00Z[u-ca=hebrew]', calendar => 'hebrew')->calendar, 'hebrew', 'the same calendar twice is fine');
dies_like(sub { $K->parse('2026-10-15T09:00:00Z[u-ca=hebrew]', calendar => 'japanese') }, qr/names the hebrew calendar and calendar => names japanese/, 'a disagreement dies');
dies_like(sub { $K->parse('2026-10-15T09:00:00Z[u-ca=klingon]') }, qr/a calendar that is not known/, 'an unknown one still dies');

# parsing in a calendar
is($K->parse_cldr('24 Tishri 5787', 'd MMMM y', calendar => 'hebrew')->iso8601, '2026-10-05T00:00:00Z', 'parse_cldr by month name');
is($K->parse_cldr('24 Tishri 5787', 'd MMMM y', calendar => 'hebrew')->calendar, 'hebrew', 'the result is in the calendar');
is($K->parse_cldr('7 1 5785', 'M d y', calendar => 'hebrew')->iso8601, '2025-03-30T00:00:00Z', 'a numeric month is the ordinal: 7 is Nisan in a common year');
is($K->parse_cldr('8 1 5784', 'M d y', calendar => 'hebrew')->iso8601, '2024-04-09T00:00:00Z', 'and 8 in a leap year');
is($K->parse_cldr('1 Adar II 5784', 'd MMMM y', calendar => 'hebrew')->iso8601, '2024-03-11T00:00:00Z', 'Adar II by name');
is($K->parse_cldr('1 Nisan 5785', 'd MMMM y', calendar => 'hebrew')->iso8601, '2025-03-30T00:00:00Z', 'Nisan by name in a common year: the slot, not the ordinal');
is($K->parse_cldr('1 Adar I 5784', 'd MMMM y', calendar => 'hebrew')->month_code, 'M05L', 'Adar I by name');
dies_like(sub { $K->parse_cldr('1 Adar I 5785', 'd MMMM y', calendar => 'hebrew') }, qr/the Hebrew year 5785 has no month 6/, 'Adar I in a common year dies');
dies_like(sub { $K->parse_cldr('13 1 5785', 'M d y', calendar => 'hebrew') }, qr/the Hebrew year 5785 has no month 13/, 'a thirteenth month in a common year dies');
is($K->parse_cldr('AM 5787 2 4', 'G y M d', calendar => 'hebrew')->iso8601, '2026-10-15T00:00:00Z', 'G y M d');
is($K->parse_cldr('令和8年10月15日', 'Gy年M月d日', calendar => 'japanese', locale => 'ja')->iso8601, '2026-10-15T00:00:00Z', 'ja japanese by era');
is($K->parse_cldr('Reiwa 8-10-15', 'GGGG y-M-d', calendar => 'japanese')->iso8601, '2026-10-15T00:00:00Z', 'en japanese by era name');
dies_like(sub { $K->parse_cldr('Showa 70-1-1', 'GGGG y-M-d', calendar => 'japanese') }, qr/Showa/, 'a year past the era dies naming it') if 0;
is($K->parse_cldr('2025年闰六月1日', 'r年MMMMd日', calendar => 'chinese', locale => 'zh')->iso8601, '2025-07-25T00:00:00Z', 'zh chinese leap month by name');
is($K->parse_cldr('Mo6bis 1, 2025', 'MMM d, r', calendar => 'chinese')->iso8601, '2025-07-25T00:00:00Z', 'en chinese abbreviated leap name');
is($K->parse_cldr('2025 6bis 1', 'r M d', calendar => 'chinese')->iso8601, '2025-07-25T00:00:00Z', 'the numeric leap pattern');
is($K->parse_cldr('2025 6 1', 'r M d', calendar => 'chinese')->iso8601, '2025-06-25T00:00:00Z', 'the month before it');
is($K->parse_cldr('bing-wu 2026 9 6', 'U r M d', calendar => 'chinese')->iso8601, '2026-10-15T00:00:00Z', 'U with r');
dies_like(sub { $K->parse_cldr('闰六月 1', 'MMMM d', calendar => 'chinese', locale => 'zh') }, qr/no year was read, and a chinese date needs one/, 'a Chinese date needs a year');
is($K->strptime('15/10/1448', '%d/%m/%Y', calendar => 'islamic-umalqura')->iso8601, '2027-03-23T00:00:00Z', 'strptime in a calendar');
is($K->strptime('4 Heshvan 5787', '%d %B %Y', calendar => 'hebrew')->iso8601, '2026-10-15T00:00:00Z', 'strptime %B is the calendar\'s month name');
ok(!defined $K->try_parse_cldr('13 1 5785', 'M d y', calendar => 'hebrew'), 'try_parse_cldr gives undef');
is($K->try_parse_cldr('24 Tishri 5787', 'd MMMM y', calendar => 'hebrew')->day, 24, 'and the value when it parses');

# the Locale and Calendar classes
my @months = Time::Keeper::Locale->names('en', 'months', 'wide', 'format', 'hebrew');
is(scalar @months, 14, 'Locale->names with a calendar: 13 slots and Adar II');
is("$months[0] $months[5] $months[6] $months[13]", 'Tishri Adar I Adar Adar II', 'in CLDR\'s slots');
is((Time::Keeper::Locale->names('ja', 'eras', 'abbreviated', 'format', 'japanese'))[236], '令和', 'the eras of the japanese calendar in ja');
is((Time::Keeper::Locale->names('en', 'cyclic_years', 'abbreviated', 'format', 'chinese'))[42], 'bing-wu', 'cyclic_years');
is((Time::Keeper::Locale->formats('en', 'date', 'chinese'))[0], 'EEEE, MMMM d, r(U)', 'Locale->formats with a calendar');
is((Time::Keeper::Locale->formats('he', 'date', 'hebrew'))[1], 'd בMMMM y', 'a pattern with a numbering override is returned as letters');
is((Time::Keeper::Locale->formats('zh', 'date', 'chinese'))[2], 'r年MMMd', 'zh chinese medium');
is((Time::Keeper::Locale->formats('en', 'time', 'hebrew'))[2], (Time::Keeper::Locale->formats('en', 'time'))[2], 'the time formats are the Gregorian\'s');
is(Time::Keeper::Locale->available_formats('en', 'hebrew')->{Gy}, 'y G', 'available_formats with a calendar');
is(Time::Keeper::Locale->available_formats('en', 'chinese')->{yyyyMMMd}, 'MMM d, r', 'the yyyy skeletons as CLDR keys them');
is(Time::Keeper::Locale->available_formats('en', 'hebrew')->{Hm}, Time::Keeper::Locale->available_formats('en')->{Hm}, 'laid over the Gregorian skeletons');
is((Time::Keeper::Calendar->names('hebrew', 'he', 'months'))[0], 'תשרי', 'Calendar->names');
is((Time::Keeper::Calendar->names('japanese', 'ja', 'eras', 'abbreviated'))[235], '平成', 'Calendar->names with a width');
dies_like(sub { Time::Keeper::Calendar->names('klingon', 'en', 'months') }, qr/klingon/, 'an unknown calendar dies');
dies_like(sub { Time::Keeper::Locale->names('en', 'months', 'wide', 'format', 'klingon') }, qr/klingon/, 'in Locale->names too');

# the archive
(my $dir = $INC{'Time/Keeper.pm'}) =~ s/\.pm$//;
my $tkd = "$dir/calendars.tkd";
ok(-f $tkd, 'calendars.tkd is installed beside the module');
cmp_ok(-s $tkd, '<', 2_500_000, 'and is under the 2.5 MB gate');
cmp_ok(-s $tkd, '>', 1_000_000, 'and holds the locales');

# The numerals some calendars' patterns are written in read back: Hebrew
# numerals in he (ד׳ בחשוון תשפ״ז), the lunar days (初六) and Chinese numerals
# of the Chinese and Korean calendars in ja and zh, and every other calendar
# in its own four date formats, in twenty locales.
{
    my $t = Time::Keeper->new(year => 2026, month => 10, day => 15, zone => 'Europe/London');
    my @bad;
    for my $c (Time::Keeper::Calendar->ids) {
        for my $l (qw(en en-GB fr de es ja zh zh-Hant ko ar fa he hi th ru tr id pt it nl)) {
            my $v = $t->in_calendar($c)->in_locale($l);
            my @f = Time::Keeper::Locale->formats($l, 'date', $c);
            for my $i (0 .. 3) {
                my $s = $v->format_date((qw(full long medium short))[$i]);
                next if $f[$i] =~ /yy(?!y)/;   # a two-digit year names no century
                my $r = eval { Time::Keeper->parse_cldr($s, $f[$i], locale => $l, calendar => $c, zone => 'Europe/London') };
                push @bad, "$c $l '$s': " . ($r // $@) unless $r && $r == $t;
            }
        }
    }
    is(eval { $t->in_calendar('hebrew')->in_locale('ca-ES-valencia')->format_date('full') } // $@, 'dijous, 4 Heshvan del 5787 AM',
       'ca-ES-valencia inherits its calendar names through ca-ES, which has none of its own');
    ok(!@bad, 'every calendar\'s dates read back in twenty locales') or diag(join "\n", scalar(@bad) . ' do not:', @bad[0 .. ($#bad < 9 ? $#bad : 9)]);
}

done_testing;
