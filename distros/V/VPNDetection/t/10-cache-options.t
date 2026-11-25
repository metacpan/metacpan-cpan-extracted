use strict;
use warnings;

use lib 't/lib';

use Test::More;
use VPNDetection;
use VPNDetectionTest::Origin;

# The cache's size and lifetime are checked when the client is built, as the
# counts and the timeout are. Through 3.19.0 a NaN lifetime held every answer
# for good, a negative or non-numeric one cached nothing with a warning, and a
# size of 1.5, -1, NaN or a word was taken as 1 or as no cache at all.

my $origin = VPNDetectionTest::Origin->new(sub {
    my ($c) = @_;
    (my $ip = $c->req->url->path->to_string) =~ s{^/}{};
    $c->render(json => { ip => $ip, is_vpn => Mojo::JSON::false });
});

my $nan = 9**9**9 / 9**9**9;

subtest 'a cache_ttl that is no number of seconds from 0 croaks' => sub {
    for my $ttl ('NaN', 'nan', $nan, -1, -0.5, 'abc', '', '1x', [1], { 1 => 1 }) {
        my $label = ref $ttl ? ref $ttl : "'$ttl'";
        my $client = eval { VPNDetection->new(base_url => $origin->url, cache_ttl => $ttl) };
        ok(!$client, "cache_ttl $label refused");
        like($@, qr/cache_ttl must be a number of seconds, 0 or more/, "cache_ttl $label names the option");
    }
};

subtest 'a cache_size that is no whole number from 0 croaks' => sub {
    for my $size (1.5, '2.5', -1, 'NaN', $nan, 'abc', '', [1]) {
        my $label = ref $size ? ref $size : "'$size'";
        my $client = eval { VPNDetection->new(base_url => $origin->url, cache_size => $size) };
        ok(!$client, "cache_size $label refused");
        like($@, qr/cache_size must be a whole number, 0 or more/, "cache_size $label names the option");
    }
};

subtest 'the lifetimes and sizes that are numbers are taken' => sub {
    for my $case ([0, 3], ['0.0', 3], [0.5, 1], ['inf', 1], [3600, 1]) {
        my ($ttl, $requests) = @$case;
        my $client = eval { VPNDetection->new(base_url => $origin->url, cache_ttl => $ttl) };
        ok($client, "cache_ttl '$ttl' taken") or diag $@;
        next unless $client;
        $origin->reset;
        $client->lookup('45.83.91.1') for 1 .. 3;
        is($origin->count, $requests, "cache_ttl '$ttl': three lookups send $requests");
    }
    for my $case ([0, 4], ['0', 4], [1, 4], [2, 2], ['inf', 2]) {
        my ($size, $requests) = @$case;
        my $client = eval { VPNDetection->new(base_url => $origin->url, cache_size => $size) };
        ok($client, "cache_size '$size' taken") or diag $@;
        next unless $client;
        $origin->reset;
        $client->lookup($_) for qw(45.83.91.1 45.83.91.2 45.83.91.1 45.83.91.2);
        is($origin->count, $requests, "cache_size '$size': two addresses twice send $requests");
    }
};

done_testing;
