use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;
use WWW::Hetzner::CLI::Cmd::Server::Cmd::Delete;
use WWW::Hetzner::CLI::Cmd::Zone::Cmd::Delete;
use WWW::Hetzner::CLI::Cmd::Record::Cmd::Delete;

# Regression guard for karr #7: the three Cloud DELETE endpoints that answer
# with an {action} -- DELETE /servers/{id}, DELETE /zones/{id_or_name} and
# DELETE /zones/{id}/rrsets/{name}/{type} -- used to have their action
# discarded, so `hcloud.pl ... delete` could not wait for the deletion.
# Exercises the real Cmd::execute($args, $chain) path against a mock_cloud.
#
# Each --no-wait subtest deliberately registers NO 'GET /actions/<id>' route:
# if the command polled anyway, MockIO dies with "No mock route for" and the
# test fails loudly instead of silently passing.

# minimal $chain->[0] stand-in: only ->cloud is used by these execute()s
{
    package Test::FakeMain;
    sub new   { my ($class, %args) = @_; return bless { %args }, $class }
    sub cloud { $_[0]->{cloud} }
}

# redirect STDOUT for the duration of $code->(), return what it printed;
# propagates any exception $code->() throws after restoring STDOUT
sub capture_stdout {
    my ($code) = @_;
    my $buf = '';
    open(my $capture, '>', \$buf) or die "can't open scalar filehandle: $!";
    my $old_fh = select($capture);
    my $ok = eval { $code->(); 1 };
    my $err = $@;
    select($old_fh);
    close($capture);
    die $err unless $ok;
    return $buf;
}

# a terminal copy of an action fixture, for the polling response
sub finished_action {
    my ($name) = @_;
    my $fixture = load_fixture($name);
    $fixture->{action}{status}   = 'success';
    $fixture->{action}{progress} = 100;
    return $fixture;
}

subtest 'server delete: --no-wait does not poll the action' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'delete_server';

    my $cloud = mock_cloud(
        'DELETE /servers/123456' => $fixture,
    );
    my $main = Test::FakeMain->new(cloud => $cloud);

    local @ARGV = ('--no-wait');
    my $cmd = WWW::Hetzner::CLI::Cmd::Server::Cmd::Delete->new_with_options;
    ok($cmd->no_wait, '--no-wait reached the command');

    my $out = capture_stdout(sub { $cmd->execute(['123456'], [$main]) });
    like($out, qr/Delete requested\./, 'reports the request, not completion');
    unlike($out, qr/Server deleted\./, 'does not claim the server is gone');
};

subtest 'server delete: default path waits for the action' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'delete_server';

    my $cloud = mock_cloud(
        'DELETE /servers/123456' => $fixture,
        'GET /actions/13343'     => sub { finished_action('servers_action') },
    );
    my @slept;
    $cloud->sleeper(sub { push @slept, $_[0] });
    my $main = Test::FakeMain->new(cloud => $cloud);

    local @ARGV = ();
    my $cmd = WWW::Hetzner::CLI::Cmd::Server::Cmd::Delete->new_with_options;
    ok(!$cmd->no_wait, 'waiting is the default');

    my $out = capture_stdout(sub { $cmd->execute(['123456'], [$main]) });
    is_deeply(\@slept, [1], 'polled once, no real seconds slept');
    like($out, qr/Server deleted\./, 'reports completion after the action finished');
};

subtest 'zone delete: --no-wait does not poll the action' => sub {
    my $cloud = mock_cloud(
        'DELETE /zones/zone123456' => sub { load_fixture('zones_action') },
    );
    my $main = Test::FakeMain->new(cloud => $cloud);

    local @ARGV = ('--no-wait');
    my $cmd = WWW::Hetzner::CLI::Cmd::Zone::Cmd::Delete->new_with_options;

    my $out = capture_stdout(sub { $cmd->execute(['zone123456'], [$main]) });
    like($out, qr/delete requested\./, 'reports the request, not completion');
};

subtest 'zone delete: default path waits for the action' => sub {
    my $cloud = mock_cloud(
        'DELETE /zones/zone123456' => sub { load_fixture('zones_action') },
        'GET /actions/9101'        => sub { finished_action('zones_action') },
    );
    my @slept;
    $cloud->sleeper(sub { push @slept, $_[0] });
    my $main = Test::FakeMain->new(cloud => $cloud);

    local @ARGV = ();
    my $cmd = WWW::Hetzner::CLI::Cmd::Zone::Cmd::Delete->new_with_options;

    my $out = capture_stdout(sub { $cmd->execute(['zone123456'], [$main]) });
    is_deeply(\@slept, [1], 'polled once, no real seconds slept');
    like($out, qr/Zone zone123456 deleted\./, 'reports completion after the action finished');
};

subtest 'record delete: --no-wait does not poll the action' => sub {
    my $cloud = mock_cloud(
        'DELETE /zones/zone123456/rrsets/www/A' => sub { load_fixture('rrsets_action') },
    );
    my $main = Test::FakeMain->new(cloud => $cloud);

    local @ARGV = ('--zone', 'zone123456', '--name', 'www', '--type', 'a', '--no-wait');
    my $cmd = WWW::Hetzner::CLI::Cmd::Record::Cmd::Delete->new_with_options;

    my $out = capture_stdout(sub { $cmd->execute([], [$main]) });
    like($out, qr{Record www/A delete requested\.}, 'reports the request, not completion');
};

subtest 'record delete: default path waits for the action' => sub {
    my $cloud = mock_cloud(
        'DELETE /zones/zone123456/rrsets/www/A' => sub { load_fixture('rrsets_action') },
        'GET /actions/9102'                     => sub { finished_action('rrsets_action') },
    );
    my @slept;
    $cloud->sleeper(sub { push @slept, $_[0] });
    my $main = Test::FakeMain->new(cloud => $cloud);

    local @ARGV = ('--zone', 'zone123456', '--name', 'www', '--type', 'a');
    my $cmd = WWW::Hetzner::CLI::Cmd::Record::Cmd::Delete->new_with_options;

    my $out = capture_stdout(sub { $cmd->execute([], [$main]) });
    is_deeply(\@slept, [1], 'polled once, no real seconds slept');
    like($out, qr{Record www/A deleted\.}, 'reports completion after the action finished');
};

done_testing;
