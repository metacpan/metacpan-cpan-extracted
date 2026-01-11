#!/usr/bin/env perl

# Integration tests for Hetzner Cloud API
# Only runs when HETZNER_TEST_TOKEN is set
# Uses a dedicated test project to avoid interference

use strict;
use warnings;
use Test::More;

unless ($ENV{HETZNER_TEST_TOKEN}) {
    plan skip_all => 'Set HETZNER_TEST_TOKEN to run integration tests';
}

use WWW::Hetzner::Cloud;

my $cloud = WWW::Hetzner::Cloud->new(token => $ENV{HETZNER_TEST_TOKEN});

# Unique prefix for test resources (to identify and clean up)
my $prefix = 'perl-test-' . substr(time, -6);

# Pre-cleanup: remove any leftover test resources from previous runs
{
    my $keys = $cloud->ssh_keys->list;
    for my $key (@$keys) {
        if ($key->name =~ /^perl-test-/) {
            eval { $cloud->ssh_keys->delete($key->id) };
            diag "Pre-cleanup: deleted SSH key " . $key->name if !$@;
        }
    }
    my $fws = $cloud->firewalls->list;
    for my $fw (@$fws) {
        if ($fw->name =~ /^perl-test-/) {
            eval { $cloud->firewalls->delete($fw->id) };
            diag "Pre-cleanup: deleted firewall " . $fw->name if !$@;
        }
    }
    my $nets = $cloud->networks->list;
    for my $net (@$nets) {
        if ($net->name =~ /^perl-test-/) {
            eval { $cloud->networks->delete($net->id) };
            diag "Pre-cleanup: deleted network " . $net->name if !$@;
        }
    }
    my $pgs = $cloud->placement_groups->list;
    for my $pg (@$pgs) {
        if ($pg->name =~ /^perl-test-/) {
            eval { $cloud->placement_groups->delete($pg->id) };
            diag "Pre-cleanup: deleted placement group " . $pg->name if !$@;
        }
    }
}

# Track created resources for cleanup
my @cleanup;

# Helper to register cleanup
sub will_cleanup {
    my ($type, $id) = @_;
    unshift @cleanup, { type => $type, id => $id };
}

# Cleanup at end
END {
    if ($cloud && @cleanup) {
        diag "Cleaning up test resources...";
        for my $item (@cleanup) {
            eval {
                if ($item->{type} eq 'ssh_key') {
                    $cloud->ssh_keys->delete($item->{id});
                } elsif ($item->{type} eq 'firewall') {
                    $cloud->firewalls->delete($item->{id});
                } elsif ($item->{type} eq 'network') {
                    $cloud->networks->delete($item->{id});
                } elsif ($item->{type} eq 'placement_group') {
                    $cloud->placement_groups->delete($item->{id});
                }
                diag "  Deleted $item->{type} $item->{id}";
            };
            warn "  Failed to delete $item->{type} $item->{id}: $@" if $@;
        }
    }
}

#
# SSH Keys - all operations
#
subtest 'SSH Keys' => sub {
    my $name = "$prefix-sshkey";
    my $pubkey = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFsWypfT8MkAhTkBhYIinpBMql+Oo87o0yVjpF3oGjyK test@example.com';

    # create
    my $key = $cloud->ssh_keys->create(
        name       => $name,
        public_key => $pubkey,
        labels     => { test => 'true' },
    );
    ok($key, 'create: returned object');
    ok($key->id, 'create: has id');
    is($key->name, $name, 'create: name matches');
    will_cleanup(ssh_key => $key->id);

    # get
    my $fetched = $cloud->ssh_keys->get($key->id);
    is($fetched->id, $key->id, 'get: returns same key');
    is($fetched->name, $name, 'get: correct name');

    # get_by_name
    my $by_name = $cloud->ssh_keys->get_by_name($name);
    is($by_name->id, $key->id, 'get_by_name: returns same key');

    # list
    my $keys = $cloud->ssh_keys->list;
    ok(ref $keys eq 'ARRAY', 'list: returns array');
    my ($found) = grep { $_->id == $key->id } @$keys;
    ok($found, 'list: created key found');

    # update
    my $new_name = "$name-updated";
    $cloud->ssh_keys->update($key->id, name => $new_name);
    my $updated = $cloud->ssh_keys->get($key->id);
    is($updated->name, $new_name, 'update: name changed');

    # ensure (idempotent create) - uses positional params and different key
    my $pubkey2 = 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIbOBT750SXYREeoCWiTBT30CcSWpgJLWYq8pG00ig/+ test2@example.com';
    my $ensured = $cloud->ssh_keys->ensure("$prefix-ensure-key", $pubkey2);
    ok($ensured, 'ensure: returned object');
    will_cleanup(ssh_key => $ensured->id);

    my $ensured2 = $cloud->ssh_keys->ensure("$prefix-ensure-key", $pubkey2);
    is($ensured2->id, $ensured->id, 'ensure: second call returns same key');

    # delete
    $cloud->ssh_keys->delete($key->id);
    shift @cleanup;
    my $keys_after = $cloud->ssh_keys->list;
    ok(!(grep { $_->id == $key->id } @$keys_after), 'delete: key removed');
};

