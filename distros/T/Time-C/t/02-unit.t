use strict;
use warnings;
use utf8;

use Test::More tests => 71;

use Time::Moment;
use Time::C;

my $t_new = Time::C->new(2012, 12, 24, 15, 30, 45);
isa_ok($t_new, 'Time::C');
is($t_new->string, "2012-12-24T15:30:45Z", 'new constructor correct');

my $t_now = Time::C->now();
isa_ok($t_now, 'Time::C');
like($t_now->string, qr/^\d+-\d+-\d+T\d+:\d+:\d+/, 'now constructor probably correct');

my $t_now_utc = Time::C->now_utc();
isa_ok($t_now_utc, 'Time::C');
like($t_now_utc->string, qr/^\d+-\d+-\d+T\d+:\d+:\d+Z$/, 'now_utc constructor probably correct');

my $t_string = Time::C->from_string("2016-09-23T04:55:13Z");
isa_ok($t_string, 'Time::C');
is($t_string->string, "2016-09-23T04:55:13Z", 'from_string constructor correct');

my $t = $t_string;

is("$t", $t_string->string, 'stringifies correctly');

is($t->year, '2016', 'initial year correct');
$t->year = 2017;
is($t->string, "2017-09-23T04:55:13Z", 'setting year correct');
$t->year++;
is($t->string, "2018-09-23T04:55:13Z", 'incrementing year correct');
$t->year--;
is($t->string, "2017-09-23T04:55:13Z", 'decrementing year correct');
$t->year += 3;
is($t->string, "2020-09-23T04:55:13Z", 'incrementing year by 3 correct');
$t->year -= 40;
is($t->string, "1980-09-23T04:55:13Z", 'decrementing year by 40 correct');

is($t->quarter, '3', 'initial quarter correct');
$t->quarter = 1;
is($t->string, "1980-03-23T04:55:13Z", 'setting quarter correct');
$t->quarter++;
is($t->string, "1980-06-23T04:55:13Z", 'incrementing quarter correct');
$t->quarter--;
is($t->string, "1980-03-23T04:55:13Z", 'decrementing quarter correct');
$t->quarter += 3;
is($t->string, "1980-12-23T04:55:13Z", 'incrementing quarter by 5 correct');
$t->quarter -= 1;
is($t->string, "1980-09-23T04:55:13Z", 'decrementing quarter by 2 correct');

is($t->month, '9', 'initial month correct');
$t->month = 2;
is($t->string, "1980-02-23T04:55:13Z", 'setting month correct');
$t->month++;
is($t->string, "1980-03-23T04:55:13Z", 'incrementing month correct');
$t->month--;
is($t->string, "1980-02-23T04:55:13Z", 'decrementing month correct');
$t->month += 14;
is($t->string, "1981-04-23T04:55:13Z", 'incrementing month by 14 correct');
$t->month -= 2;
is($t->string, "1981-02-23T04:55:13Z", 'decrementing month by 2 correct');

is($t->week, '9', 'initial week correct');
$t->week = 5;
is($t->string, "1981-01-26T04:55:13Z", 'setting week correct');
$t->week++;
is($t->string, "1981-02-02T04:55:13Z", 'incrementing week correct');
$t->week--;
is($t->string, "1981-01-26T04:55:13Z", 'decrementing week correct');
$t->week += 15;
is($t->string, "1981-05-11T04:55:13Z", 'incrementing week by 15 correct');
$t->week -= 11;
is($t->string, "1981-02-23T04:55:13Z", 'decrementing week by 11 correct');

is($t->day, '23', 'initial day correct');
$t->day = 20;
is($t->string, "1981-02-20T04:55:13Z", 'setting day correct');
$t->day++;
is($t->string, "1981-02-21T04:55:13Z", 'incrementing day correct');
$t->day--;
is($t->string, "1981-02-20T04:55:13Z", 'decrementing day correct');
$t->day += 10;
is($t->string, "1981-03-02T04:55:13Z", 'incrementing day by 10 correct');
$t->day -= 3;
is($t->string, "1981-02-27T04:55:13Z", 'decrementing day by 3 correct');

