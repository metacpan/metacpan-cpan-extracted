use strict;
use warnings FATAL => 'all';

use utf8;
use open qw(:std :utf8);

use Test::More tests => 6;
use Test::Format;

my @tests = (
    {
        input => '{}',
        expected_output => "{}\n",
    },
    {
        input => '[]',
        expected_output => "[]\n",
    },
    {
        input => '{"b":2,"a":1}',
        expected_output => '{
    "a" : 1,
    "b" : 2
}
',
    },
    {
        input => '{"ГДЕ":2,"АБВ":1}',
        expected_output => '{
    "АБВ" : 1,
    "ГДЕ" : 2
}
',
    },
);

foreach my $test (@tests) {
    my $got = Test::Format::_pretty_json($test->{input});

    is($got, $test->{expected_output});
}

my @not_jsons = (
    '"asdf',
    '{]',
);

foreach my $string (@not_jsons) {
    eval {
        my $got = Test::Format::_pretty_json($string);
    };

    ok($@, "string '$string' is not valid");
}
