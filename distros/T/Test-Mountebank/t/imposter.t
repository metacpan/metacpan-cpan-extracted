#!/usr/bin/env perl -w

use strict;
use Test::More;
use Test::Deep;
use Test::Mountebank::Imposter;
use JSON::Tiny qw(decode_json);

my $imposter = Test::Mountebank::Imposter->new( port => 4546 );

$imposter->stub->predicate(
    path => "/test",
)->response(
    status_code => 404,
    headers => {
        Content_Type => "text/html"
    },
    body => 'ERROR'
);

my $expect_json = {
    port => 4546,
    protocol => 'http',
    stubs => [
        {
            responses => [
                {
                    is => {
                        statusCode => 404,
                        headers => {
                            "Content-Type" => "text/html"
                        },
                        body => 'ERROR'
                    }
                }
            ],
            predicates => [
                {
                    equals => {
                        path => "/test",
                    }
                }
            ]
        }
    ]
};

cmp_deeply( decode_json($imposter->as_json), $expect_json );
done_testing();
