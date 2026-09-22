use strict; use warnings;
use Test::More;

use WWW::Hetzner::CLI::Role::WaitsForAction;

# throwaway Action stand-in: records whether/how often ->wait was called
{
    package My::FakeAction;
    sub new  { my $class = shift; return bless { waited => 0 }, $class; }
    sub wait { $_[0]->{waited}++; return $_[0]; }
}

# throwaway CLI command consuming the role, mirroring how real Cmd classes do it
{
    package My::WaitsTestCmd;
    use Moo;
    use MooX::Options protect_argv => 0;
    with 'WWW::Hetzner::CLI::Role::WaitsForAction';
}

# 1. default (no --no-wait): handle_action waits
{
    local @ARGV = ();
    my $cmd = My::WaitsTestCmd->new_with_options;
    ok(!$cmd->no_wait, 'no_wait is false by default');

    my $action = My::FakeAction->new;
    my $ret = $cmd->handle_action($action);
    is($action->{waited}, 1, 'wait was called by default');
    is($ret, $action, 'handle_action returns the action on success');
}

# 2. --no-wait: handle_action returns immediately, never calls wait
{
    local @ARGV = ('--no-wait');
    my $cmd = My::WaitsTestCmd->new_with_options;
    ok($cmd->no_wait, '--no-wait sets no_wait true');

    my $action = My::FakeAction->new;
    my $ret = $cmd->handle_action($action);
    is($action->{waited}, 0, 'wait was NOT called with --no-wait');
    is($ret, undef, 'handle_action returns nothing when skipping');
}

# 3. non-Action / undef args are a no-op, regardless of no_wait
{
    my $cmd = My::WaitsTestCmd->new;
    is($cmd->handle_action(undef), undef, 'undef is a no-op');
    is($cmd->handle_action({}), undef, 'a plain hashref without ->wait is a no-op');
}

# 4. arrayref of actions (Firewall's plural methods): waits on each element
{
    local @ARGV = ();
    my $cmd = My::WaitsTestCmd->new_with_options;
    my @actions = map { My::FakeAction->new } (1 .. 3);
    $cmd->handle_action(\@actions);
    is($_->{waited}, 1, 'each action in the arrayref was waited on') for @actions;
}
{
    local @ARGV = ('--no-wait');
    my $cmd = My::WaitsTestCmd->new_with_options;
    my @actions = map { My::FakeAction->new } (1 .. 3);
    $cmd->handle_action(\@actions);
    is($_->{waited}, 0, '--no-wait skips waiting on every action in the arrayref') for @actions;
}

done_testing;
