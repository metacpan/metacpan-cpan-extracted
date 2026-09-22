use strict;
use warnings;
use Test::More;
use lib 't/lib';
use Test::WWW::Hetzner::Mock;

sub attempt {
    my ($code) = @_;
    my ($result, $error);
    my $ok = eval {
        $result = $code->();
        1;
    };
    $error = $@ unless $ok;
    return ($result, $error // '');
}

sub storage {
    my (%routes) = @_;
    my ($client, $error) = attempt(sub { mock_storage(%routes) });
    ok($client, 'Storage client is available') or do {
        diag($error);
        return;
    };
    return $client;
}

subtest 'Storage boxes list, get, folders, entity data, and nullable values' => sub {
    my $storage = storage(
        'GET /storage_boxes'            => sub { load_fixture('storage_boxes_list') },
        'GET /storage_boxes/42'         => sub { load_fixture('storage_boxes_get') },
        'GET /storage_boxes/42/folders' => sub { load_fixture('storage_boxes_folders') },
    ) or return;

    my $boxes = $storage->storage_boxes;
    isa_ok($boxes, 'WWW::Hetzner::Storage::API::StorageBoxes');

    my $list = $boxes->list(per_page => 25);
    is(ref $list, 'ARRAY', 'list returns an arrayref');
    is(scalar @$list, 1, 'list returns one page');
    isa_ok($list->[0], 'WWW::Hetzner::Storage::StorageBox');
    is($list->[0]->id, 42, 'Storage Box id');
    is($list->[0]->name, 'my-resource', 'Storage Box name');
    is($list->[0]->storage_box_type->{name}, 'bx20', 'nested type data remains available');
    is($list->[0]->location->{name}, 'fsn1', 'nested location data remains available');
    is($list->[0]->snapshot_plan, undef, 'nullable snapshot_plan remains undef');
    is($list->[0]->server, undef, 'nullable server remains undef');
    is($list->[0]->system, undef, 'nullable system remains undef');
    is_deeply($list->[0]->data->{stats}, {size => 0, size_data => 0, size_snapshots => 0}, 'data retains raw stats');

    my $box = $boxes->get(42);
    isa_ok($box, 'WWW::Hetzner::Storage::StorageBox');
    is_deeply($box->access_settings, {
        reachable_externally => 0, samba_enabled => 0, ssh_enabled => 0,
        webdav_enabled => 0, zfs_enabled => 0,
    }, 'access settings survive wrapping');
    is_deeply($boxes->folders(42), ['offsite-backup', 'photos'], 'folders returns an arrayref of strings');
    isa_ok($box->subaccounts, 'WWW::Hetzner::Storage::API::Subaccounts', 'Storage Box exposes nested subaccounts');
    isa_ok($box->snapshots, 'WWW::Hetzner::Storage::API::Snapshots', 'Storage Box exposes nested snapshots');
};

subtest 'Storage Box create, update, entity update, and delete follow their result contracts' => sub {
    my @seen;
    my $storage = storage(
        'POST /storage_boxes' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, [$method, $path, $opts{body}, $opts{request}];
            return load_fixture('storage_boxes_create');
        },
        'PUT /storage_boxes/42' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, [$method, $path, $opts{body}, $opts{request}];
            my $result = load_fixture('storage_boxes_get');
            $result->{storage_box}{name} = $opts{body}{name} if exists $opts{body}{name};
            $result->{storage_box}{labels} = $opts{body}{labels} if exists $opts{body}{labels};
            return $result;
        },
        'GET /storage_boxes/42' => sub { load_fixture('storage_boxes_get') },
        'GET /storage_boxes/actions/13' => sub {
            my $response = load_fixture('storage_boxes_action');
            $response->{action}{status} = 'success';
            $response->{action}{progress} = 100;
            return $response;
        },
        'DELETE /storage_boxes/42' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, [$method, $path, $opts{body}, $opts{request}];
            return load_fixture('storage_boxes_action');
        },
    ) or return;
    $storage->sleeper(sub { });
    my $boxes = $storage->storage_boxes;

    my $created = $boxes->create(
        name => 'my-resource', location => 'fsn1', storage_box_type => 'bx20', password => 'secret-password',
        labels => { environment => 'prod' }, ssh_keys => ['ssh-ed25519 AAAA'],
        access_settings => { ssh_enabled => 1 },
    );
    isa_ok($created, 'WWW::Hetzner::Storage::StorageBox', 'create returns a Storage Box');
    isa_ok($created->action, 'WWW::Hetzner::Action', 'create attaches its Action');
    is($created->action->poll_path, '/storage_boxes/actions', 'create Action polls the Storage action endpoint');
    $created->action->wait(interval => 1, timeout => 1);
    ok(!exists $created->data->{password}, 'create password is input-only and never returned in entity data');

    my $updated = $boxes->update(42, name => 'renamed', labels => { environment => 'test' });
    isa_ok($updated, 'WWW::Hetzner::Storage::StorageBox', 'controller update returns an entity');
    is($updated->name, 'renamed', 'controller update returns updated data');
    ok(!$updated->can('action') || !defined $updated->action, 'update does not invent an Action');

    my $entity = $boxes->get(42);
    $entity->name('entity-renamed');
    $entity->labels({ environment => 'entity' });
    my $entity_updated = $entity->update;
    isa_ok($entity_updated, 'WWW::Hetzner::Storage::StorageBox', 'entity update returns an entity');
    is($entity_updated->name, 'entity-renamed', 'entity update sends current name');

    my $deleted = $boxes->delete(42);
    isa_ok($deleted, 'WWW::Hetzner::Action', 'controller delete returns its Action');
    my $entity_deleted = $entity->delete;
    isa_ok($entity_deleted, 'WWW::Hetzner::Action', 'entity delete returns its Action');

    is_deeply([ map { [$_->[0], $_->[1], $_->[2]] } @seen ], [
        ['POST', '/storage_boxes', {
            name => 'my-resource', location => 'fsn1', storage_box_type => 'bx20', password => 'secret-password',
            labels => { environment => 'prod' }, ssh_keys => ['ssh-ed25519 AAAA'], access_settings => { ssh_enabled => 1 },
        }],
        ['PUT', '/storage_boxes/42', {name => 'renamed', labels => {environment => 'test'}}],
        ['PUT', '/storage_boxes/42', {name => 'entity-renamed', labels => {environment => 'entity'}}],
        ['DELETE', '/storage_boxes/42', undef],
        ['DELETE', '/storage_boxes/42', undef],
    ], 'CRUD paths and JSON bodies follow the Storage API contract');
    isa_ok($seen[0][3], 'WWW::Hetzner::HTTPRequest', 'create raw request is available independently of callback body');
};

