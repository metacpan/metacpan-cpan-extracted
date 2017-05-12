#!/usr/bin/env perl

use strict;
use warnings;

use Test::Most;
use URI::redis;

sub test_methods {
    my ($uri, @tests) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    while ( my ($method, $expected_value) = splice @tests, 0, 2 ) {
        is $uri->$method, $expected_value, "$method is correct";
    }
}

subtest "scheme: 'redis://', password: userinfo, database: path" => sub {
    my $uri = URI->new('redis://:testpassword@redis.example.com:1234/5');

    test_methods($uri,
        scheme                 => 'redis',
        password               => 'testpassword',
        password_from_userinfo => 'testpassword',
        password_from_query    => undef,
        host                   => 'redis.example.com',
        port                   => 1234,
        socket_path            => undef,
        database               => 5,
        database_from_path     => 5,
        database_from_query    => undef,
    );
};

subtest "scheme: 'redis://', password: query, database: path" => sub {
    my $uri = URI->new(
        'redis://redis.example.com:1234/5?password=testpassword');

    test_methods($uri,
        scheme                 => 'redis',
        password               => 'testpassword',
        password_from_userinfo => undef,
        password_from_query    => 'testpassword',
        host                   => 'redis.example.com',
        port                   => 1234,
        socket_path            => undef,
        database               => 5,
        database_from_path     => 5,
        database_from_query    => undef,
    );
};

subtest "scheme: 'redis://', password: query, database: query" => sub {
    my $uri = URI->new(
        'redis://redis.example.com:1234?password=testpassword&db=5');

    test_methods($uri,
        scheme                 => 'redis',
        password               => 'testpassword',
        password_from_userinfo => undef,
        password_from_query    => 'testpassword',
        host                   => 'redis.example.com',
        port                   => 1234,
        socket_path            => undef,
        database               => 5,
        database_from_path     => undef,
        database_from_query    => 5,
    );
};

subtest "scheme: 'redis://', password: userinfo, database: query" => sub {
    my $uri = URI->new('redis://:testpassword@redis.example.com:1234?db=5');

    test_methods($uri,
        scheme                 => 'redis',
        password               => 'testpassword',
        password_from_userinfo => 'testpassword',
        password_from_query    => undef,
        host                   => 'redis.example.com',
        port                   => 1234,
        socket_path            => undef,
        database               => 5,
        database_from_path     => undef,
        database_from_query    => 5,
    );
};

subtest "scheme: 'redis://', defaults" => sub {
    my $uri = URI->new('redis://');

    test_methods($uri,
        scheme                 => 'redis',
        password               => undef,
        password_from_userinfo => undef,
        password_from_query    => undef,
        host                   => 'localhost',
        port                   => 6379,
        socket_path            => undef,
        database               => 0,
        database_from_path     => undef,
        database_from_query    => undef,
    );
};


subtest "scheme: 'redis+unix://', password: userinfo, database: query" => sub {
    my $uri = URI->new('redis+unix://:testpassword@/tmp/redis.sock?db=5');

    test_methods($uri,
        scheme                 => 'redis+unix',
        password               => 'testpassword',
        password_from_userinfo => 'testpassword',
        password_from_query    => undef,
        host                   => undef,
        port                   => undef,
        socket_path            => '/tmp/redis.sock',
        database               => 5,
        database_from_path     => undef,
        database_from_query    => 5,
    );
};

subtest "scheme: 'redis+unix://', password: query, database: query" => sub {
    my $uri = URI->new(
        'redis+unix:///tmp/redis.sock?password=testpassword&db=5');


    test_methods($uri,
        scheme                 => 'redis+unix',
        password               => 'testpassword',
        password_from_userinfo => undef,
        password_from_query    => 'testpassword',
        host                   => undef,
        port                   => undef,
        socket_path            => '/tmp/redis.sock',
        database               => 5,
        database_from_path     => undef,
        database_from_query    => 5,
    );
};

subtest "scheme: 'redis+unix://', defaults" => sub {
    my $uri = URI->new('redis+unix:///tmp/redis.sock');

    test_methods($uri,
        scheme                 => 'redis+unix',
        password               => undef,
        password_from_userinfo => undef,
        password_from_query    => undef,
        host                   => undef,
        port                   => undef,
        socket_path            => '/tmp/redis.sock',
        database               => 0,
        database_from_path     => undef,
        database_from_query    => undef,
    );
};


done_testing;
