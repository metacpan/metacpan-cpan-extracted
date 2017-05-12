#!perl
use strict;
use utf8;
use warnings qw(all);

use Test::More;

use HTTP::Tiny;
use Test::HTTP::AnyEvent::Server;

local $ENV{no_proxy} = '*';

my $server = Test::HTTP::AnyEvent::Server->new(
    disable_proxy   => 0,
    forked          => 1,
);

my $ua = HTTP::Tiny->new(
    http_proxy      => undef,
    https_proxy     => undef,
    proxy           => undef,
);

my $res = $ua->get($server->uri . q(repeat/1000/asdfgh));
ok($res->{success}, q(success));
like($res->{content}, qr{^(?:asdfgh){1000}$}x, q(content OK));

done_testing(2);
