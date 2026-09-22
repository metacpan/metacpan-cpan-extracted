use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw(decode_json);
use lib 't/lib';

use Test::WWW::Hetzner::Mock;
use WWW::Hetzner::CLI::Cmd::Server::Cmd::Rescue;
use WWW::Hetzner::CLI::Cmd::Server::Cmd::Rebuild;

# Regression guard for karr #6: enable_rescue/rebuild's root_password sidecar
# was silently dropped and --output json died encoding a blessed Action, once
# those methods started returning WWW::Hetzner::Action instead of a
# raw {action=>..., root_password=>...} hash (Task 4). Exercises the real
# Cmd::execute($args, $chain) path against a mock_cloud, not the controller
# directly, so it fails the same way the CLI bug did.

# minimal $chain->[0] stand-in: only ->cloud and ->output are used by execute()
{
    package Test::FakeMain;
    sub new    { my ($class, %args) = @_; return bless { %args }, $class }
    sub cloud  { $_[0]->{cloud} }
    sub output { $_[0]->{output} }
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

subtest 'server rescue: root_password shown in text mode' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'enable_rescue';
    $fixture->{root_password} = 'rescue-pw-text';

    my $cloud = mock_cloud(
        'POST /servers/123456/actions/enable_rescue' => $fixture,
    );
    my $main = Test::FakeMain->new(cloud => $cloud, output => 'text');

    local @ARGV = ();
    my $cmd = WWW::Hetzner::CLI::Cmd::Server::Cmd::Rescue->new_with_options(wait => 0);

    my $out = capture_stdout(sub { $cmd->execute(['123456'], [$main]) });
    like($out, qr/Root password: rescue-pw-text/, 'root_password printed in text mode');
};

subtest 'server rescue: --output json does not die and carries root_password' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'enable_rescue';
    $fixture->{root_password} = 'rescue-pw-json';

    my $cloud = mock_cloud(
        'POST /servers/123456/actions/enable_rescue' => $fixture,
    );
    my $main = Test::FakeMain->new(cloud => $cloud, output => 'json');

    local @ARGV = ();
    my $cmd = WWW::Hetzner::CLI::Cmd::Server::Cmd::Rescue->new_with_options(wait => 0);

    my $out = eval { capture_stdout(sub { $cmd->execute(['123456'], [$main]) }) };
    ok(!$@, 'execute did not die encoding the Action to JSON') or diag("died with: $@");

    my ($json_line) = grep { /root_password/ } split /\n/, ($out // '');
    ok(defined $json_line, 'a JSON line with root_password was printed') or diag("captured: " . ($out // '<undef>'));

    my $decoded = eval { decode_json($json_line) };
    ok(!$@, 'printed line is valid JSON') or diag("decode failed: $@; line was: " . ($json_line // '<undef>'));
    is($decoded->{root_password}, 'rescue-pw-json', 'root_password survives --output json');
};

subtest 'server rebuild: root_password shown in text mode' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'rebuild';
    $fixture->{root_password} = 'rebuild-pw-text';

    my $cloud = mock_cloud(
        'POST /servers/123456/actions/rebuild' => $fixture,
    );
    my $main = Test::FakeMain->new(cloud => $cloud, output => 'text');

    local @ARGV = ('--image', 'debian-13');
    my $cmd = WWW::Hetzner::CLI::Cmd::Server::Cmd::Rebuild->new_with_options(wait => 0);

    my $out = capture_stdout(sub { $cmd->execute(['123456'], [$main]) });
    like($out, qr/Root password: rebuild-pw-text/, 'root_password printed in text mode');
};

subtest 'server rebuild: --output json does not die and carries root_password' => sub {
    my $fixture = load_fixture('servers_action');
    $fixture->{action}{command} = 'rebuild';
    $fixture->{root_password} = 'rebuild-pw-json';

    my $cloud = mock_cloud(
        'POST /servers/123456/actions/rebuild' => $fixture,
    );
    my $main = Test::FakeMain->new(cloud => $cloud, output => 'json');

    local @ARGV = ('--image', 'debian-13');
    my $cmd = WWW::Hetzner::CLI::Cmd::Server::Cmd::Rebuild->new_with_options(wait => 0);

    my $out = eval { capture_stdout(sub { $cmd->execute(['123456'], [$main]) }) };
    ok(!$@, 'execute did not die') or diag("died with: $@");

    my ($json_line) = grep { /root_password/ } split /\n/, ($out // '');
    ok(defined $json_line, 'a JSON line with root_password was printed') or diag("captured: " . ($out // '<undef>'));

    my $decoded = eval { decode_json($json_line) };
    ok(!$@, 'printed line is valid JSON') or diag("decode failed: $@; line was: " . ($json_line // '<undef>'));
    is($decoded->{root_password}, 'rebuild-pw-json', 'root_password survives --output json');
};

done_testing;
