#!/usr/bin/env perl

use strict;
use warnings;

use Test2::V0 -target => 'VM::HetznerCloud::API::Servers';

subtest 'can all required methods' => sub {
    my $client = $CLASS->new(
        token => 'abc135',
    );

    isa_ok $client, 'VM::HetznerCloud::API::Servers';

    my @methods = qw(
        list create
        get delete put
        list_actions add_to_placement_group attach_iso attach_to_network
        change_alias_ips change_dns_ptr change_protection change_type
        create_image detach_from_network detach_iso disable_backup
        disable_rescue enable_backup enable_rescue poweroff
        poweron reboot rebuild remove_from_placement_group
        request_console reset reset_password shutdown
        get_actions
        list_metrics
    );

    can_ok $client, @methods;
};

subtest 'check attribute values' => sub {
    my $client = $CLASS->new(
        token => $ENV{HETZNER_CLOUD_TOKEN} // 'abc135',
    );

    is $client->token, $ENV{HETZNER_CLOUD_TOKEN} // 'abc135';
};


done_testing();
