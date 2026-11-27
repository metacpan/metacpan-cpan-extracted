use strict;
use warnings;

use lib 't/lib';

use Test::More;
use VPNDetection;
use VPNDetectionTest::Origin;

# An AS's `type` is a paid plan's member: Unlimited's answer, with a key or without
# one, carries an `asn` without it. Such an answer is read, in a lookup, my_ip and a
# batch entry alike, and `type` reads as absent. One that is served still reads as
# served, and a null or a wrong type is still a retried server_error.

my $as = { asn => 9009, name => 'M247 Europe SRL', domain => 'm247global.com', prefix => '146.70.116.0/24',
    country => 'US', rpki_status => 'valid' };
my $keyless = { ip => '9.9.9.9', is_vpn => \0, is_relay => \0, is_tor => \0, is_anycast => \0, asn => { %$as } };
my $paid = { %$keyless, asn => { %$as, type => 'hosting' } };

my $body;
my $origin = VPNDetectionTest::Origin->new(sub { $_[0]->render(json => $body) });
my $client = VPNDetection->new(base_url => $origin->url, retries => 1);

subtest 'a lookup without the AS type is read, and the type reads as absent' => sub {
    ($body, my $count) = ($keyless, $origin->count);
    my $result = eval { $client->lookup('9.9.9.9') };
    ok($result, 'the answer is read') or return diag($@);

    is($origin->count, $count + 1, 'in one request');
    is_deeply($result->asn, $as, 'the AS carries what was served');
    ok(!exists $result->asn->{type}, 'and type has no key at all');
    is($result->asn->{type}, undef, 'so it reads as undef');
    is($result->asn->{name}, 'M247 Europe SRL', 'and the rest of the AS reads');
    is($result->has('is_bot'), 0, 'is_bot, a paid plan\'s too, is absent');
    ok(!exists $result->raw->{asn}{type}, 'and so is it in the raw answer');
};

subtest 'a cached answer without the AS type is still without it' => sub {
    ($body, my $count) = ($keyless, $origin->count);
    my $cached = VPNDetection->new(base_url => $origin->url, retries => 1);
    my $first = $cached->lookup('9.9.9.8');
    my $second = $cached->lookup('9.9.9.8');

    is($origin->count, $count + 1, 'the second lookup came from the cache');
    ok(!exists $_->asn->{type}, 'and carries no type') for $first, $second;
};

subtest 'my_ip without the AS type is read' => sub {
    $body = $keyless;
    my $result = eval { $client->my_ip };
    ok($result, 'the answer is read') or return diag($@);
    ok(!exists $result->asn->{type}, 'and type has no key at all');
};

subtest 'a batch entry without the AS type is an answer, not an error' => sub {
    my %entry = (
        '9.9.9.1' => { %$keyless, ip => '9.9.9.1' },
        '9.9.9.2' => { %$paid, ip => '9.9.9.2' },
    );
    $body = { results => \%entry, errors => {} };
    my $answers = VPNDetection->new(base_url => $origin->url, retries => 1, cache_size => 0)
        ->lookup_batch([sort keys %entry]);

    isa_ok($answers->{'9.9.9.1'}, 'VPNDetection::Result', 'the entry without a type');
    ok(!exists $answers->{'9.9.9.1'}->asn->{type}, 'carries no type');
    isa_ok($answers->{'9.9.9.2'}, 'VPNDetection::Result', 'the entry with one');
    is($answers->{'9.9.9.2'}->asn->{type}, 'hosting', 'reads it');
};

subtest 'a type that is served reads as served' => sub {
    $body = $paid;
    my $result = eval { $client->lookup('9.9.9.7') };
    ok($result, 'the answer is read') or return diag($@);
    is($result->asn->{type}, 'hosting', 'type reads as served');
    is_deeply($result->asn, { %$as, type => 'hosting' }, 'with the whole AS');

    $body = { %$keyless, ip => '9.9.9.6', asn => { %$as, type => '' } };
    $result = eval { $client->lookup('9.9.9.6') };
    ok($result, 'an empty type is a string, and read') or return diag($@);
    is($result->asn->{type}, '', 'as served');
};

subtest 'a type that is null or of the wrong type is a retried server_error' => sub {
    my %cases = (
        'a null type' => undef,
        'a number' => 5,
        'a boolean' => \1,
        'a list' => ['hosting'],
        'an object' => { kind => 'hosting' },
    );
    for my $name (sort keys %cases) {
        $body = { %$keyless, asn => { %$as, type => $cases{$name} } };
        my $count = $origin->count;
        my $fresh = VPNDetection->new(base_url => $origin->url, retries => 1, cache_size => 0);
        my $answer = eval { $fresh->lookup('9.9.9.5') };
        my $error = $@;

        ok(!defined $answer, "$name: no answer");
        is(ref $error && $error->kind, 'server_error', "$name: a server_error");
        is(ref $error && $error->status, 200, "$name: carrying the status");
        is($origin->count, $count + 2, "$name: retried");
    }
};

done_testing();
