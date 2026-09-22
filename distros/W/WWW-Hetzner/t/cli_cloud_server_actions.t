use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;
use WWW::Hetzner::CLI::Cmd::Server::Cmd::Create;
use WWW::Hetzner::CLI::Cmd::Server::Cmd::Describe;
use WWW::Hetzner::CLI::Cmd::Server::Cmd::List;
use WWW::Hetzner::CLI::Cmd::Server::Cmd::Poweron;
use WWW::Hetzner::CLI::Cmd::Server::Cmd::Poweroff;
use WWW::Hetzner::CLI::Cmd::Server::Cmd::Reboot;
use WWW::Hetzner::CLI::Cmd::Server::Cmd::Reset;
use WWW::Hetzner::CLI::Cmd::Server::Cmd::Shutdown;

# Covers the eight Server command classes not already exercised by the rescue,
# rebuild, delete and default-list CLI tests.
{
    package Test::CLIServerActionsMain;
    sub new    { my ($class, %args) = @_; return bless { %args }, $class }
    sub cloud  { $_[0]->{cloud} }
    sub output { $_[0]->{output} }
}

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

sub run_command {
    my (%case) = @_;
    my $cloud = mock_cloud(@{ $case{routes} });
    $cloud->sleeper($case{sleeper}) if $case{sleeper};
    my $main = Test::CLIServerActionsMain->new(cloud => $cloud, output => ($case{output} // 'table'));

    local @ARGV = @{ $case{argv} // [] };
    my $cmd = $case{class}->new_with_options;
    ok($cmd->no_wait, "$case{name} parsed --no-wait") if $case{no_wait};

    my $out = eval { capture_stdout(sub { $cmd->execute($case{args} // [], [$main]) }) };
    my $err = $@;
    ok(!$err, "$case{name} executes")
        or do { diag("died with: $err"); return };
    like($out, $case{like}, "$case{name} reports its result");
}

subtest 'server list forwards the label selector' => sub {
    run_command(
        name   => 'server list',
        class  => 'WWW::Hetzner::CLI::Cmd::Server::Cmd::List',
        argv   => [ '--selector', 'env=prod' ],
        routes => [
            'GET /servers' => sub {
                my ($method, $path, %opts) = @_;
                is_deeply($opts{params}, { label_selector => 'env=prod' }, 'selector is encoded as label_selector');
                return load_fixture('servers_list');
            },
        ],
        like => qr/omnicorp-cop/,
    );
};

subtest 'server describe renders an entity returned by get' => sub {
    run_command(
        name   => 'server describe',
        class  => 'WWW::Hetzner::CLI::Cmd::Server::Cmd::Describe',
        args   => [ '123456' ],
        routes => [ 'GET /servers/123456' => load_fixture('servers_get') ],
        like   => qr/Datacenter:\s+fsn1-dc14/,
    );
};

subtest 'server create maps CLI collections and public-net options' => sub {
    run_command(
        name    => 'server create',
        class   => 'WWW::Hetzner::CLI::Cmd::Server::Cmd::Create',
        argv    => [
            '--name', 'web-two', '--type', 'cx23', '--image', 'debian-12',
            '--location', 'fsn1', '--ssh_key', '2323', '--firewall', '300',
            '--label', 'env=prod', '--network', '100', '--without_ipv4',
            '--primary_ipv6', '700', '--volume', '555', '--placement_group', '1300',
            '--no-wait',
        ],
        no_wait => 1,
        routes  => [
            'POST /servers' => sub {
                my ($method, $path, %opts) = @_;
                is_deeply(
                    $opts{body},
                    {
                        name               => 'web-two',
                        server_type        => 'cx23',
                        image              => 'debian-12',
                        location           => 'fsn1',
                        ssh_keys           => [2323],
                        firewalls          => [{ firewall => 300 }],
                        labels             => { env => 'prod' },
                        networks           => [100],
                        public_net         => { enable_ipv4 => 0, ipv6 => 700 },
                        volumes            => [555],
                        placement_group    => 1300,
                        start_after_create => 1,
                    },
                    'server create sends the CLI option structure expected by the Cloud API',
                );
                return load_fixture('servers_create');
            },
        ],
        like => qr/Server created:/,
    );
};

subtest 'server poweron waits by default for its single action' => sub {
    my @slept;
    run_command(
        name   => 'server poweron',
        class  => 'WWW::Hetzner::CLI::Cmd::Server::Cmd::Poweron',
        args   => [ '123456' ],
        routes => [
            'POST /servers/123456/actions/poweron' => sub {
                my ($method, $path, %opts) = @_;
                is_deeply($opts{body}, {}, 'poweron has an empty action body');
                return load_fixture('servers_action');
            },
            'GET /actions/13343' => sub {
                my $done = load_fixture('servers_action');
                $done->{action}{status} = 'success';
                $done->{action}{progress} = 100;
                return $done;
            },
        ],
        sleeper => sub { push @slept, $_[0] },
        like    => qr/Server powered on\./,
    );
    is_deeply(\@slept, [1], 'poweron polls once instead of sleeping for real');
};

for my $case (
    [ 'poweroff', 'WWW::Hetzner::CLI::Cmd::Server::Cmd::Poweroff', 'POST /servers/123456/actions/poweroff', qr/Power-off requested\./ ],
    [ 'reboot',   'WWW::Hetzner::CLI::Cmd::Server::Cmd::Reboot',   'POST /servers/123456/actions/reboot',   qr/Server reboot requested\./ ],
    [ 'reset',    'WWW::Hetzner::CLI::Cmd::Server::Cmd::Reset',    'POST /servers/123456/actions/reset',    qr/Server reset requested\./ ],
    [ 'shutdown', 'WWW::Hetzner::CLI::Cmd::Server::Cmd::Shutdown', 'POST /servers/123456/actions/shutdown', qr/Server shutdown requested\./ ],
) {
    my ($name, $class, $route, $like) = @$case;
    subtest "server $name: --no-wait does not poll" => sub {
        run_command(
            name    => "server $name",
            class   => $class,
            argv    => [ '--no-wait' ],
            args    => [ '123456' ],
            no_wait => 1,
            routes  => [
                $route => sub {
                    my ($method, $path, %opts) = @_;
                    is_deeply($opts{body}, {}, "$name has an empty action body");
                    return load_fixture('servers_action');
                },
            ],
            like => $like,
        );
    };
}

done_testing;
