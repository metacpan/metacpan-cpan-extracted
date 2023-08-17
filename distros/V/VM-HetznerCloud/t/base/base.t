#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use_ok 'VM::HetznerCloud';

my $cloud = VM::HetznerCloud->new(
    token => 'abc123',
);

isa_ok $cloud, 'VM::HetznerCloud';
can_ok $cloud, qw/token base_uri host client/;

my $client = $cloud->client;
isa_ok $client, 'Mojo::UserAgent';

is $cloud->base_uri, 'v1';
is $cloud->token, 'abc123';
is $cloud->host, 'https://api.hetzner.cloud';

# do some fake requests

done_testing();
