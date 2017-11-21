#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use YAHC;

subtest "yahc_terminal_error" => sub {
    cmp_ok(YAHC::yahc_terminal_error(0), '==', 0, '0 value is not terminal error');

    cmp_ok(
        YAHC::yahc_terminal_error(
            YAHC::Error::INTERNAL_ERROR()
        ),
        '==',
        0,
        'YAHC::Error::INTERNAL_ERROR() is not terminal error'
    );

    cmp_ok(
        YAHC::yahc_terminal_error(
            YAHC::Error::TERMINAL_ERROR()
        ),
        '==',
        1,
        'YAHC::Error::TERMINAL_ERROR() is terminal error'
    );

    cmp_ok(
        YAHC::yahc_terminal_error(
            YAHC::Error::TERMINAL_ERROR() | YAHC::Error::TERMINAL_ERROR()
        ),
        '==',
        1,
        'YAHC::Error::TERMINAL_ERROR() | YAHC::Error::TERMINAL_ERROR() is terminal error'
    );
};

subtest "yahc_conn_user_data" => sub {
    my $conn = {};
    is(YAHC::yahc_conn_user_data($conn), undef, 'user_data is undef at start');
    is(YAHC::yahc_conn_user_data($conn, 'test'), 'test', 'user_data contains "test"');
    YAHC::yahc_conn_user_data($conn, undef);
    is(YAHC::yahc_conn_user_data($conn), undef, 'user_data contains undef');
};

done_testing;