#
# Firewalls - all operations
#
subtest 'Firewalls' => sub {
    my $name = "$prefix-firewall";

    # create
    my $fw = $cloud->firewalls->create(
        name   => $name,
        labels => { test => 'true' },
    );
    ok($fw, 'create: returned object');
    ok($fw->id, 'create: has id');
    is($fw->name, $name, 'create: name matches');
    will_cleanup(firewall => $fw->id);

    # get
    my $fetched = $cloud->firewalls->get($fw->id);
    is($fetched->id, $fw->id, 'get: returns same firewall');

    # update
    my $new_name = "$name-updated";
    $cloud->firewalls->update($fw->id, name => $new_name);
    my $updated = $cloud->firewalls->get($fw->id);
    is($updated->name, $new_name, 'update: name changed');

    # set_rules (replace all rules)
    $cloud->firewalls->set_rules($fw->id, [
        {
            direction  => 'in',
            protocol   => 'tcp',
            port       => '22',
            source_ips => ['0.0.0.0/0', '::/0'],
        },
        {
            direction  => 'in',
            protocol   => 'tcp',
            port       => '80',
            source_ips => ['0.0.0.0/0', '::/0'],
        },
    ]);
    my $with_rules = $cloud->firewalls->get($fw->id);
    is(scalar @{$with_rules->rules}, 2, 'set_rules: two rules set');

    # list
    my $fws = $cloud->firewalls->list;
    ok((grep { $_->id == $fw->id } @$fws), 'list: firewall found');

    # Note: apply_to_resources/remove_from_resources need a server, skipped

    # delete
    $cloud->firewalls->delete($fw->id);
    shift @cleanup;
    my $fws_after = $cloud->firewalls->list;
    ok(!(grep { $_->id == $fw->id } @$fws_after), 'delete: firewall removed');
};

#
# Networks - all operations
#
subtest 'Networks' => sub {
    my $name = "$prefix-network";

    # create
    my $net = $cloud->networks->create(
        name     => $name,
        ip_range => '10.99.0.0/16',
        labels   => { test => 'true' },
    );
    ok($net, 'create: returned object');
    ok($net->id, 'create: has id');
    is($net->name, $name, 'create: name matches');
    is($net->ip_range, '10.99.0.0/16', 'create: ip_range matches');
    will_cleanup(network => $net->id);

    # get
    my $fetched = $cloud->networks->get($net->id);
    is($fetched->id, $net->id, 'get: returns same network');

    # update
    my $new_name = "$name-updated";
    $cloud->networks->update($net->id, name => $new_name);
    my $updated = $cloud->networks->get($net->id);
    is($updated->name, $new_name, 'update: name changed');

    # add_subnet
    $cloud->networks->add_subnet($net->id,
        ip_range     => '10.99.1.0/24',
        type         => 'cloud',
        network_zone => 'eu-central',
    );
    my $with_subnet = $cloud->networks->get($net->id);
    ok(@{$with_subnet->subnets} >= 1, 'add_subnet: subnet added');

    # add_route
    $cloud->networks->add_route($net->id,
        destination => '10.100.0.0/16',
        gateway     => '10.99.1.1',
    );
    my $with_route = $cloud->networks->get($net->id);
    ok(@{$with_route->routes} >= 1, 'add_route: route added');

    # delete_route (named params)
    $cloud->networks->delete_route($net->id,
        destination => '10.100.0.0/16',
        gateway     => '10.99.1.1',
    );
    my $after_route_del = $cloud->networks->get($net->id);
    is(scalar @{$after_route_del->routes}, 0, 'delete_route: route removed');

    # delete_subnet (positional: $id, $ip_range)
    $cloud->networks->delete_subnet($net->id, '10.99.1.0/24');
    my $after_subnet_del = $cloud->networks->get($net->id);
    is(scalar @{$after_subnet_del->subnets}, 0, 'delete_subnet: subnet removed');

    # list
    my $nets = $cloud->networks->list;
    ok((grep { $_->id == $net->id } @$nets), 'list: network found');

    # delete
    $cloud->networks->delete($net->id);
    shift @cleanup;
    my $nets_after = $cloud->networks->list;
    ok(!(grep { $_->id == $net->id } @$nets_after), 'delete: network removed');
};

