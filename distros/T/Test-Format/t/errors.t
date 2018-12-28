use strict;
use warnings FATAL => 'all';

use utf8;
use open qw(:std :utf8);

use Test::More tests => 9;
use Test::Format;

my @tests = (
    {
        opts => [],
        expected_error => qr/Must specify opts/,
    },
    {
        opts => [1],
        expected_error => qr/There must be key-value pairs/,
    },
    {
        opts => [1 => 2],
        expected_error => qr/Unknown opts: 1/,
    },
    {
        opts => [files => []],
        expected_error => qr/'files' can't be an empty array/,
    },
    {
        opts => [files => ['a.txt']],
        expected_error => qr/Must specify 'format' or 'format_sub'/,
    },
    {
        opts => [files => ['a.txt'], format => 'pretty_json', format_sub => sub {}],
        expected_error => qr/Can't specify both 'format' and 'format_sub'/,
    },
    {
        opts => [files => ['a.txt'], format => undef],
        expected_error => qr/Must specify 'format' or 'format_sub'/,
    },
    {
        opts => [files => ['a.txt'], format => 'NNN'],
        expected_error => qr/Unknown value for 'format' opt: 'NNN'/,
    },
    {
        opts => [files => ['a.txt'], format_sub => 'sub'],
        expected_error => qr/'format_sub' must be sub/,
    },
);

foreach my $test (@tests) {
    eval {
        test_format(@{$test->{opts}});
    };

    like($@, $test->{expected_error}, $test->{expected_error});
}
