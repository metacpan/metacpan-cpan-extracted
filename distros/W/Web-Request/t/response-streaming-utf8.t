#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Web::Request;

{
    use utf8;

    my $req = Web::Request->new_from_env({});

    my $res = $req->new_response(sub {
        my $responder = shift;
        $responder->([200, [], ["café"]]);
    });
    my $psgi_res = $res->finalize;
    ok(ref($psgi_res) eq 'CODE', "got a coderef");

    is_deeply(
        resolve_response($psgi_res),
        [ 200, [], ["caf\xe9"] ],
        "got the right response"
    );
}

{
    use utf8;

    my $req = Web::Request->new_from_env({});
    $req->encoding('UTF-8');

    my $res = $req->new_response(sub {
        my $responder = shift;
        $responder->([200, [], ["café"]]);
    });
    my $psgi_res = $res->finalize;
    ok(ref($psgi_res) eq 'CODE', "got a coderef");

    is_deeply(
        resolve_response($psgi_res),
        [ 200, [], ["caf\xc3\xa9"] ],
        "got the right response"
    );
}

{
    use utf8;

    my $req = Web::Request->new_from_env({});

    my $res = $req->new_response(sub {
        my $responder = shift;
        my $writer = $responder->([200, []]);
        $writer->write("ca");
        $writer->write("fé");
        $writer->close;
    });
    my $psgi_res = $res->finalize;
    ok(ref($psgi_res) eq 'CODE', "got a coderef");

    is_deeply(
        resolve_response($psgi_res),
        [ 200, [], ["ca", "f\xe9"] ],
        "got the right response"
    );
}

{
    use utf8;

    my $req = Web::Request->new_from_env({});
    $req->encoding('UTF-8');

    my $res = $req->new_response(sub {
        my $responder = shift;
        my $writer = $responder->([200, []]);
        $writer->write("ca");
        $writer->write("fé");
        $writer->close;
    });
    my $psgi_res = $res->finalize;
    ok(ref($psgi_res) eq 'CODE', "got a coderef");

    is_deeply(
        resolve_response($psgi_res),
        [ 200, [], ["ca", "f\xc3\xa9"] ],
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
