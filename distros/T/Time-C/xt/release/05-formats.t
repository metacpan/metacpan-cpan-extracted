#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

plan tests => 9589;

use Time::C;
use Time::P;
use Time::F;

my $year = 2016;
foreach my $fmt (qw/ %C-%y %Y %y %G-%V-%w %g-%V-%w /) {
    my $t = Time::C->new($year)->day_of_year(1)->second_of_day(0);
    my $str = strftime($t, $fmt);
    note $str;
    my $t2 = Time::C->strptime($str, $fmt);

    is ($t2, $t, "Format $fmt processed correctly");
}

foreach my $sec (qw/
     0      10     30     60     70     90    120
   300     310    330    360    370    390
  1800    1810   1830   1860   1870          1920
  2100
  3600    3610   3630                        3720
  3900    3910   3930          3970   3990
 18000   18010  18030  18060  18070  18090  18120
 43200   43210  43230  43260  43270  43290  43320
 57600   57610  57630  57660  57670  57690  57720
/) {
    foreach my $fmt (qw/ %B %b %H %I-%p %k %l-%p %M %S %T %n- %n %t- %t %X %R %r /) {
        my $t = Time::C->new($year)->day_of_year(1)->second_of_day($sec);
        my $format = "%Y: $fmt";
        my $str = strftime($t, $format);
        note $str;
        my $t2 = Time::C->strptime($str, $format);
        my $str2 = strftime($t2, $format);

        is ($str2, $str, "Format $fmt processed correctly") or diag "$t -> ($fmt) -> $str -> $t2";
    }
}

foreach my $day (1 .. 366) {

    foreach my $fmt (qw/ %F %x %v /) {
        my $t = Time::C->new($year)->day_of_year($day)->second_of_day(0);
        my $str = strftime($t, $fmt);
        note $str;
        my $t2 = Time::C->strptime($str, $fmt);
        
        is ($t2, $t, "Format $fmt processed correctly");
    }

    foreach my $fmt (qw/ %W-%A %W-%a %c %m-%d %m-%e %j %s %U-%u %U-%w %V-%u %V-%w %W-%u %W-%w /) {
        my $t = Time::C->new($year)->day_of_year($day)->second_of_day(0);
        my $format = "%Y: $fmt";
        my $str = strftime($t, $format);
        note $str;
        my $t2 = Time::C->strptime($str, $format);

        is ($t2, $t, "Format $fmt processed correctly") or diag "$t -> ($fmt) -> $str -> $t2";
    }
    foreach my $fmt (qw / %Y:%W-%A %Y:%W-%a %Y:%U-%u %Y:%U-%w %G:%V-%u %G:%V-%w %Y:%W-%u %Y:%W-%w /) {
        my $t = Time::C->new($year)->day_of_year($day)->second_of_day(0);
        my $str = strftime($t, $fmt);
        note $str;
        my $t2 = Time::C->strptime($str, $fmt);

        is ($t2, $t, "Format $fmt processed correctly") or diag "$t -> ($fmt) -> $str -> $t2";
    }
}

#done_testing;
