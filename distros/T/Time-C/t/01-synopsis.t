use strict;
use warnings;
use utf8;

use Test::More;

plan tests => 46;

use Time::C;
use Time::D;
use Time::F;
use Time::P;
use Time::R;

# start with Time::C synopsis
my $t = Time::C->from_string('2016-09-23T04:28:30Z');
isa_ok($t, "Time::C");

is ($t->string, "2016-09-23T04:28:30Z", 'initial time correct');

# 2016-01-01T04:28:30Z
$t->month = $t->day = 1;
is ($t->string, "2016-01-01T04:28:30Z", 'setting month and day to 1 correct');
 
# 2016-01-01T00:00:00Z
$t->hour = $t->minute = $t->second = 0;
is ($t->string, "2016-01-01T00:00:00Z", 'setting hour, minute, second to 0 correct');
 
# 2016-02-04T00:00:00Z
$t->month += 1; $t->day += 3;
is ($t->string, "2016-02-04T00:00:00Z", 'increasing month by 1 and day by 3 correct');
 
# 2016-03-03T00:00:00Z
$t->day += 28;
is ($t->string, "2016-03-03T00:00:00Z", 'increasing day by 28 correct');

# print all days of the week (2016-02-29T00:00:00Z to 2016-03-06T00:00:00Z)
my @days;
$t->day_of_week = 1;
BLOCK: {
    do { push @days, "$t"; last BLOCK if @days > 10; } while $t->day_of_week++ < 7;
}
is (@days, 7, '@days has an entire week');
is ($days[0], "2016-02-29T00:00:00Z", 'first day of week correct');
is ($days[1], "2016-03-01T00:00:00Z", 'second day of week correct');
is ($days[2], "2016-03-02T00:00:00Z", 'third day of week correct');
is ($days[3], "2016-03-03T00:00:00Z", 'fourth day of week correct');
is ($days[4], "2016-03-04T00:00:00Z", 'fifth day of week correct');
is ($days[5], "2016-03-05T00:00:00Z", 'sixth day of week correct');
is ($days[6], "2016-03-06T00:00:00Z", 'seventh day of week correct');

# then Time::D synopsis
my $dstr = Time::D->new(time, time - 3600)->to_string();
is ($dstr, "1 hour ago", "initial diff correct");

is (Time::D->new(time)->to_string(), "now", "diff with no difference correct");

my $d = Time::D->new(Time::C->from_string("2016-09-29T20:06:03Z")->epoch);
isa_ok ($d, "Time::D");
$d->comp(Time::C->from_string("2000-01-01T00:00:00Z")->epoch);
is ($d->to_string(), "16 years, 8 months, 4 weeks, 20 hours, 6 minutes, and 3 seconds ago", "Time comparison to 2000-01-01T00:00:00Z correct");

$d->years = 0;
is ($d, "8 months, and 4 weeks ago", "setting years to 0 correct");

$d->months--;
is ($d, "7 months, and 4 weeks ago", "decrementing months correct");

is (Time::C->gmtime($d->comp)->string(), "2016-02-01T00:00:00Z", "comparison time correct");

# and now Time::F synopsis
my $str = strftime(Time::C->from_string("2016-10-31T14:21:57Z"), "%c", locale => "sv_SE");
is ($str, "mån 31 okt 2016 14:21:57", "strftime works correctly");

# and Time::P synopsis
my $p = Time::C->mktime(strptime("sön okt 30 16:07:34 UTC 2016", "%a %b %d %T %Z %Y", locale => "sv_SE"));
isa_ok($p, "Time::C");
is ($p, "2016-10-30T16:07:34Z", "strptime works correctly");

# and last Time::R
my $start = Time::C->new(2016,1,31);
my $r = Time::R->new($start, months => 1);
isa_ok($r, "Time::R");

is ($r->next(), "2016-02-29T00:00:00Z", "first recurrence correct");

is ($r->next(), "2016-03-31T00:00:00Z", "second recurrence correct");

$r->current = Time::C->new(2016,9,30);

my @until = $r->until(Time::C->new(2017,1,1));
is (@until, 4, 'Correct number of times in @until');
is ($until[0], "2016-09-30T00:00:00Z", 'First time in @until correct');
is ($until[1], "2016-10-31T00:00:00Z", 'Second time in @until correct');
is ($until[2], "2016-11-30T00:00:00Z", 'Third time in @until correct');
is ($until[3], "2016-12-31T00:00:00Z", 'Fourth time in @until correct');

is ($r->next(), "2017-01-31T00:00:00Z", "next after until correct");

my $m = Time::R->new(Time::C->new(2016), months => 1, end => Time::C->new(2017));
my @res;
while (my $n = $m->next()) {
  $n->day++ while $n->day_of_week != 4;
  push @res, $n->strftime(format => '%A %-d %B %Y'); #ex: Thursday 4 February 2016
}

is (@res, 12, "right number of thursdays in result");
is ($res[0], "Thursday 4 February 2016", "first thursday correct");
is ($res[1], "Thursday 3 March 2016", "second thursday correct");
is ($res[2], "Thursday 7 April 2016", "third thursday correct");
is ($res[3], "Thursday 5 May 2016", "fourth thursday correct");
is ($res[4], "Thursday 2 June 2016", "fifth thursday correct");
is ($res[5], "Thursday 7 July 2016", "sixth thursday correct");
is ($res[6], "Thursday 4 August 2016", "seventh thursday correct");
is ($res[7], "Thursday 1 September 2016", "eigth thursday correct");
is ($res[8], "Thursday 6 October 2016", "ninth thursday correct");
is ($res[9], "Thursday 3 November 2016", "tenth thursday correct");
is ($res[10], "Thursday 1 December 2016", "eleventh thursday correct");
is ($res[11], "Thursday 5 January 2017", "twelfth thursday correct");

#done_testing;
