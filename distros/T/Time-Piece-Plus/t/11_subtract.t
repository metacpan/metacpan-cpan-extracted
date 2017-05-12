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
    my $subtracted = $time->subtract(10);
    is($subtracted->strftime($datetime_format) => "2011-11-26 01:15:10", "correctly subtracted");
};

subtest subtract_days => sub {
    my $subtracted = $time->subtract(days => 1);
    is($subtracted->strftime($datetime_format) => "2011-11-25 01:15:20", "correctly subtracted");
};

subtest subtract_month => sub {
    my $subtracted = $time->subtract(months => 1);
    is($subtracted->strftime($datetime_format) => "2011-10-26 01:15:20", "correctly subtracted");
};

subtest subtract_year => sub {
    my $subtracted = $time->subtract(years => 1);
    is($subtracted->strftime($datetime_format) => "2010-11-26 01:15:20", "correctly subtracted");
};

subtest subtract_all => sub {
    my $subtracted = $time->subtract(years => 1, months => 1, days => 1, hours => 1, seconds => 1, minutes => 1);
    is($subtracted->strftime($datetime_format) => "2010-10-25 00:14:19", "correctly subtracted");
};

subtest subtract_number => sub {
    my $subtracted = $time - 10;

    is($subtracted->strftime($datetime_format) => "2011-11-26 01:15:10", "correctly subtracted");
};

subtest subtract_time_second => sub {
    my $seconds = Time::Seconds->new(10);
    my $subtracted = $time - $seconds;

    is($subtracted->strftime($datetime_format) => "2011-11-26 01:15:10", "correctly added");
};

subtest subtract_time_piece => sub {
    my $sometime = "2011-11-26 01:15:10";
    my $time2 =  Time::Piece::Plus->strptime($sometime, $datetime_format);

    my $seconds = $time - $time2;
    isa_ok $seconds, 'Time::Seconds';
    is $seconds->seconds, 10;
};

done_testing;