#
# Placement Groups - all operations
#
subtest 'Placement Groups' => sub {
    my $name = "$prefix-pg";

    # create
    my $pg = $cloud->placement_groups->create(
        name   => $name,
        type   => 'spread',
        labels => { test => 'true' },
    );
    ok($pg, 'create: returned object');
    ok($pg->id, 'create: has id');
    is($pg->name, $name, 'create: name matches');
    is($pg->type, 'spread', 'create: type matches');
    will_cleanup(placement_group => $pg->id);

    # get
    my $fetched = $cloud->placement_groups->get($pg->id);
    is($fetched->id, $pg->id, 'get: returns same placement group');

    # update
    my $new_name = "$name-updated";
    $cloud->placement_groups->update($pg->id, name => $new_name);
    my $updated = $cloud->placement_groups->get($pg->id);
    is($updated->name, $new_name, 'update: name changed');

    # list
    my $pgs = $cloud->placement_groups->list;
    ok((grep { $_->id == $pg->id } @$pgs), 'list: placement group found');

    # delete
    $cloud->placement_groups->delete($pg->id);
    shift @cleanup;
    my $pgs_after = $cloud->placement_groups->list;
    ok(!(grep { $_->id == $pg->id } @$pgs_after), 'delete: placement group removed');
};

#
# Read-only resources - all operations
#
subtest 'Locations' => sub {
    my $locations = $cloud->locations->list;
    ok(@$locations > 0, 'list: has locations');

    my $first = $locations->[0];
    ok($first->id, 'list: location has id');
    ok($first->name, 'list: location has name');

    # get
    my $fetched = $cloud->locations->get($first->id);
    is($fetched->id, $first->id, 'get: returns same location');

    # get_by_name
    my $by_name = $cloud->locations->get_by_name($first->name);
    is($by_name->id, $first->id, 'get_by_name: returns same location');
};

subtest 'Datacenters' => sub {
    my $dcs = $cloud->datacenters->list;
    ok(@$dcs > 0, 'list: has datacenters');

    my $first = $dcs->[0];
    ok($first->id, 'list: datacenter has id');
    ok($first->name, 'list: datacenter has name');

    # get
    my $fetched = $cloud->datacenters->get($first->id);
    is($fetched->id, $first->id, 'get: returns same datacenter');

    # get_by_name
    my $by_name = $cloud->datacenters->get_by_name($first->name);
    is($by_name->id, $first->id, 'get_by_name: returns same datacenter');
};

subtest 'Server Types' => sub {
    my $types = $cloud->server_types->list;
    ok(@$types > 0, 'list: has server types');

    my $first = $types->[0];
    ok($first->id, 'list: server type has id');
    ok($first->name, 'list: server type has name');

    # get
    my $fetched = $cloud->server_types->get($first->id);
    is($fetched->id, $first->id, 'get: returns same server type');

    # get_by_name
    my $by_name = $cloud->server_types->get_by_name($first->name);
    is($by_name->id, $first->id, 'get_by_name: returns same server type');
};

subtest 'Images' => sub {
    my $images = $cloud->images->list;
    ok(@$images > 0, 'list: has images');

    my $first = $images->[0];
    ok($first->id, 'list: image has id');

    # get
    my $fetched = $cloud->images->get($first->id);
    is($fetched->id, $first->id, 'get: returns same image');

    # get_by_name (images might not have unique names, so just test it works)
    if ($first->name) {
        my $by_name = $cloud->images->get_by_name($first->name);
        ok($by_name, 'get_by_name: returns an image');
    }
};

done_testing;
