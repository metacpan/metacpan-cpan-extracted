#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More;

## no critic (ProhibitStringyEval, RequireCheckingReturnValueOfEval)
eval q(use Net::SSLeay);
plan skip_all => q(Net::SSLeay required for HTTPS functionality) if $@;

use AnyEvent::HTTP;
use Test::HTTP::AnyEvent::Server;

$AnyEvent::Log::FILTER->level(q(fatal));
AnyEvent::HTTP::set_proxy(undef);

my $tls_ctx = { cert_file => 't/cert.pem' };
my $server  = Test::HTTP::AnyEvent::Server->new(
    https   => $tls_ctx,
);
my $cv = AE::cv;

$cv->begin;
http_request
    GET     => $server->uri . q(echo/head),
    tls_ctx => $tls_ctx,
    sub {
        my ($body, $hdr) = @_;
        like($body, qr{^GET\s+/echo/head\s+HTTP/1\.[01]\b}isx, q(echo/head));
        ok($hdr->{q(content-type)} eq q(text/plain), q(Content-Type));
        ok($hdr->{connection} eq q(close), q(Connection));
        like($hdr->{server}, qr{^Test::HTTP::AnyEvent::Server/}x, q(User-Agent));

        $cv->end;
    };

$cv->wait;

done_testing(4);
