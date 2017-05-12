use strict;
use warnings;
use utf8;
use Test::More;

use Time::Piece::Plus;
use Time::Seconds;

my $sometime = "2011-11-26 01:15:20";
my $datetime_format = "%Y-%m-%d %H:%M:%S";
my $time = Time::Piece::Plus->strptime($sometime, $datetime_format);

subtest original => sub {
    my $added = $time->add(10);
    is($added->strftime($datetime_format) => "2011-11-26 01:15:30", "correctly added");
};

subtest add_days => sub {
    my $added = $time->add(days => 1);
    is($added->strftime($datetime_format) => "2011-11-27 01:15:20", "correctly added");
};

subtest add_month => sub {
    my $added = $time->add(months => 1);
    is($added->strftime($datetime_format) => "2011-12-26 01:15:20", "correctly added");
};

subtest add_year => sub {
    my $added = $time->add(years => 1);
    is($added->strftime($datetime_format) => "2012-11-26 01:15:20", "correctly added");
};

subtest add_all => sub {
    my $added = $time->add(years => 1, months => 1, days => 1, hours => 1, seconds => 1, minutes => 1);
    is($added->strftime($datetime_format) => "2012-12-27 02:16:21", "correctly added");
};

subtest add_number => sub {
    my $added = $time + 10;
    $added    = 10 + $added;

    is($added->strftime($datetime_format) => "2011-11-26 01:15:40", "correctly added");
};

subtest add_time_second => sub {
    my $seconds = Time::Seconds->new(10);
    my $added = $time + $seconds;

    is($added->strftime($datetime_format) => "2011-11-26 01:15:30", "correctly added");
};

done_testing;
