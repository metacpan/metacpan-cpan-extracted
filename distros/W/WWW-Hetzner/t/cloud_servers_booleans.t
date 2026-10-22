#!/usr/bin/env perl

# karr #30: Servers->create copied enable_ipv4 => 0 etc. verbatim into the
# body, so they went out as JSON numbers (0/1) and the Hetzner API rejected the
# request with invalid_input ("failed to parse json").  These tests inspect the
# encoded request content leaving through the IO seam, not the decoded hash.

use strict;
use warnings;
use Test::More;
use JSON::PP ();
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

# Capture the raw JSON string of the request sent to $route.
sub encoded_body_for {
    my ($route, $fixture, $call) = @_;
    my $content;
    my $cloud = mock_cloud(
        $route => sub {
            my ($method, $path, %opts) = @_;
            $content = $opts{request}->content;
            return $fixture;
        },
    );
    $call->($cloud);
    return $content;
}

my %base = (name => 'bool-test', server_type => 'cx23', image => 'debian-13');

subtest 'create sends Perl 0/1 as JSON booleans' => sub {
    my $json = encoded_body_for('POST /servers', load_fixture('servers_create'), sub {
        shift->servers->create(%base,
            enable_ipv4        => 0,
            enable_ipv6        => 0,
            automount          => 1,
            start_after_create => 0,
        );
    });
    like($json, qr/"enable_ipv4":false/,        'enable_ipv4 => 0 encodes as false');
    like($json, qr/"enable_ipv6":false/,        'enable_ipv6 => 0 encodes as false');
    like($json, qr/"automount":true/,           'automount => 1 encodes as true');
    like($json, qr/"start_after_create":false/, 'start_after_create => 0 encodes as false');
};

subtest 'create default start_after_create is JSON true' => sub {
    my $json = encoded_body_for('POST /servers', load_fixture('servers_create'), sub {
        shift->servers->create(%base);
    });
    like($json, qr/"start_after_create":true/, 'default start_after_create encodes as true');
    unlike($json, qr/"public_net"/, 'no public_net without IP options');
};

subtest 'create accepts truthy/falsy, \\0/\\1 and JSON::PP booleans alike' => sub {
    my $json = encoded_body_for('POST /servers', load_fixture('servers_create'), sub {
        shift->servers->create(%base,
            enable_ipv4        => \0,
            enable_ipv6        => JSON::PP::false,
            automount          => '',
            start_after_create => 'yes',
        );
    });
    like($json, qr/"enable_ipv4":false/,       '\\0 encodes as false');
    like($json, qr/"enable_ipv6":false/,       'JSON::PP::false encodes as false');
    like($json, qr/"automount":false/,         'empty string encodes as false');
    like($json, qr/"start_after_create":true/, 'truthy string encodes as true');

    $json = encoded_body_for('POST /servers', load_fixture('servers_create'), sub {
        shift->servers->create(%base,
            enable_ipv4 => \1,
            enable_ipv6 => JSON::PP::true,
        );
    });
    like($json, qr/"enable_ipv4":true/, '\\1 encodes as true');
    like($json, qr/"enable_ipv6":true/, 'JSON::PP::true encodes as true');
};

subtest 'create coerces booleans passed inside public_net' => sub {
    my $json = encoded_body_for('POST /servers', load_fixture('servers_create'), sub {
        shift->servers->create(%base,
            public_net => { enable_ipv4 => 0, enable_ipv6 => 1 },
        );
    });
    like($json, qr/"enable_ipv4":false/, 'public_net enable_ipv4 => 0 encodes as false');
    like($json, qr/"enable_ipv6":true/,  'public_net enable_ipv6 => 1 encodes as true');
};

subtest 'change_type sends upgrade_disk as JSON boolean' => sub {
    my $json = encoded_body_for('POST /servers/42/actions/change_type', load_fixture('servers_action'), sub {
        shift->servers->change_type(42, 'cx33', upgrade_disk => 0);
    });
    like($json, qr/"upgrade_disk":false/, 'upgrade_disk => 0 encodes as false');

    $json = encoded_body_for('POST /servers/42/actions/change_type', load_fixture('servers_action'), sub {
        shift->servers->change_type(42, 'cx33');
    });
    like($json, qr/"upgrade_disk":true/, 'default upgrade_disk encodes as true');
};

done_testing;
