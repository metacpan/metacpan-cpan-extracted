use strict; use warnings;
use Test::More;
use lib 't/lib';
use Test::WWW::Hetzner::Mock;

# 1. attributes + predicates from fixture
my $cloud = mock_cloud('GET /actions/13343' => sub { load_fixture('actions_get') });
my $a = $cloud->actions->get(13343);
isa_ok($a, 'WWW::Hetzner::Action');
is($a->command, 'poweron', 'command');
ok($a->is_running, 'is_running');
ok(!$a->is_success && !$a->is_error, 'not terminal');

# 2. list() wraps every action from the fixture (regression guard for _wrap_list
#    reading the wrong top-level key, or the fixture going unused)
{
    my $c = mock_cloud('GET /actions' => sub { load_fixture('actions_list') });
    my $list = $c->actions->list(status => 'running');
    is(ref $list, 'ARRAY', 'list returns an arrayref');
    is(scalar @$list, 3, 'three actions from the fixture');
    isa_ok($_, 'WWW::Hetzner::Action') for @$list;
    my ($errored) = grep { $_->is_error } @$list;
    ok($errored, 'one action in the list is_error');
    is($errored->error_message, 'server does not exist',
        'error_message carries the fixture message through _wrap_list');
}

# 3. wait success path: running -> running -> success, counting polls via sleeper
{
    my @states = ('running', 'running', 'success');
    my $i = 0;
    my $c = mock_cloud('GET /actions/1' => sub {
        my $s = $states[$i] // 'success'; $i++;
        return { action => { id => 1, command => 'create_server', status => $s,
                             progress => ($s eq 'success' ? 100 : 0), error => undef } };
    });
    my @slept;
    $c->sleeper(sub { push @slept, $_[0] });
    my $act = $c->actions->get(1);   # first GET -> running
    $act->wait(interval => 5);
    ok($act->is_success, 'wait resolves to success');
    is_deeply(\@slept, [5, 5], 'slept between polls, no real seconds');
}

# 4. wait error path croaks with the API message
{
    my $c = mock_cloud('GET /actions/2' => sub {
        { action => { id => 2, command => 'create_server', status => 'error',
                      error => { code => 'x', message => 'boom' } } };
    });
    my $act = $c->actions->get(2);
    eval { $act->wait; 1 };
    like($@, qr/boom/, 'wait croaks with error.message');
}

# 5. wait timeout croaks with id + command
{
    my $c = mock_cloud('GET /actions/3' => sub {
        { action => { id => 3, command => 'create_server', status => 'running', error => undef } };
    });
    $c->sleeper(sub {});   # no real sleep
    my $act = $c->actions->get(3);
    eval { $act->wait(interval => 1, timeout => 3); 1 };
    like($@, qr/\b3\b.*create_server|create_server.*\b3\b/, 'timeout names id and command');
}

# 6. HasActions role: _wrap_action / _wrap_actions, via a throwaway consumer
{
    package My::WrapTest;
    use Moo;
    has client => (is => 'ro');
    with 'WWW::Hetzner::Role::HasActions';
}
{
    my $w = My::WrapTest->new(client => $cloud);
    is($w->_wrap_action(undef), undef, 'undef action -> undef');
    my $plain = $w->_wrap_action({ id => 5, status => 'running' });
    isa_ok($plain, 'WWW::Hetzner::Action');
    is($plain->root_password, undef, '_wrap_action: no sidecar -> root_password undef');
    is_deeply($plain->result, {}, '_wrap_action: result defaults to {}');
    is(scalar @{ $w->_wrap_actions([{id=>1,status=>'running'},{id=>2,status=>'success'}]) }, 2, 'plural');
    is_deeply($w->_wrap_actions(undef), [], 'undef list -> empty arrayref');
}

# 7. HasActions role: _wrap_action_result carries sidecar fields on the Action
{
    my $w = My::WrapTest->new(client => $cloud);
    is($w->_wrap_action_result({}), undef, 'no action key -> undef');

    my $wrapped = $w->_wrap_action_result({
        action        => { id => 9, command => 'reset_password', status => 'running' },
        root_password => 'pw123',
    });
    isa_ok($wrapped, 'WWW::Hetzner::Action');
    is($wrapped->id, 9, 'action fields still set');
    is($wrapped->root_password, 'pw123', 'sidecar preserved via _wrap_action_result');
    is_deeply($wrapped->result, { root_password => 'pw123' },
        'result holds only the sidecar, not the action key');
}

done_testing;
