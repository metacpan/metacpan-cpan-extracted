use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw(decode_json);
use lib 't/lib';

use Test::WWW::Hetzner::Mock;
use WWW::Hetzner::Robot::CLI::Cmd::Boot;
use WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Rescue;
use WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Linux;
use WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Vnc;
use WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Windows;
use WWW::Hetzner::Robot::CLI::Cmd::Rdns;
use WWW::Hetzner::Robot::CLI::Cmd::Failover;

# Exercises the real Cmd::execute($args, $chain) path of the boot, rdns and
# failover commands against a mock_robot, so the CLI surface is covered the
# same way t/cli_server_rescue.t covers the Cloud one. Nothing here talks to
# the network.

# minimal $chain->[0] stand-in: only ->robot and ->output are used by execute()
{
    package Test::FakeMain;
    sub new    { my ($class, %args) = @_; return bless { %args }, $class }
    sub robot  { $_[0]->{robot} }
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

sub boot_robot {
    my (%extra) = @_;
    return mock_robot(
        'GET /boot/123456'          => load_fixture('robot_boot_get'),
        'GET /boot/123456/rescue'   => load_fixture('robot_boot_rescue'),
        'GET /boot/123456/linux'    => load_fixture('robot_boot_linux'),
        'GET /boot/123456/vnc'      => load_fixture('robot_boot_vnc'),
        'GET /boot/123456/windows'  => load_fixture('robot_boot_windows'),
        %extra,
    );
}

subtest 'boot: status of all options' => sub {
    my $main = Test::FakeMain->new(robot => boot_robot(), output => 'table');

    local @ARGV = ();
    my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Boot->new_with_options;

    my $out = capture_stdout(sub { $cmd->execute(['123456'], [$main]) });
    like($out, qr/^rescue\s+no\s+linux, vkvm$/m, 'rescue row lists the available systems');
    like($out, qr/^linux\s+no\s+Debian 12 minimal/m, 'linux row lists the available dists');
    like($out, qr/^windows\s+no\s+Windows Server 2022/m, 'windows row present');
};

subtest 'boot: server number is required' => sub {
    my $main = Test::FakeMain->new(robot => boot_robot(), output => 'table');

    local @ARGV = ();
    my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Boot->new_with_options;

    my $ok = eval { capture_stdout(sub { $cmd->execute([], [$main]) }); 1 };
    ok(!$ok, 'dies without a server number');
    like($@, qr/Usage: hrobot\.pl boot/, 'with a usage message');
};

subtest 'boot rescue: status, enable, disable' => sub {
    my $robot = boot_robot(
        'POST /boot/123456/rescue'   => load_fixture('robot_boot_rescue_active'),
        'DELETE /boot/123456/rescue' => load_fixture('robot_boot_rescue'),
    );
    my $main = Test::FakeMain->new(robot => $robot, output => 'table');

    {
        local @ARGV = ();
        my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Rescue->new_with_options;
        my $out = capture_stdout(sub { $cmd->execute(['123456'], [$main]) });
        like($out, qr/Active:\s+no/, 'status shows inactive');
        unlike($out, qr/Password:/, 'no password line while inactive');
    }

    {
        local @ARGV = ('--enable', '--os', 'linux');
        my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Rescue->new_with_options;
        my $out = capture_stdout(sub { $cmd->execute(['123456'], [$main]) });
        like($out, qr/Active:\s+yes/, 'enable reports active');
        like($out, qr/Password:\s+jEt0dtUvomlyOwRr/, 'generated password is printed');
        like($out, qr/Reset the server/, 'reminds that a reset is still needed');
    }

    {
        local @ARGV = ('--disable');
        my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Rescue->new_with_options;
        my $out = capture_stdout(sub { $cmd->execute(['123456'], [$main]) });
        like($out, qr/Active:\s+no/, 'disable reports inactive');
    }
};

subtest 'boot rescue: --enable without --os is refused before any request' => sub {
    my $main = Test::FakeMain->new(robot => boot_robot(), output => 'table');

    local @ARGV = ('--enable');
    my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Rescue->new_with_options;

    my $ok = eval { capture_stdout(sub { $cmd->execute(['123456'], [$main]) }); 1 };
    ok(!$ok, 'dies');
    like($@, qr/--os is required/, 'names the missing option');
};

subtest 'boot rescue: --enable and --disable are mutually exclusive' => sub {
    my $main = Test::FakeMain->new(robot => boot_robot(), output => 'table');

    local @ARGV = ('--enable', '--disable', '--os', 'linux');
    my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Rescue->new_with_options;

    my $ok = eval { capture_stdout(sub { $cmd->execute(['123456'], [$main]) }); 1 };
    ok(!$ok, 'dies');
    like($@, qr/mutually exclusive/, 'says why');
};

subtest 'boot linux: enable prints the password, json stays valid' => sub {
    my $robot = boot_robot(
        'POST /boot/123456/linux' => load_fixture('robot_boot_linux_active'),
    );

    {
        my $main = Test::FakeMain->new(robot => $robot, output => 'table');
        local @ARGV = ('--enable', '--dist', 'Debian 12 minimal', '--lang', 'en');
        my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Linux->new_with_options;
        my $out = capture_stdout(sub { $cmd->execute(['123456'], [$main]) });
        like($out, qr/Dist:\s+Debian 12 minimal/, 'installed dist printed');
        like($out, qr/Password:\s+hRk9pQ2xLmNvBzTa/, 'generated password printed');
    }

    {
        my $main = Test::FakeMain->new(robot => $robot, output => 'json');
        local @ARGV = ('--enable', '--dist', 'Debian 12 minimal', '--lang', 'en');
        my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Linux->new_with_options;
        my $out = capture_stdout(sub { $cmd->execute(['123456'], [$main]) });
        my $decoded = eval { decode_json($out) };
        ok(!$@, 'printed JSON decodes') or diag("decode failed: $@; out was: $out");
        is($decoded->{password}, 'hRk9pQ2xLmNvBzTa', 'password survives --output json');
    }
};

subtest 'boot vnc and windows are reachable' => sub {
    my $robot = boot_robot();
    my $main = Test::FakeMain->new(robot => $robot, output => 'table');

    {
        local @ARGV = ();
        my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Vnc->new_with_options;
        my $out = capture_stdout(sub { $cmd->execute(['123456'], [$main]) });
        like($out, qr/Dist:\s+centOS-5\.0, Fedora-6/, 'vnc dists listed');
    }

    {
        local @ARGV = ();
        my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Boot::Cmd::Windows->new_with_options;
        my $out = capture_stdout(sub { $cmd->execute(['123456'], [$main]) });
        like($out, qr/OS:\s+Windows Server 2022/, 'windows editions listed');
    }
};

subtest 'rdns: list, show, set, delete' => sub {
    my $robot = mock_robot(
        'GET /rdns'                 => load_fixture('robot_rdns_list'),
        'GET /rdns/203.0.113.50'    => load_fixture('robot_rdns_get'),
        'POST /rdns/203.0.113.50'   => sub {
            my ($method, $path, %opts) = @_;
            return { rdns => { ip => '203.0.113.50', ptr => $opts{body}{ptr} } };
        },
        'DELETE /rdns/203.0.113.50' => '',
    );
    my $main = Test::FakeMain->new(robot => $robot, output => 'table');

    {
        local @ARGV = ();
        my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Rdns->new_with_options;
        my $out = capture_stdout(sub { $cmd->execute([], [$main]) });
        like($out, qr/203\.0\.113\.50\s+dedi-1\.omnicorp\.example/, 'list shows the first entry');
        like($out, qr/203\.0\.113\.51\s+mail\.omnicorp\.example/, 'list shows the second entry');
    }

    {
        local @ARGV = ();
        my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Rdns->new_with_options;
        my $out = capture_stdout(sub { $cmd->execute(['203.0.113.50'], [$main]) });
        like($out, qr/PTR: dedi-1\.omnicorp\.example/, 'single entry shown');
    }

    {
        local @ARGV = ('--ptr', 'new.omnicorp.example');
        my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Rdns->new_with_options;
        my $out = capture_stdout(sub { $cmd->execute(['203.0.113.50'], [$main]) });
        like($out, qr/PTR: new\.omnicorp\.example/, '--ptr writes and echoes the new value');
    }

    {
        local @ARGV = ('--delete');
        my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Rdns->new_with_options;
        my $out = capture_stdout(sub { $cmd->execute(['203.0.113.50'], [$main]) });
        like($out, qr/deleted/, '--delete confirms');
    }

    {
        local @ARGV = ('--ptr', 'orphan.omnicorp.example');
        my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Rdns->new_with_options;
        my $ok = eval { capture_stdout(sub { $cmd->execute([], [$main]) }); 1 };
        ok(!$ok, '--ptr without an IP dies');
        like($@, qr/IP address is required/, 'with a usable message');
    }
};

subtest 'failover: list, show, switch, delete' => sub {
    my $robot = mock_robot(
        'GET /failover'                 => load_fixture('robot_failover_list'),
        'GET /failover/203.0.113.60'    => load_fixture('robot_failover_get'),
        'POST /failover/203.0.113.60'   => sub {
            my ($method, $path, %opts) = @_;
            my $switched = load_fixture('robot_failover_get');
            $switched->{failover}{active_server_ip} = $opts{body}{active_server_ip};
            return $switched;
        },
        'DELETE /failover/203.0.113.60' => sub {
            my $dropped = load_fixture('robot_failover_get');
            $dropped->{failover}{active_server_ip} = undef;
            return $dropped;
        },
    );
    my $main = Test::FakeMain->new(robot => $robot, output => 'table');

    {
        local @ARGV = ();
        my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Failover->new_with_options;
        my $out = capture_stdout(sub { $cmd->execute([], [$main]) });
        like($out, qr/203\.0\.113\.60\s+123456\s+203\.0\.113\.50/, 'list row');
        like($out, qr/2001:db8:fff1::/, 'IPv6 failover IP listed');
    }

    {
        local @ARGV = ();
        my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Failover->new_with_options;
        my $out = capture_stdout(sub { $cmd->execute(['203.0.113.60'], [$main]) });
        like($out, qr/Active Server IP: 203\.0\.113\.50/, 'single failover IP shown');
    }

    {
        local @ARGV = ('--to', '198.51.100.10');
        my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Failover->new_with_options;
        my $out = capture_stdout(sub { $cmd->execute(['203.0.113.60'], [$main]) });
        like($out, qr/Active Server IP: 198\.51\.100\.10/, '--to switches the routing');
    }

    {
        local @ARGV = ('--delete');
        my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Failover->new_with_options;
        my $out = capture_stdout(sub { $cmd->execute(['203.0.113.60'], [$main]) });
        like($out, qr/Active Server IP: $/m, '--delete leaves no active server');
    }

    {
        my $json_main = Test::FakeMain->new(robot => $robot, output => 'json');
        local @ARGV = ();
        my $cmd = WWW::Hetzner::Robot::CLI::Cmd::Failover->new_with_options;
        my $out = capture_stdout(sub { $cmd->execute(['203.0.113.60'], [$json_main]) });
        my $decoded = eval { decode_json($out) };
        ok(!$@, 'json output decodes') or diag("decode failed: $@; out was: $out");
        is($decoded->{ip}, '203.0.113.60', 'json carries the failover IP');
    }
};

done_testing;
