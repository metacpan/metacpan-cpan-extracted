#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use lib 't/lib';

use Test::WWW::VastAI::Live qw(
    live_client
    require_live_env
);

BEGIN {
    require_live_env();
}

my $vast = live_client();

subtest 'read only account and marketplace coverage' => sub {
    my $user = $vast->user->current;
    isa_ok($user, 'WWW::VastAI::User');
    ok(defined $user->id, 'user has id');

    my $instances = $vast->instances->list;
    is(ref $instances, 'ARRAY', 'instances list returns arrayref');
    if (@{$instances}) {
        isa_ok($instances->[0], 'WWW::VastAI::Instance');
    }
    else {
        pass('instances list is empty');
    }

    my $ssh_keys = $vast->ssh_keys->list;
    is(ref $ssh_keys, 'ARRAY', 'ssh_keys list returns arrayref');
    if (@{$ssh_keys}) {
        isa_ok($ssh_keys->[0], 'WWW::VastAI::SSHKey');
    }
    else {
        pass('ssh_keys list is empty');
    }

    my $api_keys = $vast->api_keys->list;
    is(ref $api_keys, 'ARRAY', 'api_keys list returns arrayref');
    if (@{$api_keys}) {
        isa_ok($api_keys->[0], 'WWW::VastAI::APIKey');
    }
    else {
        pass('api_keys list is empty');
    }

    my $templates = $vast->templates->list;
    is(ref $templates, 'ARRAY', 'templates list returns arrayref');
    if (@{$templates}) {
        isa_ok($templates->[0], 'WWW::VastAI::Template');
    }
    else {
        pass('templates list is empty');
    }

    my $volumes = $vast->volumes->list;
    is(ref $volumes, 'ARRAY', 'volumes list returns arrayref');
    if (@{$volumes}) {
        isa_ok($volumes->[0], 'WWW::VastAI::Volume');
    }
    else {
        pass('volumes list is empty');
    }

    my $offers = $vast->offers->search(
        limit    => 3,
        verified => { eq => \1 },
        rentable => { eq => \1 },
        rented   => { eq => \0 },
    );
    is(ref $offers, 'ARRAY', 'offers search returns arrayref');
    if (@{$offers}) {
        isa_ok($offers->[0], 'WWW::VastAI::Offer');
        ok(defined $offers->[0]->ask_contract_id, 'offer has ask_contract_id');
    }
    else {
        pass('offers search returned no results');
    }

    my $invoices = $vast->invoices->list(limit => 3);
    is(ref $invoices, 'ARRAY', 'invoices list returns arrayref');
    if (@{$invoices}) {
        isa_ok($invoices->[0], 'WWW::VastAI::Invoice');
    }
    else {
        pass('invoices list is empty');
    }
};

done_testing;