subtest 'Storage Box validates all required create fields before any request' => sub {
    my $storage = storage() or return;
    my $boxes = $storage->storage_boxes;

    for my $required (qw(name location storage_box_type password)) {
        my %params = (
            name => 'my-resource', location => 'fsn1', storage_box_type => 'bx20', password => 'secret-password',
        );
        delete $params{$required};
        my ($result, $error) = attempt(sub { $boxes->create(%params) });
        ok(!defined $result, "create without $required returns no entity");
        like($error, qr/\Q$required\E.*required/i, "create requires $required");
    }
};

subtest 'all seven Storage Box action endpoints use documented paths and bodies' => sub {
    my @seen;
    my $storage = storage(
        '/storage_boxes/42/actions/.*' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, [$method, $path, $opts{body}, $opts{request}];
            my $response = load_fixture('storage_boxes_action');
            ($response->{action}{command} = $path) =~ s{.*/}{};
            return $response;
        },
    ) or return;
    my $boxes = $storage->storage_boxes;

    my @actions = (
        $boxes->change_protection(42, delete => 1),
        $boxes->change_type(42, storage_box_type => 'bx11'),
        $boxes->reset_password(42, password => 'new-secret'),
        $boxes->update_access_settings(42, reachable_externally => 1, samba_enabled => 1, ssh_enabled => 1, webdav_enabled => 0, zfs_enabled => 1),
        $boxes->rollback_snapshot(42, snapshot => 7),
        $boxes->enable_snapshot_plan(42, max_snapshots => 3, minute => 0, hour => 2, day_of_week => 1, day_of_month => 15),
        $boxes->disable_snapshot_plan(42),
    );
    isa_ok($_, 'WWW::Hetzner::Action', 'Storage action returns an Action') for @actions;
    is($_->poll_path, '/storage_boxes/actions', 'Storage action polls the global Storage path') for @actions;

    is_deeply([ map { [$_->[0], $_->[1], $_->[2]] } @seen ], [
        ['POST', '/storage_boxes/42/actions/change_protection', {delete => 1}],
        ['POST', '/storage_boxes/42/actions/change_type', {storage_box_type => 'bx11'}],
        ['POST', '/storage_boxes/42/actions/reset_password', {password => 'new-secret'}],
        ['POST', '/storage_boxes/42/actions/update_access_settings', {reachable_externally => 1, samba_enabled => 1, ssh_enabled => 1, webdav_enabled => 0, zfs_enabled => 1}],
        ['POST', '/storage_boxes/42/actions/rollback_snapshot', {snapshot => 7}],
        ['POST', '/storage_boxes/42/actions/enable_snapshot_plan', {max_snapshots => 3, minute => 0, hour => 2, day_of_week => 1, day_of_month => 15}],
        ['POST', '/storage_boxes/42/actions/disable_snapshot_plan', {}],
    ], 'all documented Storage Box actions use their exact endpoint and body');
    isa_ok($seen[0][3], 'WWW::Hetzner::HTTPRequest', 'action raw request is available independently of mock decoding');
};

