#!/usr/bin/perl
use lib 'lib';
use Time::Sequence;
use Test::More;
use Date::Calc qw/Mktime/;
use POSIX qw/strftime/;

my $lastday_this_hour = get_time(
    undef,
    format => "%04d-%02d-%02d %02d",
    delta  => { day => -1 },
);
print $lastday_this_hour, "\n";

my $time_10min_before = get_time(
    "2014-06-10 22:22:22",
    delta => {
        year   => 0,
        month  => 0,
        day    => 0,
        hour   => 0,
        minute => -10,
        second => 0,
    },
);
is( $time_10min_before, '2014-06-10 22:12:22', 'get_time : 10min before' );

my $seq = seq_times(
    "2014-06-11 07:15:22", "2014-06-11 12:00:00",
    delta    => { minute => 30 },
    format   => "%04d-%02d-%02d %02d:%02d",
    trim_end => 0,
);
is( $seq->[-2], '2014-06-11 11:45', 'seq_times' );
print "$_\n" for @$seq;

my $c = cut_time( "2014-06-11 09:33", $seq );
is( $c, '2014-06-11 09:15', 'cut_time' );
print $c, "\n";

done_testing;
