use strict;
use warnings;
use Test::More;
use WWW::Hetzner::HTTPResponse;
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

sub action_response {
    my (%params) = @_;
    my $response = load_fixture('storage_box_actions_get');
    $response->{action}{id} = $params{id} if exists $params{id};
    $response->{action}{status} = $params{status} if exists $params{status};
    $response->{action}{progress} = $params{progress} if exists $params{progress};
    $response->{action}{error} = $params{error} if exists $params{error};
    return $response;
}

subtest 'Storage global and bound action controllers list, list_all, and get on documented paths' => sub {
    my $global_first = load_fixture('storage_box_actions_list');
    $global_first->{meta}{pagination}{per_page} = 1;
    $global_first->{meta}{pagination}{next_page} = 2;
    $global_first->{meta}{pagination}{last_page} = 2;
    $global_first->{meta}{pagination}{total_entries} = 2;
    my $global_second = load_fixture('storage_box_actions_list');
    $global_second->{actions}[0]{id} = 14;
    $global_second->{meta}{pagination} = {
        page => 2, per_page => 1, previous_page => 1, next_page => undef, last_page => 2, total_entries => 2,
    };
    my $bound_first = load_fixture('storage_box_actions_list');
    $bound_first->{actions}[0]{id} = 21;
    $bound_first->{meta}{pagination}{per_page} = 1;
    $bound_first->{meta}{pagination}{next_page} = 2;
    $bound_first->{meta}{pagination}{last_page} = 2;
    $bound_first->{meta}{pagination}{total_entries} = 2;
    my $bound_second = load_fixture('storage_box_actions_list');
    $bound_second->{actions}[0]{id} = 22;
    $bound_second->{meta}{pagination} = {
        page => 2, per_page => 1, previous_page => 1, next_page => undef, last_page => 2, total_entries => 2,
    };
    my @seen;
    my $storage = storage(
        'GET /storage_boxes/actions' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, [$path, $opts{params}, $opts{request}];
            my $page = ($opts{params} // {})->{page} // 1;
            return $page == 1 ? $global_first : $global_second;
        },
        'GET /storage_boxes/actions/13' => sub { load_fixture('storage_box_actions_get') },
        'GET /storage_boxes/42' => sub { load_fixture('storage_boxes_get') },
        'GET /storage_boxes/42/actions' => sub {
            my ($method, $path, %opts) = @_;
            push @seen, [$path, $opts{params}, $opts{request}];
            my $page = ($opts{params} // {})->{page} // 1;
            return $page == 1 ? $bound_first : $bound_second;
        },
    ) or return;
    my $actions = $storage->actions;
    isa_ok($actions, 'WWW::Hetzner::Storage::API::Actions');

    my $single = $actions->list(status => 'running', per_page => 1);
    is_deeply([map { $_->id } @$single], [13], 'global list remains a single page');

    @seen = ();
    my %params = (status => 'running', sort => ['id', 'command'], per_page => 1);
    my $all = $actions->list_all(%params);
    is_deeply([map { $_->id } @$all], [13, 14], 'global list_all follows Storage pagination');
    is_deeply([map { $_->[1] } @seen], [
        {status => 'running', sort => ['id', 'command'], per_page => '1'},
        {status => 'running', sort => ['id', 'command'], per_page => '1', page => '2'},
    ], 'global list_all retains filters, repeated sort, and per_page');
    isa_ok($seen[0][2], 'WWW::Hetzner::HTTPRequest', 'global action raw request is available');
    is_deeply(\%params, {status => 'running', sort => ['id', 'command'], per_page => 1}, 'global action list_all does not mutate params');

    my $global_action = $actions->get(13);
    isa_ok($global_action, 'WWW::Hetzner::Action');
    is($global_action->poll_path, '/storage_boxes/actions', 'global action uses Storage poll path');

    my $bound = $storage->storage_boxes->get(42)->actions;
    isa_ok($bound, 'WWW::Hetzner::Storage::API::Actions', 'Storage Box exposes a bound Actions controller');
    @seen = ();
    my $bound_single = $bound->list(status => 'running', per_page => 1);
    is_deeply([map { $_->id } @$bound_single], [21], 'bound list remains a single page');

    @seen = ();
    my %bound_params = (status => 'running', sort => ['id', 'command'], per_page => 1);
    my $bound_all = $bound->list_all(%bound_params);
    is_deeply([map { $_->id } @$bound_all], [21, 22], 'bound list_all follows Storage Box action pagination');
    is_deeply([map { $_->[0] } @seen], ['/storage_boxes/42/actions', '/storage_boxes/42/actions'], 'bound list_all stays on the Storage Box action collection');
    is_deeply([map { $_->[1] } @seen], [
        {status => 'running', sort => ['id', 'command'], per_page => '1'},
        {status => 'running', sort => ['id', 'command'], per_page => '1', page => '2'},
    ], 'bound list_all retains filters, repeated sort, and per_page');
    isa_ok($seen[0][2], 'WWW::Hetzner::HTTPRequest', 'bound action raw request is available');
    is_deeply(\%bound_params, {status => 'running', sort => ['id', 'command'], per_page => 1}, 'bound action list_all does not mutate params');

    my $bound_action = $bound->get(13);
    isa_ok($bound_action, 'WWW::Hetzner::Action', 'bound get returns an Action');
    is($bound_action->poll_path, '/storage_boxes/actions', 'bound get uses global Storage action polling');
};

subtest 'Storage Actions poll only /storage_boxes/actions and never sleep for terminal actions' => sub {
    my @paths;
    my $storage = storage(
        'GET /storage_boxes/actions/13' => sub {
            my ($method, $path, %opts) = @_;
            push @paths, $path;
            return action_response(id => 13, status => 'success', progress => 100, error => undef);
        },
    ) or return;
    my $sleeps = 0;
    $storage->sleeper(sub { $sleeps++ });
    my $action = $storage->actions->get(13);
    $action->refresh;
    is($action->status, 'success', 'refresh receives terminal Storage action status');
    is_deeply(\@paths, [
        '/storage_boxes/actions/13',
        '/storage_boxes/actions/13',
    ], 'get and refresh never use global Cloud or deprecated per-box action paths');
    $action->wait(interval => 1, timeout => 1);
    is($sleeps, 0, 'already terminal action does not sleep');
};

subtest 'Storage Action wait covers running success, API failure, action failure, and timeout without real sleep' => sub {
    my %calls;
    my $storage = storage(
        'GET /storage_boxes/actions/13' => sub {
            $calls{success}++;
            return action_response(id => 13,
                status => $calls{success} == 1 ? 'running' : 'success',
                progress => $calls{success} == 1 ? 50 : 100,
                error => undef,
            );
        },
        'GET /storage_boxes/actions/14' => sub {
            return WWW::Hetzner::HTTPResponse->new(
                status => 500, content => '{"error":{"message":"Storage polling unavailable"}}',
            );
        },
        'GET /storage_boxes/actions/15' => sub {
            return action_response(id => 15, status => 'error', progress => 100,
                error => {code => 'action_failed', message => 'Storage action failed'});
        },
        'GET /storage_boxes/actions/16' => sub {
            $calls{timeout}++;
            return action_response(id => 16, status => 'running', progress => 50, error => undef);
        },
    ) or return;
    my $sleeps = 0;
    $storage->sleeper(sub { $sleeps++ });

    my $success = $storage->actions->get(13);
    $success->wait(interval => 1, timeout => 2);
    is($success->status, 'success', 'running Storage action reaches success');
    is($calls{success}, 2, 'success action polled via Storage path until terminal');

    my ($api_result, $api_error) = attempt(sub { $storage->actions->get(14)->wait(interval => 1, timeout => 1) });
    ok(!defined $api_result, 'poll API failure returns no action result');
    like($api_error, qr/Storage polling unavailable/, 'poll API failure propagates its message');

    my ($failed_result, $failed_error) = attempt(sub { $storage->actions->get(15)->wait(interval => 1, timeout => 1) });
    ok(!defined $failed_result, 'failed action returns no success result');
    like($failed_error, qr/Storage action failed/, 'failed action error propagates its message');

    my ($timeout_result, $timeout_error) = attempt(sub { $storage->actions->get(16)->wait(interval => 1, timeout => 1) });
    ok(!defined $timeout_result, 'timed out action returns no success result');
    like($timeout_error, qr/Timed out waiting for action 16/, 'timeout is reported');
    is($calls{timeout}, 2, 'timeout polls once after its initial action fetch before the deadline');
    is($sleeps, 2, 'all wait paths use the injected sleeper and never real sleep');
};

done_testing;
