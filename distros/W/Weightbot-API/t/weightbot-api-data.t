#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use Test::More tests => 2;

use_ok( 'Weightbot::API' );

my $data = 'date, kilograms, pounds
2008-12-04, 80.9, 178.4
2008-12-05, 82.6, 182.1
2008-12-06, 81.9, 180.6
2008-12-08, 82.6, 182.1';

my $expected_result = [
    {
        'n' => 1,
        'date' => '2008-12-04',
        'kg' => '80.9',
        'lb' => '178.4'
    },
    {
        'n' => 2,
        'date' => '2008-12-05',
        'kg' => '82.6',
        'lb' => '182.1'
    },
    {
        'n' => 3,
        'date' => '2008-12-06',
        'kg' => '81.9',
        'lb' => '180.6'
    },
    {
        'n' => 4,
        'date' => '2008-12-07',
        'kg' => '',
        'lb' => ''
    },
    {
        'n' => 5,
        'date' => '2008-12-08',
        'kg' => '82.6',
        'lb' => '182.1'
    },
];

my $wi = Weightbot::API->new({
    email    => 'aa@example.com',
    password => '******',
    raw_data => $data,
});

is_deeply($wi->data, $expected_result, 'data()');
