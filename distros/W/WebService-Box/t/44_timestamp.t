#!/usr/bin/perl

use strict;
use warnings;

{
    package TimestampTest;

    use WebService::Box::Types::Library qw(Timestamp);
    use Moo;

    has date => (
        is     => 'ro',
        isa    => Timestamp,
        coerce => Timestamp()->coercion,
    );
}

use DateTime;
use Test::More;
use Test::Exception;

my $time_test_1 = TimestampTest->new(
    date => DateTime->new(
        day   => 13,
        month => 9,
        year  => 2013,
    ),
);

isa_ok $time_test_1, 'TimestampTest';

is $time_test_1->date->year, 2013, 'year';
is $time_test_1->date->month, 9, 'month';
is $time_test_1->date->day, 13, 'day';

my $time_test_2 = TimestampTest->new(
    date => '2013-09-13T13:34:12-02:00',
);

is $time_test_2->date->year, 2013, 'year (coerce)';
is $time_test_2->date->month, 9, 'month (coerce)';
is $time_test_2->date->day, 13, 'day (coerce)';
is $time_test_2->date->hour, 13, 'hour (coerce)';
is $time_test_2->date->minute, 34, 'minute (coerce)';
is $time_test_2->date->second, 12, 'second (coerce)';

done_testing();
