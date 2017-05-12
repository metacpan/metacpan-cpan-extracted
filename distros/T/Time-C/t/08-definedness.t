#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More;

plan tests => 228;

use Time::C;

sub in {
    my ($needle, @haystack) = @_;
    foreach my $straw (@haystack) { return 1 if $straw eq $needle; }
    return 0;
}

sub check_d {
    my $obj  = shift;
    my $name = shift;
    my @true = @_;
    my @keys = qw/ epoch_d year month mday week wday yday hour minute second offset tz_d /;

    for my $key (@keys) {
        if (in($key, @true)) {
            is ($obj->{$key}, 1, "$key true - $name");
        } else {
            is ($obj->{$key} + 0, 0, "$key false - $name");
        }
    }
}

my $t = Time::C->new();
check_d $t, "new";

$t->second = 0;
check_d $t, "second set", qw/ second /;

$t->minute = 0;
check_d $t, "minute set", qw/ second minute /;

$t->hour = 0;
check_d $t, "hour set", qw/ second minute hour /;

$t->year = 2016;
check_d $t, "year set", qw/ second minute hour year /;

$t->month = 1;
check_d $t, "month set", qw/ second minute hour year month /;

$t->day = 1;
check_d $t, "day set", qw/ second minute hour year month mday /;

$t->week = 2;
check_d $t, "week set", qw/ second minute hour year month mday week /;

$t->day_of_week = 1;
check_d $t, "wday set", qw/ second minute hour year month mday week wday /;

$t->day_of_year = 30;
check_d $t, "yday set", qw/ second minute hour year month mday week wday yday /;

$t->offset = 0;
check_d $t, "offset set", qw/ second minute hour year month mday week wday yday offset /;

$t->tz = 'UTC';
check_d $t, "tz set", qw/ second minute hour year month mday week wday yday offset tz_d /;

$t->epoch++;
check_d $t, "epoch set", qw/ second minute hour year month mday week wday yday offset tz_d epoch_d /;

my $t2 = Time::C->new();

$t2->second_of_day = 0;
check_d $t2, "second_of_day set", qw/ second minute hour /;

$t2->day_of_year = 1;
check_d $t2, "day_of_year set", qw/ second minute hour yday /;

my $t3 = Time::C->strptime("mån 31 okt 2016", "%a %d %b %Y", locale => "sv_SE");
check_d $t3, "strptime month/mday/year set", qw/ month mday year /;

$t3->tm = $t3->tm;
check_d $t3, "tm set", qw/ epoch_d month mday year week wday yday second minute hour /;

my $t4 = Time::C->strptime("mån vecka 3 2016", "%a vecka %-V %G", locale => "sv_SE");
check_d $t4, "strptime week/wday/year set", qw/ week wday year /;

$t4->strptime("16:04:48", "%T");
check_d $t4, "strptime time set", qw/ week wday year hour minute second /;

#done_testing;
