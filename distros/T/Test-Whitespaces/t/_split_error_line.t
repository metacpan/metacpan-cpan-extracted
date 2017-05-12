#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use open qw(:std :utf8);

use Test::More;

use Test::Whitespaces { _only_load => 1 };

my @tests = (
    {
        line => "a \n",
        expected => [
            {
                status => 'correct',
                text => 'a',
            },
            {
                status => 'error',
                text => '_',
            },
            {
                status => 'correct',
                text => '\n',
            },
        ],
    },
    {
        line => "\trun_it(); \n",
        expected => [
            {
                status => 'error',
                text => '\t',
            },
            {
                status => 'correct',
                text => 'run_it();',
            },
            {
                status => 'error',
                text => '_',
            },
            {
                status => 'correct',
                text => '\n',
            },
        ],
    },
    {
        line => "a\t\trun_it(); \r\n",
        expected => [
            {
                status => 'correct',
                text => 'a',
            },
            {
                status => 'error',
                text => '\t\t',
            },
            {
                status => 'correct',
                text => 'run_it();',
            },
            {
                status => 'error',
                text => '_\r',
            },
            {
                status => 'correct',
                text => '\n',
            },
        ],
    },
    {
        line => "1; ",
        expected => [
            {
                status => 'correct',
                text => '1;',
            },
            {
                status => 'error',
                text => '_',
            },
        ],
    },
    {
        line => "\t1\n",
        expected => [
            {
                status => 'error',
                text => '\t',
            },
            {
                status => 'correct',
                text => '1\n',
            },
        ],
    },
);

foreach my $t (@tests) {
    my @splited_line = Test::Whitespaces::_split_error_line($t->{line});
    is_deeply(
        \@splited_line,
        $t->{expected},
        '_split_error_line()',
    );
}

done_testing();
