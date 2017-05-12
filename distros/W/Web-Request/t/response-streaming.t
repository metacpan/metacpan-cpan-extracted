#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Web::Response;

{
    my $res = Web::Response->new(sub {
        my $responder = shift;
        $responder->([200, [], ["Hello world"]]);
    });
    my $psgi_res = $res->finalize;
    ok(ref($psgi_res) eq 'CODE', "got a coderef");

    is_deeply(
        resolve_response($psgi_res),
        [ 200, [], ["Hello world"] ],
        "got the right response"
    );
}

{
    my $res = Web::Response->new(sub {
        my $responder = shift;
        my $writer = $responder->([200, []]);
        $writer->write("Hello");
        $writer->write(" ");
        $writer->write("world");
        $writer->close;
    });
    my $psgi_res = $res->finalize;
    ok(ref($psgi_res) eq 'CODE', "got a coderef");

    is_deeply(
        resolve_response($psgi_res),
        [ 200, [], ["Hello", " ", "world"] ],
        "got the right response"
    );
}

sub resolve_response {
    my ($psgi_res) = @_;

    if (ref($psgi_res) eq 'CODE') {
        my $body = [];
        $psgi_res->(sub {
            $psgi_res = shift;
            return Plack::Util::inline_object(
                write => sub { push @$body, $_[0] },
                close => sub { push @$psgi_res, $body },
            );
        });
    }

    return $psgi_res;
}

done_testing;
