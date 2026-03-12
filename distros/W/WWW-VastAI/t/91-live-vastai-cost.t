#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use lib 't/lib';

use Test::WWW::VastAI::Live qw(
    live_client
    pick_cheapest_offer
    public_port_for_instance
    require_cost_env
    unique_label
    wait_for_http
    wait_for_instance
);

BEGIN {
    require_cost_env();
}

my $vast = live_client();
my $label = $ENV{VAST_LIVE_LABEL} || unique_label('perl-cost-vast');
my $instance;

END {
    return unless $vast;
    return unless $instance;
    return unless eval { $instance->id };

    eval {
        my $result = $vast->instances->delete($instance->id);
        diag 'cleanup: delete requested for instance ' . $instance->id;
        $result;
    };
    diag "cleanup failed for instance " . $instance->id . ": $@" if $@;
}

subtest 'rent cheapest offer, verify custom image over http, stop and clean up' => sub {
    my $offer = defined $ENV{VAST_LIVE_ASK_ID} && length $ENV{VAST_LIVE_ASK_ID}
        ? undef
        : pick_cheapest_offer(
            $vast,
            disk_space => { gte => ($ENV{VAST_LIVE_DISK} || 16) },
          );

    my $offer_id = $ENV{VAST_LIVE_ASK_ID} || $offer->ask_contract_id;
    note 'using ask id ' . $offer_id if defined $offer_id;

    my %create = (
        disk    => ($ENV{VAST_LIVE_DISK} || 16),
        runtype => ($ENV{VAST_LIVE_RUNTYPE} || 'args'),
        label   => $label,
    );

    $create{image} = (
        defined $ENV{VAST_LIVE_IMAGE} && length $ENV{VAST_LIVE_IMAGE}
            ? $ENV{VAST_LIVE_IMAGE}
            : 'nginx:alpine'
    );
    $create{template_hash_id} = $ENV{VAST_LIVE_TEMPLATE_HASH_ID}
        if defined $ENV{VAST_LIVE_TEMPLATE_HASH_ID} && length $ENV{VAST_LIVE_TEMPLATE_HASH_ID};
    $create{onstart_cmd} = $ENV{VAST_LIVE_ONSTART_CMD}
        if defined $ENV{VAST_LIVE_ONSTART_CMD} && length $ENV{VAST_LIVE_ONSTART_CMD};

    $instance = $vast->instances->create($offer_id, %create);
    isa_ok($instance, 'WWW::VastAI::Instance');
    ok($instance->id, 'created instance has id');

    my $running = wait_for_instance(
        $vast,
        $instance->id,
        'running',
        timeout  => ($ENV{VAST_LIVE_TIMEOUT} || 240),
        interval => ($ENV{VAST_LIVE_POLL_INTERVAL} || 5),
    );
    isa_ok($running, 'WWW::VastAI::Instance');
    ok($running->is_running, 'instance reached running state');

    my $http_port = public_port_for_instance($running, 80);
    ok(defined $http_port, 'instance exposes a public HTTP port');

    my $url = 'http://' . $running->public_ipaddr . ':' . $http_port . '/';
    my $body = wait_for_http(
        $url,
        timeout  => ($ENV{VAST_LIVE_HTTP_TIMEOUT} || 120),
        interval => ($ENV{VAST_LIVE_HTTP_INTERVAL} || 5),
        match    => qr/nginx/i,
    );
    like($body, qr/nginx/i, 'custom image answered over HTTP');

    my $stop_requested = $vast->instances->stop($instance->id);
    isa_ok($stop_requested, 'WWW::VastAI::Instance');
    my $stopped = wait_for_instance(
        $vast,
        $instance->id,
        'stopped',
        timeout  => ($ENV{VAST_LIVE_TIMEOUT} || 240),
        interval => ($ENV{VAST_LIVE_POLL_INTERVAL} || 5),
    );
    ok($stopped->is_stopped, 'instance reached stopped state');

    my $deleted = $vast->instances->delete($instance->id);
    ok($deleted, 'delete request accepted');
    undef $instance;
};

done_testing;
