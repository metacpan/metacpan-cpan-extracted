#!/usr/bin/perl

# Simple PSGI application

sub {
    my $text = "Hello, world!\n";

    return [ 200, [ "Content-Type" => "text/plain", "Content-Length" => length($text) ], [ $text ] ];
};
