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

subtest 'Subaccounts use their Storage Box nested paths for CRUD' => sub {
    my @seen;
    my $storage = storage(
        'GET /storage_boxes/42' => sub { load_fixture('storage_boxes_get') },
        'GET /storage_boxes/42/subaccounts' => sub { load_fixture('storage_box_subaccounts_list') },
        'GET /storage_boxes/42/subaccounts/42' => sub { load_fixture('storage_box_subaccounts_get') },
        'POST /storage_boxes/42/subaccounts' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, [$method, $path, $opts{body}, $opts{request}];
            return load_fixture('storage_box_subaccounts_create');
        },
        'PUT /storage_boxes/42/subaccounts/42' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, [$method, $path, $opts{body}, $opts{request}];
            my $response = load_fixture('storage_box_subaccounts_get');
            $response->{subaccount}{$_} = $opts{body}{$_} for keys %{$opts{body}};
            return $response;
        },
        'DELETE /storage_boxes/42/subaccounts/42' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, [$method, $path, $opts{body}, $opts{request}];
            return load_fixture('storage_box_subaccounts_action');
        },
        'GET /storage_boxes/actions/13' => sub {
            my $response = load_fixture('storage_box_subaccounts_action');
            $response->{action}{status} = 'success';
            $response->{action}{progress} = 100;
            return $response;
        },
    ) or return;
    $storage->sleeper(sub { });
    my $subaccounts = $storage->storage_boxes->get(42)->subaccounts;
    isa_ok($subaccounts, 'WWW::Hetzner::Storage::API::Subaccounts');

    my $list = $subaccounts->list;
    is(ref $list, 'ARRAY', 'subaccount list returns an arrayref');
    isa_ok($list->[0], 'WWW::Hetzner::Storage::Subaccount');
    is($list->[0]->home_directory, 'my_backups/host01.my.company', 'subaccount home directory');
    is_deeply($list->[0]->data->{access_settings}, {
        samba_enabled => 0, ssh_enabled => 1, webdav_enabled => 0,
        reachable_externally => 1, readonly => 0,
    }, 'subaccount raw access settings remain available');

    my $subaccount = $subaccounts->get(42);
    isa_ok($subaccount, 'WWW::Hetzner::Storage::Subaccount');
    is($subaccount->storage_box, 42, 'nested subaccount retains owning Storage Box id');

    my $created = $subaccounts->create(
        home_directory => 'my_backups/host02.my.company', password => 'subaccount-secret',
        name => 'host02', description => 'host02 backup', labels => {environment => 'test'},
        access_settings => {ssh_enabled => 1},
    );
    isa_ok($created, 'WWW::Hetzner::Storage::Subaccount', 'subaccount create returns entity');
    isa_ok($created->action, 'WWW::Hetzner::Action', 'subaccount create attaches Action');
    is($created->action->poll_path, '/storage_boxes/actions', 'subaccount create Action polls Storage global action path');
    ok(!exists $created->data->{password}, 'subaccount password is input-only');
    $created->action->wait(interval => 1, timeout => 1);

    my $updated = $subaccounts->update(42,
        name => 'host02-renamed', description => 'updated backup', labels => {environment => 'updated'},
    );
    isa_ok($updated, 'WWW::Hetzner::Storage::Subaccount', 'subaccount update returns entity');
    is($updated->name, 'host02-renamed', 'subaccount update returns updated name');

    $subaccount->name('entity-renamed');
    $subaccount->description('entity backup');
    $subaccount->labels({environment => 'entity'});
    my $entity_updated = $subaccount->update;
    isa_ok($entity_updated, 'WWW::Hetzner::Storage::Subaccount', 'subaccount entity update returns entity');
    is($entity_updated->name, 'entity-renamed', 'subaccount entity update sends current name');

    my $deleted = $subaccounts->delete(42);
    isa_ok($deleted, 'WWW::Hetzner::Action', 'subaccount delete returns Action');
    my $entity_deleted = $subaccount->delete;
    isa_ok($entity_deleted, 'WWW::Hetzner::Action', 'subaccount entity delete returns Action');

    is_deeply([map { [$_->[0], $_->[1], $_->[2]] } @seen], [
        ['POST', '/storage_boxes/42/subaccounts', {
            home_directory => 'my_backups/host02.my.company', password => 'subaccount-secret',
            name => 'host02', description => 'host02 backup', labels => {environment => 'test'}, access_settings => {ssh_enabled => 1},
        }],
        ['PUT', '/storage_boxes/42/subaccounts/42', {
            name => 'host02-renamed', description => 'updated backup', labels => {environment => 'updated'},
        }],
        ['PUT', '/storage_boxes/42/subaccounts/42', {
            name => 'entity-renamed', description => 'entity backup', labels => {environment => 'entity'},
        }],
        ['DELETE', '/storage_boxes/42/subaccounts/42', undef],
        ['DELETE', '/storage_boxes/42/subaccounts/42', undef],
    ], 'subaccount CRUD uses exact nested paths and JSON bodies');
    isa_ok($seen[0][3], 'WWW::Hetzner::HTTPRequest', 'subaccount create raw request is available');
};

