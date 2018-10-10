#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use Test::Most;

use lib "$FindBin::RealBin/../lib";

use WebService::Mattermost;

my $api = WebService::Mattermost->new({
    base_url => '...',
    username => '...',
    password => '...',
})->api;

foreach my $name ($api->meta->get_attribute_list) {
    my $attr = $api->meta->get_attribute($name);

    if ($attr->has_builder) {
        can_ok $api, $name;

        my $cref = $api->can($name);

        next unless $cref;

        ok $api->$cref, "Built ${name}";
    }
}

done_testing();

