#!/usr/bin/env perl -w

use strict;
use Test::More;
use Test::Deep;
use Test::Mountebank::Predicate::Equals;
use JSON::Tiny qw(decode_json);

subtest 'full equals' => sub  {
    my $eq = Test::Mountebank::Predicate::Equals->new(
        method      => "POST",
        path        => "/test",
        query       => { first => "1", second => "2" },
        body        => "dummy body",
        requestFrom => "::ffff:127.0.0.1",
        headers     => {
            Content_Type => 'text/html; version=3.2',
        },
    );

    my $expect_json = {
        equals => {
            method => "POST",
            path => "/test",
            query => {
                first => "1",
                second => "2"
            },
            headers => {
                "Content-Type" => 'text/html; version=3.2',
            },
            body => "dummy body",
            requestFrom => "::ffff:127.0.0.1",
        }
    };

    cmp_deeply( $eq->as_hashref(), $expect_json );
};

subtest 'simple equals' => sub  {
    my $eq = Test::Mountebank::Predicate::Equals->new(
        path   => "/test",
    );

    my $expect_json = {
        equals => {
            path => "/test",
        }
    };

    cmp_deeply( $eq->as_hashref(), $expect_json );
};

done_testing();
