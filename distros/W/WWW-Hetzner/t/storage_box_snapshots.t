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

subtest 'Snapshots use nested IDs for list, get, create, update, entity update, and delete' => sub {
    my @seen;
    my $storage = storage(
        'GET /storage_boxes/42' => sub { load_fixture('storage_boxes_get') },
        'GET /storage_boxes/42/snapshots' => sub { load_fixture('storage_box_snapshots_list') },
        'GET /storage_boxes/42/snapshots/1' => sub { load_fixture('storage_box_snapshots_get') },
        'POST /storage_boxes/42/snapshots' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, [$method, $path, $opts{body}, $opts{request}];
            return load_fixture('storage_box_snapshots_create');
        },
        'PUT /storage_boxes/42/snapshots/1' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, [$method, $path, $opts{body}, $opts{request}];
            my $response = load_fixture('storage_box_snapshots_get');
            $response->{snapshot}{$_} = $opts{body}{$_} for keys %{$opts{body}};
            return $response;
        },
        'DELETE /storage_boxes/42/snapshots/1' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, [$method, $path, $opts{body}, $opts{request}];
            return load_fixture('storage_box_snapshots_action');
        },
        'GET /storage_boxes/actions/13' => sub {
            my $response = load_fixture('storage_box_snapshots_create');
            $response->{action}{status} = 'success';
            $response->{action}{progress} = 100;
            $response->{action}{error} = undef;
            return {action => $response->{action}};
        },
    ) or return;
    $storage->sleeper(sub { });
    my $snapshots = $storage->storage_boxes->get(42)->snapshots;
    isa_ok($snapshots, 'WWW::Hetzner::Storage::API::Snapshots');

    my $list = $snapshots->list;
    is(ref $list, 'ARRAY', 'snapshot list returns an arrayref');
    is(scalar @$list, 2, 'snapshot list retains non-paginated response entries');
    isa_ok($list->[0], 'WWW::Hetzner::Storage::Snapshot');
    is($list->[0]->storage_box, 42, 'snapshot retains owning Storage Box id');
    ok(!$list->[0]->is_automatic, 'manual snapshot boolean');
    ok($list->[1]->is_automatic, 'automatic snapshot boolean');
    is_deeply($list->[0]->data->{stats}, {size => 2097152, size_filesystem => 1048576}, 'snapshot raw stats remain available');

    my $snapshot = $snapshots->get(1);
    isa_ok($snapshot, 'WWW::Hetzner::Storage::Snapshot');
    is($snapshot->name, '2025-02-12T11-35-19', 'snapshot name');

    my $empty = $snapshots->create;
    isa_ok($empty, 'WWW::Hetzner::Storage::Snapshot', 'snapshot create permits no optional fields');
    isa_ok($empty->action, 'WWW::Hetzner::Action', 'empty snapshot create attaches Action');
    is($empty->action->poll_path, '/storage_boxes/actions', 'snapshot create Action polls Storage global action path');
    $empty->action->wait(interval => 1, timeout => 1);

    my $created = $snapshots->create(description => 'manual backup', labels => {environment => 'test'});
    isa_ok($created, 'WWW::Hetzner::Storage::Snapshot', 'snapshot create with optional values returns entity');
    isa_ok($created->action, 'WWW::Hetzner::Action', 'snapshot create with optional values attaches Action');

    my $updated = $snapshots->update(1, description => 'updated backup', labels => {environment => 'updated'});
    isa_ok($updated, 'WWW::Hetzner::Storage::Snapshot', 'snapshot update returns entity');
    is($updated->description, 'updated backup', 'snapshot update returns updated description');

    $snapshot->description('entity backup');
    $snapshot->labels({environment => 'entity'});
    my $entity_updated = $snapshot->update;
    isa_ok($entity_updated, 'WWW::Hetzner::Storage::Snapshot', 'snapshot entity update returns entity');
    is($entity_updated->description, 'entity backup', 'snapshot entity update sends current description');

    my $deleted = $snapshots->delete(1);
    isa_ok($deleted, 'WWW::Hetzner::Action', 'snapshot delete returns Action');
    my $entity_deleted = $snapshot->delete;
    isa_ok($entity_deleted, 'WWW::Hetzner::Action', 'snapshot entity delete returns Action');

    is_deeply([map { [$_->[0], $_->[1], $_->[2]] } @seen], [
        ['POST', '/storage_boxes/42/snapshots', {}],
        ['POST', '/storage_boxes/42/snapshots', {description => 'manual backup', labels => {environment => 'test'}}],
        ['PUT', '/storage_boxes/42/snapshots/1', {description => 'updated backup', labels => {environment => 'updated'}}],
        ['PUT', '/storage_boxes/42/snapshots/1', {description => 'entity backup', labels => {environment => 'entity'}}],
        ['DELETE', '/storage_boxes/42/snapshots/1', undef],
        ['DELETE', '/storage_boxes/42/snapshots/1', undef],
    ], 'snapshot CRUD retains Storage Box and Snapshot IDs without invented parameters');
    isa_ok($seen[0][3], 'WWW::Hetzner::HTTPRequest', 'snapshot raw request is available');
};

done_testing;