subtest 'Subaccount create validates home_directory and password before any request' => sub {
    my $storage = storage(
        'GET /storage_boxes/42' => sub { load_fixture('storage_boxes_get') },
    ) or return;
    my $subaccounts = $storage->storage_boxes->get(42)->subaccounts;

    for my $required (qw(home_directory password)) {
        my %params = (home_directory => 'my_backups/host04', password => 'subaccount-secret');
        delete $params{$required};
        my ($result, $error) = attempt(sub { $subaccounts->create(%params) });
        ok(!defined $result, "subaccount create without $required returns no entity");
        like($error, qr/\Q$required\E.*required/i, "subaccount create requires $required");
    }
};

subtest 'Subaccount actions use documented nested IDs and password remains input-only' => sub {
    my @seen;
    my $storage = storage(
        'GET /storage_boxes/42' => sub { load_fixture('storage_boxes_get') },
        '/storage_boxes/42/subaccounts/42/actions/.*' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, [$method, $path, $opts{body}, $opts{request}];
            my $response = load_fixture('storage_box_subaccounts_action');
            ($response->{action}{command} = $path) =~ s{.*/}{};
            return $response;
        },
    ) or return;
    my $subaccounts = $storage->storage_boxes->get(42)->subaccounts;

    my @actions = (
        $subaccounts->change_home_directory(42, home_directory => 'my_backups/host03.my.company'),
        $subaccounts->reset_subaccount_password(42, password => 'new-subaccount-secret'),
        $subaccounts->update_access_settings(42,
            readonly => 1, reachable_externally => 0, samba_enabled => 0, ssh_enabled => 1, webdav_enabled => 0,
        ),
    );
    isa_ok($_, 'WWW::Hetzner::Action', 'subaccount action returns Action') for @actions;
    is($_->poll_path, '/storage_boxes/actions', 'subaccount action polls Storage global action path') for @actions;

    is_deeply([map { [$_->[0], $_->[1], $_->[2]] } @seen], [
        ['POST', '/storage_boxes/42/subaccounts/42/actions/change_home_directory', {home_directory => 'my_backups/host03.my.company'}],
        ['POST', '/storage_boxes/42/subaccounts/42/actions/reset_subaccount_password', {password => 'new-subaccount-secret'}],
        ['POST', '/storage_boxes/42/subaccounts/42/actions/update_access_settings', {
            readonly => 1, reachable_externally => 0, samba_enabled => 0, ssh_enabled => 1, webdav_enabled => 0,
        }],
    ], 'subaccount action endpoints retain both Storage Box and Subaccount IDs');
    isa_ok($seen[1][3], 'WWW::Hetzner::HTTPRequest', 'password-reset raw request is available');
    ok(!exists $actions[1]->data->{password}, 'password reset Action does not expose the submitted password');
};

done_testing;
