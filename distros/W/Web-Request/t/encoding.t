#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use Test::More;
use Plack::Test;

use HTTP::Request::Common;
use Web::Request;

{
    my $app = sub {
        my ($env) = @_;
        my $req = Web::Request->new_from_env($env);
        is($req->content, "caf\x{c3}\x{a9}");
        $req->encoding('UTF-8');
        is($req->content, "café");
        $req->encoding('iso8859-1');
        is($req->content, "caf\x{c3}\x{a9}");
        return $req->new_response(status => 200)->finalize;
    };

    test_psgi
        app    => $app,
        client => sub {
            my ($cb) = @_;
            my $res = $cb->(POST '/', Content => "caf\x{c3}\x{a9}");
            ok($res->is_success) || diag($res->content);
        };
}

{
    my $app = sub {
        my ($env) = @_;
        my $req = Web::Request->new_from_env($env);

        my $params;

        $params = $req->query_parameters;
        is_deeply([keys %$params],   ["\x{cf}\x{84}"]);
        is_deeply([values %$params], ["2\x{cf}\x{80}"]);
        $req->encoding('UTF-8');
        $params = $req->query_parameters;
        is_deeply([keys %$params],   ["τ"]);
        is_deeply([values %$params], ["2π"]);
        $req->encoding('iso8859-1');
        $params = $req->query_parameters;
        is_deeply([keys %$params],   ["\x{cf}\x{84}"]);
        is_deeply([values %$params], ["2\x{cf}\x{80}"]);

        $params = $req->all_query_parameters;
        is_deeply([keys %$params],   ["\x{cf}\x{84}"]);
        is_deeply([values %$params], [["2\x{cf}\x{80}"]]);
        $req->encoding('UTF-8');
        $params = $req->all_query_parameters;
        is_deeply([keys %$params],   ["τ"]);
        is_deeply([values %$params], [["2π"]]);
        $req->encoding('iso8859-1');
        $params = $req->all_query_parameters;
        is_deeply([keys %$params],   ["\x{cf}\x{84}"]);
        is_deeply([values %$params], [["2\x{cf}\x{80}"]]);

        return $req->new_response(status => 200)->finalize;
    };

    test_psgi
        app    => $app,
        client => sub {
            my ($cb) = @_;
            my $res = $cb->(GET '/?%CF%84=2%CF%80');
            ok($res->is_success) || diag($res->content);
        };
}

{
    my $app = sub {
        my ($env) = @_;
        my $req = Web::Request->new_from_env($env);

        my $params;

        $params = $req->body_parameters;
        is_deeply([keys %$params],   ["\x{cf}\x{84}"]);
        is_deeply([values %$params], ["2\x{cf}\x{80}"]);
        $req->encoding('UTF-8');
        $params = $req->body_parameters;
        is_deeply([keys %$params],   ["τ"]);
        is_deeply([values %$params], ["2π"]);
        $req->encoding('iso8859-1');
        $params = $req->body_parameters;
        is_deeply([keys %$params],   ["\x{cf}\x{84}"]);
        is_deeply([values %$params], ["2\x{cf}\x{80}"]);

        $params = $req->all_body_parameters;
        is_deeply([keys %$params],   ["\x{cf}\x{84}"]);
        is_deeply([values %$params], [["2\x{cf}\x{80}"]]);
        $req->encoding('UTF-8');
        $params = $req->all_body_parameters;
        is_deeply([keys %$params],   ["τ"]);
        is_deeply([values %$params], [["2π"]]);
        $req->encoding('iso8859-1');
        $params = $req->all_body_parameters;
        is_deeply([keys %$params],   ["\x{cf}\x{84}"]);
        is_deeply([values %$params], [["2\x{cf}\x{80}"]]);

        return $req->new_response(status => 200)->finalize;
    };

    test_psgi
        app    => $app,
        client => sub {
            my ($cb) = @_;
            my $res = $cb->(
                POST '/',
                'Content-Type' => 'application/x-www-form-urlencoded',
                'Content'      => '%CF%84=2%CF%80',
            );
            ok($res->is_success) || diag($res->content);
        };
}

{
    my $app = sub {
        my ($env) = @_;
        my $req = Web::Request->new_from_env($env);
        return $req->new_response(
            status  => 200,
            content => "café",
        )->finalize;
    };

    test_psgi
        app    => $app,
        client => sub {
            my ($cb) = @_;
            my $res = $cb->(GET '/');
            ok($res->is_success) || diag($res->content);
            is($res->content, "caf\xe9", "content encoded with latin1");
        };
}

{
    my $app = sub {
        my ($env) = @_;
        my $req = Web::Request->new_from_env($env);
        $req->encoding('UTF-8');
        return $req->new_response(
            status  => 200,
            content => "café",
        )->finalize;
    };

    test_psgi
        app    => $app,
        client => sub {
            my ($cb) = @_;
            my $res = $cb->(GET '/');
            ok($res->is_success) || diag($res->content);
            is($res->content, "caf\xc3\xa9", "content encoded with UTF-8");
        };
}

{
    my $app = sub {
        my ($env) = @_;
        my $req = Web::Request->new_from_env($env);
        $req->encoding(undef);
        return $req->new_response(
            status  => 200,
            content => "\x01\x02\xf3",
        )->finalize;
    };

    test_psgi
        app    => $app,
        client => sub {
            my ($cb) = @_;
            my $res = $cb->(GET '/');
            ok($res->is_success) || diag($res->content);
            is($res->content, "\x01\x02\xf3", "unencoded content");
        };
}

done_testing;
