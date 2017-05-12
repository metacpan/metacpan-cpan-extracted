#!perl
use strict;
use utf8;
use warnings qw(all);

use Carp qw(croak);
use Test::More;

use AnyEvent::HTTP;
use Test::HTTP::AnyEvent::Server;

$AnyEvent::Log::FILTER->level(q(fatal));
AnyEvent::HTTP::set_proxy(undef);

my $body = q(key1=value1&key2=value2);
my $server = Test::HTTP::AnyEvent::Server->new(
    custom_handler => sub {
        my ($res) = @_;
        if ($res->request->uri eq '/hello') {
            isa_ok($res, 'HTTP::Response');
            isa_ok($res->request, 'HTTP::Request');
            isa_ok($res->request->headers, 'HTTP::Headers');
            is($res->request->content, $body, 'received content is the same as the sent');
            is($res->request->headers->header('Content-Length'), length $body, 'Content-Length is correct');
            $res->content('world');
            return 1;
        } elsif ($res->request->uri eq '/broken') {
            croak 'BROKEN';
        } else {
            return 0;
        }
    },
);
my $cv = AE::cv;

$cv->begin;
http_request POST => $server->uri . q(hello), body => $body, sub {
    is($_[0], 'world', q(is custom));
    $cv->end;
};

$cv->begin;
http_request GET => $server->uri . q(non-existent), sub {
    is($_[1]->{Status}, 404, q(Not Found));
    $cv->end;
};

$cv->begin;
http_request GET => $server->uri . q(broken), sub {
    is($_[1]->{Status}, 500, q(Internal Server Error));
    $cv->end;
};

$cv->wait;

done_testing(8);