is($t->day_of_month, '27', 'initial day_of_month correct');
$t->day_of_month = 13;
is($t->string, "1981-02-13T04:55:13Z", 'setting day_of_month correct');
$t->day_of_month++;
is($t->string, "1981-02-14T04:55:13Z", 'incrementing day_of_month correct');
$t->day_of_month--;
is($t->string, "1981-02-13T04:55:13Z", 'decrementing day_of_month correct');
$t->day_of_month += 20;
is($t->string, "1981-03-05T04:55:13Z", 'incrementing day_of_month by 20 correct');
$t->day_of_month -= 5;
is($t->string, "1981-02-28T04:55:13Z", 'decrementing day_of_month by 5 correct');

is($t->day_of_year, '59', 'initial day_of_year correct');
$t->day_of_year = 80;
is($t->string, "1981-03-21T04:55:13Z", 'setting day_of_year correct');
$t->day_of_year++;
is($t->string, "1981-03-22T04:55:13Z", 'incrementing day_of_year correct');
$t->day_of_year--;
is($t->string, "1981-03-21T04:55:13Z", 'decrementing day_of_year correct');

is($t->day_of_quarter, '80', 'initial day_of_quarter correct');
$t->day_of_quarter = 32;
is($t->string, "1981-02-01T04:55:13Z", 'setting_day_of_quarter correct');
$t->day_of_quarter++;
is($t->string, "1981-02-02T04:55:13Z", 'incrementing day_of_quarter correct');

is($t->day_of_week, '1', 'initial day_of_week correct');
$t->day_of_week = 3;
is($t->string, "1981-02-04T04:55:13Z", 'setting day_of_week correct');
$t->day_of_week++;
is($t->string, "1981-02-05T04:55:13Z", 'incrementing day_of_week correct');

is($t->hour, '4', 'initial hour correct');
$t->hour = 0;
is($t->string, "1981-02-05T00:55:13Z", 'setting hour correct');

is($t->minute, '55', 'initial minute correct');
$t->minute += 5;
is($t->string, "1981-02-05T01:00:13Z", 'incrementing minute by 5 correct');

is($t->second, '13', 'initial second correct');
$t->second -= 3613;
is($t->string, "1981-02-05T00:00:00Z", 'decrementing second by 3613 correct');

is($t->offset, '0', 'initial offset correct');
$t->offset = 120;
is($t->string, "1981-02-05T02:00:00+02:00", 'setting offset correct');

is($t->strftime(format => "%Y-%m-%d %T", locale => "en_GB", strict => 0),
    "1981-02-05 02:00:00", "passing arguments to ->strftime correct");
is ($t->strftime(), "1981-02-05T02:00:00+02:00", "passing no arguments to ->strftime correct");
is ($t->strftime("1980-03-03", format => "%Y-%m-%d"),
    "1980-03-03T02:00:00+02:00", "passing a new string and a format to ->strftime correct");
$t->strftime(format => "%Y-%m-%d") = "1990-05-06";
is ($t->string, "1990-05-06T02:00:00+02:00", "setting ->strftime with a format correct");
$t->strftime(format => "%a vecka %-W %Y", locale => "sv_SE") = "mån vecka 3 2016";
is ($t->string, "2016-01-18T02:00:00+02:00",
    "setting ->strftime with a format and a locale correct");
is (Time::C->strptime("mån 31 okt 2016 20:33:45", "%c", locale => "sv_SE")->strftime(format => "%c", locale => "ja_JP"),
    "2016年10月31日 20時33分45秒", "->strptime()->strftime with different locales correct");
my $str = Time::C->strptime("mån 31 okt 2016 20:33:45", "%c", locale => "sv_SE")->strftime(format => "%EY %m %d %X", locale => "ja_JP");
is ($str, "平成28年 10 31 20時33分45秒", "strftime with era correct");
is (Time::C->strptime("平成28年 10 31 20時33分45秒", "%EY %m %d %X", locale => "ja_JP")->strftime(format => "%c", locale => "sv_SE"),
    "mån 31 okt 2016 20:33:45", "strptime with era correct");
