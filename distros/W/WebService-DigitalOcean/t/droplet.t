#!/usr/bin/env perl
use warnings;
use strict;
use utf8;
use Test::More;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::WebService::DigitalOcean;

my $do = Test::WebService::DigitalOcean->new(token => 'foo');
isa_ok($do, 'WebService::DigitalOcean');

my $res;

set_expected_response('droplet_create');

$res = $do->droplet_create({
    name   => "example.com",
    region => "nyc3",
    size   => "512mb",
    image  => "ubuntu-14-04-x64",
});

ok($res, 'the droplet_create response is defined');
is($res->{content}{name}, 'example.com', 'the droplet name is example.com');
is($res->{content}{kernel}{name}, 'Ubuntu 14.04 x64 vmlinuz-3.13.0-37-generic', 'the droplet kernel name is correct');
is(get_last_request()->method, 'POST', 'the request method is correct');
is(get_last_request()->uri, 'https://api.digitalocean.com/v2/droplets', 'the request uri is correct');

done_testing;
