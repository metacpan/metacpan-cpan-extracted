#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Web::Response;

{
    my $res = Web::Response->new([302]);
    is $res->status, 302;
}

{
    my $res = Web::Response->new([200, ['Content-Type' => 'text/plain']]);
    is $res->content_type, 'text/plain';
}

{
    my $res = Web::Response->new([200, ['Content-Type' => 'text/plain']]);
    is $res->content_type, 'text/plain';
}

{
    my $res = Web::Response->new([200]);
    $res->content_type('image/png');
    is $res->content_type, 'image/png';
}

{
    my $res = Web::Response->new([200]);
    $res->header('X-Foo' => "bar");
    is $res->header('X-Foo'), "bar";
}

done_testing;
