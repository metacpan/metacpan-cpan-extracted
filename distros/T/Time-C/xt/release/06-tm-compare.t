#!/usb/bin/env perl

use strict;
use warnings;

use Test::More;

plan tests => 9277;

use Time::C;
use Time::F;

foreach my $year (1990 .. 2016) {
    my $fmt = "%G: %W-%w";
    my $t = Time::C->new($year, 1, 1);
    my $str = strftime($t, $fmt);
    my $str2 = $t->tm->strftime($fmt);

    is ($str, $str2, "Format $fmt for $t - $str2 correct");
}

foreach my $year (1990 .. 2016) {
    my $fmt = "%G: %W-%w";
    my $t = Time::C->new($year, 1, 22);
    my $str = strftime($t, $fmt);
    my $str2 = $t->tm->strftime($fmt);

    is ($str, $str2, "Format $fmt for $t - $str2 correct");
}

my $year = 2016;
foreach my $fmt (qw/ %C-%y %Y %y %G-%W-%w %g-%W-%w /) {
    my $t = Time::C->new($year)->day_of_year(1)->second_of_day(0);
    my $str = strftime($t, $fmt);
    my $str2 = $t->tm->strftime($fmt);

    is ($str, $str2, "Format $fmt correct") or diag "Time: $t";
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
				my $str2 = $t->tm->strftime($format);

        is ($str2, $str, "Format $fmt processed correctly") or diag "Time: $t";
    }
}

foreach my $day (1 .. 366) {

    foreach my $fmt (qw/ %F %x /) {
        my $t = Time::C->new($year)->day_of_year($day)->second_of_day(0);
        my $str = strftime($t, $fmt);
				my $str2 = $t->tm->strftime($fmt);

        is ($str, $str2, "Format $fmt processed correctly") or diag "Time: $t";
    }

    foreach my $fmt (qw/ %W-%A %W-%a %c %m-%d %m-%e %j %s %U-%u %U-%w %V-%u %V-%w %W-%u %W-%w /) {
        my $t = Time::C->new($year)->day_of_year($day)->second_of_day(0);
        my $format = "%Y: $fmt";
        my $str = strftime($t, $format);
				my $str2 = $t->tm->strftime($format);

        is ($str, $str2, "Format $fmt processed correctly") or diag "Time: $t";
    }
    foreach my $fmt (qw / %W-%A %W-%a %U-%u %U-%w %V-%u %V-%w %W-%u %W-%w /) {
        my $t = Time::C->new($year)->day_of_year($day)->second_of_day(0);
        my $format = "%G: $fmt";
        my $str = strftime($t, $format);
				my $str2 = $t->tm->strftime($format);

        is ($str, $str2, "Format $format processed correctly") or diag "Time: $t";
    }
}

#done_testing;
