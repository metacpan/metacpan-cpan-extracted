#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0 -target => 'VM::HetznerCloud';

subtest 'server' => sub {
    my $cloud = $CLASS->new(
        token => 'abc123',
    );

    isa_ok $cloud, 'VM::HetznerCloud';

    my $client = $cloud->servers;
    isa_ok $client, 'VM::HetznerCloud::API::Servers';


    is $client->token, $cloud->token;
    is $client->host, $cloud->host;
    is $client->base_uri, $cloud->base_uri;
};


done_testing();
