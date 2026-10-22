#!/usr/bin/env perl

# karr #31: Volumes->create copied automount verbatim into the body, so a
# Perl 0/1 went out as a JSON number (0/1) and the Hetzner API rejected the
# request with invalid_input ("failed to parse json").  Volumes->attach used
# `$opts{automount} ? \1 : \0`, so a caller passing \0 got true -- every
# reference is truthy.  These tests inspect the encoded request content
# leaving through the IO seam, not the decoded hash.

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

my %base = (name => 'bool-test', size => 10, location => 'fsn1');

subtest 'create sends Perl 0/1 as JSON booleans' => sub {
    my $json = encoded_body_for('POST /volumes', load_fixture('volumes_create'), sub {
        shift->volumes->create(%base, automount => 0);
    });
    like($json, qr/"automount":false/, 'automount => 0 encodes as false');

    $json = encoded_body_for('POST /volumes', load_fixture('volumes_create'), sub {
        shift->volumes->create(%base, automount => 1);
    });
    like($json, qr/"automount":true/, 'automount => 1 encodes as true');
};

subtest 'create accepts truthy/falsy, \\0/\\1 and JSON::PP booleans alike' => sub {
    my $json = encoded_body_for('POST /volumes', load_fixture('volumes_create'), sub {
        shift->volumes->create(%base, automount => \0);
    });
    like($json, qr/"automount":false/, '\\0 encodes as false');

    $json = encoded_body_for('POST /volumes', load_fixture('volumes_create'), sub {
        shift->volumes->create(%base, automount => \1);
    });
    like($json, qr/"automount":true/, '\\1 encodes as true');

    $json = encoded_body_for('POST /volumes', load_fixture('volumes_create'), sub {
        shift->volumes->create(%base, automount => JSON::PP::false);
    });
    like($json, qr/"automount":false/, 'JSON::PP::false encodes as false');

    $json = encoded_body_for('POST /volumes', load_fixture('volumes_create'), sub {
        shift->volumes->create(%base, automount => JSON::PP::true);
    });
    like($json, qr/"automount":true/, 'JSON::PP::true encodes as true');
};

subtest 'create without automount sends no automount field' => sub {
    my $json = encoded_body_for('POST /volumes', load_fixture('volumes_create'), sub {
        shift->volumes->create(%base);
    });
    unlike($json, qr/"automount"/, 'no automount field without the option');
};

subtest 'attach sends Perl 0/1 as JSON booleans' => sub {
    my $json = encoded_body_for('POST /volumes/777/actions/attach', load_fixture('volumes_action'), sub {
        shift->volumes->attach(777, 42, automount => 0);
    });
    like($json, qr/"automount":false/, 'automount => 0 encodes as false');

    $json = encoded_body_for('POST /volumes/777/actions/attach', load_fixture('volumes_action'), sub {
        shift->volumes->attach(777, 42, automount => 1);
    });
    like($json, qr/"automount":true/, 'automount => 1 encodes as true');
};

subtest 'attach sends \\0 as false' => sub {
    my $json = encoded_body_for('POST /volumes/777/actions/attach', load_fixture('volumes_action'), sub {
        shift->volumes->attach(777, 42, automount => \0);
    });
    like($json, qr/"automount":false/, '\\0 encodes as false');

    $json = encoded_body_for('POST /volumes/777/actions/attach', load_fixture('volumes_action'), sub {
        shift->volumes->attach(777, 42, automount => \1);
    });
    like($json, qr/"automount":true/, '\\1 encodes as true');
};

subtest 'attach without automount sends no automount field' => sub {
    my $json = encoded_body_for('POST /volumes/777/actions/attach', load_fixture('volumes_action'), sub {
        shift->volumes->attach(777, 42);
    });
    unlike($json, qr/"automount"/, 'no automount field without the option');
};

done_testing;
