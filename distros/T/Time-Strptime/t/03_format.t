use strict;

use Time::Strptime::Format;
use Test::More;

my %TEST_CASE = (
    '2014-01-01 01:23:45' => [
        {
            format => '%Y-%m-%d %H:%M:%S',
            result => [1388539425, 0],
        },
        {
            format => '%F %H:%M:%S',
            result => [1388539425, 0],
        },
        {
            format => '%Y-%m-%d %T',
            result => [1388539425, 0],
        },
        {
            format => '%F %T',
            result => [1388539425, 0],
        },
    ],
    '2014/01' => [
        {
            format => '%Y/%m',
            result => [1388534400, 0],
        },
    ],
    "[0-9]\t2014-01-01 [a-z] 01:23:45 [A-Z]" => [
        {
            format => '[0-9]%t%Y-%m-%d [a-z] %H:%M:%S [A-Z]',
            result => [1388539425, 0],
        },
        {
            format => '[0-9]%t%F [a-z] %H:%M:%S [A-Z]',
            result => [1388539425, 0],
        },
        {
            format => '[0-9]%t%Y-%m-%d [a-z] %T [A-Z]',
            result => [1388539425, 0],
        },
        {
            format => '[0-9]%t%F [a-z] %T [A-Z]',
            result => [1388539425, 0],
        },
    ],
    "20-Mar-2014" => [
        {
            format => "%e-%b-%Y",
            result => [1395273600, 0],
        },
        {
            format => "%d-%b-%Y",
            result => [1395273600, 0],
        },
        {
            format => "%v",
            result => [1395273600, 0],
        },
    ],
    "2014/03/20 AM12:00:00" => [
        {
            format => "%Y/%m/%d %p%I:%M:%S",
            result => [1395273600, 0],
        },
    ],
    "2014/03/20 AM01:00:00" => [
        {
            format => "%Y/%m/%d %p%I:%M:%S",
            result => [1395277200, 0],
        },
    ],
    "2014/03/20 PM12:00:00" => [
        {
            format => "%Y/%m/%d %p%I:%M:%S",
            result => [1395316800, 0],
        },
    ],
    "2014/03/20 PM01:00:00" => [
        {
            format => "%Y/%m/%d %p%I:%M:%S",
            result => [1395320400, 0],
        },
    ],
    "2014%079 (Thu)" => [
        {
            format => "%Y%%%j (%a)",
            result => [1395273600, 0],
        },
        {
            format => "%Y%%%j (%A)",
            result => [1395273600, 0],
        },
        {
            format => "%Y%%%j%n(%a)",
            result => [1395273600, 0],
        },
    ],
    "1395320400 +0000" => [
        {
            format => "%s %z",
            result => [1395320400, 0],
        },
    ],
    "1395320400 +0100" => [
        {
            format => "%s %z",
            result => [1395320400, 3600],
        },
    ],
    "1395320400 -0100" => [
        {
            format => "%s %z",
            result => [1395320400, -3600],
        },
    ],
    "2014-01-01T01:23:45Z" => [
        {
            format => "%FT%T%z",
            result => [1388539425, 0],
        },
    ],
    "2014-01-01T01:23:45+0900" => [
        {
            format => "%FT%T%z",
            result => [1388507025, 3600*9],
        },
    ],
    "2014-01-01T01:23:45-0900" => [
        {
            format => "%FT%T%z",
            result => [1388571825, -3600*9],
        },
    ],
    "2014-01-01 01:23:45 (Asia/Tokyo)" => [
        {
            format => "%F %T (%Z)",
            result => [1388507025, 3600*9],
        },
    ],
);

for my $str (keys %TEST_CASE) {
    subtest "String: $str" => sub {
        for my $wanted (@{ $TEST_CASE{$str} }) {
            my @result = Time::Strptime::Format->new($wanted->{format}, {
                time_zone => 'GMT',
                locale    => 'C',
            })->parse($str);
            is_deeply \@result, $wanted->{result}, "Format: $wanted->{format}"
                or diag "result: ".POSIX::strftime('%F %T', gmtime($result[0]));
        }
    };
}

done_testing;
