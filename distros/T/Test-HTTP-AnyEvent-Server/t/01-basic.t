#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More;

use AnyEvent::HTTP;
use Config;
use Scalar::Util qw(looks_like_number);
use Test::HTTP::AnyEvent::Server;

$AnyEvent::Log::FILTER->level(q(fatal));
AnyEvent::HTTP::set_proxy(undef);

my $server = Test::HTTP::AnyEvent::Server->new;
my $cv = AE::cv;

$cv->begin;
http_request GET => $server->uri . q(echo/head), sub {
    my ($body, $hdr) = @_;

    like($body, qr{^GET\s+/echo/head\s+HTTP/1\.[01]\b}isx, q(echo/head));
    ok($hdr->{q(content-type)} eq q(text/plain), q(Content-Type));
    ok($hdr->{connection} eq q(close), q(Connection));
    like($hdr->{server}, qr{^Test::HTTP::AnyEvent::Server/}x, q(User-Agent));

    $cv->end;
};

$cv->begin;
my $body = q(key1=value1&key2=value2);
http_request POST => $server->uri . q(echo/body), body => $body, sub {
    ok($_[0] eq $body, q(echo/body));
    $cv->end;
};

$cv->begin;
http_request GET => $server->uri . q(repeat/123/qwerty), sub {
    like($_[0], qr{^(?:qwerty){123}$}x, q(repeat));
    $cv->end;
};

SKIP: {
    skip q(MidnightBSD 0.3 fails this test), 3
        if $Config{osname} eq 'midnightbsd'
        and $Config{osvers} eq '0.3-release';

    $cv->begin;
    my $stamp = time;
    http_request GET => $server->uri . q(delay/3), timeout => 5, sub {
        if ($_[0] =~ m{^issued\s+(.+)$}ix) {
            my $issued = AnyEvent::HTTP::parse_date($1);
            ok(looks_like_number($issued), qq(parsed time string "$1" as $issued));
            ok(is_within_range($issued, $stamp, 1), qq(replied (almost) immediately (started at $stamp)));
            my $now = time;
            ok(is_within_range($issued + 3, $now, 1), qq(started at $stamp; delayed until $now));
        } else {
            fail(q(invalid date response));
        }
        $cv->end;
    };
}

$cv->begin;
http_request GET => $server->uri . q(non-existent), sub {
    ok($_[1]->{Status} == 404, q(Not Found));
    $cv->end;
};

$cv->begin;
http_request HEAD => $server->uri, sub {
    ok($_[1]->{Status} == 400, q(Bad Request));
    $cv->end;
};

$cv->wait;

done_testing(11);


sub is_within_range {
    my ($val, $ref, $range) = @_;
    return
        (abs($val - $ref) <= $range)
            ? 1
            : 0
}
