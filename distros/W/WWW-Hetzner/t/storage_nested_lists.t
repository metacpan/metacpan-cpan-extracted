use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::WWW::Hetzner::Mock;

sub attempt {
    my ($code) = @_;
    my ($result, $error);
    my $ok = eval { $result = $code->(); 1 };
    $error = $@ unless $ok;
    return ($result, $error // '');
}

sub storage {
    my (%routes) = @_;
    my ($client, $error) = attempt(sub { mock_storage(%routes) });
    ok($client, 'Storage client is available') or return;
    return $client;
}

subtest 'non-paginated Storage Box nested lists preserve documented filters without page parameters' => sub {
    my @seen;
    my $storage = storage(
        'GET /storage_boxes/42' => sub { load_fixture('storage_boxes_get') },
        'GET /storage_boxes/42/folders' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, [$path, $opts{params}, $opts{request}];
            return load_fixture('storage_boxes_folders');
        },
        'GET /storage_boxes/42/subaccounts' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, [$path, $opts{params}, $opts{request}];
            return load_fixture('storage_box_subaccounts_list');
        },
        'GET /storage_boxes/42/snapshots' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, [$path, $opts{params}, $opts{request}];
            return load_fixture('storage_box_snapshots_list');
        },
    ) or return;
    my $box = $storage->storage_boxes->get(42);

    is_deeply($storage->storage_boxes->folders(42, path => 'offsite-backup'), ['offsite-backup', 'photos'], 'folders accepts its documented path filter');
    is(scalar @{ $box->subaccounts->list(name => 'my-name', label_selector => 'environment=prod', username => 'u1337-sub1', sort => ['id', 'name']) }, 1, 'subaccounts list accepts documented filters');
    is(scalar @{ $box->snapshots->list(name => 'snapshot', label_selector => 'environment=prod', is_automatic => 0, sort => ['id', 'name']) }, 2, 'snapshots list accepts documented filters');

    is_deeply([map { $_->[0] } @seen], [
        '/storage_boxes/42/folders',
        '/storage_boxes/42/subaccounts',
        '/storage_boxes/42/snapshots',
    ], 'nested controllers retain their Storage Box path');
    is_deeply([map { $_->[1] } @seen], [
        {path => 'offsite-backup'},
        {name => 'my-name', label_selector => 'environment=prod', username => 'u1337-sub1', sort => ['id', 'name']},
        {name => 'snapshot', label_selector => 'environment=prod', is_automatic => '0', sort => ['id', 'name']},
    ], 'non-paginated endpoints never receive invented page or per_page parameters');
    isa_ok($_->[2], 'WWW::Hetzner::HTTPRequest', 'nested raw request remains available') for @seen;
};

done_testing;
