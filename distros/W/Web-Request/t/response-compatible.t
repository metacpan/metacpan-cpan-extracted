#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Web::Response;

{
    my $res = Web::Response->new;
    $res->status(200);
    $res->header("Foo\000Bar" => "baz");
    $res->header("Qux\177Quux" => "42");
    $res->content("Hello");

    is_deeply $res->finalize, [ 200, [ "Foo\000Bar" => 'baz', "Qux\177Quux" => '42' ], ["Hello"] ];
}

{
    my $res = Web::Response->new;
    $res->status(200);
    $res->header("X-LWS-I"  => "Bar\r\n  true");
    $res->header("X-LWS-II" => "Bar\r\n\t\ttrue");
    $res->content("Hello");

    is_deeply $res->finalize,
        [
            200,
            [ 'X-LWS-I' => 'Bar true', 'X-LWS-II' => 'Bar true' ],
            ["Hello"]
        ];
}

{
    my $res = Web::Response->new;
    $res->status(200);
    $res->header("X-CR-LF" => "Foo\nBar\rBaz");
    $res->content("Hello");

    is_deeply $res->finalize, [ 200, [ 'X-CR-LF' => 'FooBarBaz' ], ["Hello"] ];
}

{
    my $res = Web::Response->new;
    $res->status(200);
    $res->header("X-CR-LF" => "Foo\nBar\rBaz");
    $res->content("Hello");

    is_deeply $res->finalize, [ 200, [ 'X-CR-LF' => 'FooBarBaz' ], ["Hello"] ];
}

done_testing;