subtest 'Storage Box list_all and get_by_name use documented pagination without changing caller params' => sub {
    my $first = load_fixture('storage_boxes_list');
    $first->{meta}{pagination}{per_page} = 1;
    $first->{meta}{pagination}{next_page} = 2;
    $first->{meta}{pagination}{last_page} = 2;
    $first->{meta}{pagination}{total_entries} = 2;
    my $second = load_fixture('storage_boxes_list');
    $second->{storage_boxes}[0]{id} = 43;
    $second->{storage_boxes}[0]{name} = 'target-storage-box';
    $second->{meta}{pagination} = {
        page => 2, per_page => 1, previous_page => 1, next_page => undef, last_page => 2, total_entries => 2,
    };
    my @seen;
    my $storage = storage(
        'GET /storage_boxes' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, [$opts{params}, $opts{request}];
            my $page = ($opts{params} // {})->{page} // 1;
            return $page == 1 ? $first : $second;
        },
    ) or return;
    my $boxes = $storage->storage_boxes;

    my $single = $boxes->list(per_page => 1);
    is_deeply([map { $_->id } @$single], [42], 'list stays a one-page request');

    @seen = ();
    my %params = (label_selector => 'environment=prod', sort => ['id', 'name:asc'], per_page => 1);
    my $all = $boxes->list_all(%params);
    is_deeply([map { $_->id } @$all], [42, 43], 'list_all collects every Box page');
    is_deeply([map { $_->[0] } @seen], [
        {label_selector => 'environment=prod', sort => ['id', 'name:asc'], per_page => '1'},
        {label_selector => 'environment=prod', sort => ['id', 'name:asc'], per_page => '1', page => '2'},
    ], 'list_all retains Box filters, repeated sort, and per_page');
    isa_ok($seen[0][1], 'WWW::Hetzner::HTTPRequest', 'Box pagination raw request is available');
    is_deeply(\%params, {label_selector => 'environment=prod', sort => ['id', 'name:asc'], per_page => 1}, 'Box list_all leaves caller params untouched');

    @seen = ();
    my $named = $boxes->get_by_name('target-storage-box');
    isa_ok($named, 'WWW::Hetzner::Storage::StorageBox', 'get_by_name returns a Storage Box');
    is($named->id, 43, 'get_by_name searches the second page');
    is_deeply([map { $_->[0] } @seen], [
        {name => 'target-storage-box'},
        {name => 'target-storage-box', page => '2'},
    ], 'get_by_name preserves name filter over pagination');
};

done_testing;
