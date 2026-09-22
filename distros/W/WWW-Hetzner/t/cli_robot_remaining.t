use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;
use WWW::Hetzner::Robot::CLI::Cmd::Key;
use WWW::Hetzner::Robot::CLI::Cmd::Reset;
use WWW::Hetzner::Robot::CLI::Cmd::Server;
use WWW::Hetzner::Robot::CLI::Cmd::Server::Cmd::List;
use WWW::Hetzner::Robot::CLI::Cmd::Server::Cmd::Describe;
use WWW::Hetzner::Robot::CLI::Cmd::Traffic;
use WWW::Hetzner::Robot::CLI::Cmd::Wol;

# Covers every Robot CLI command not exercised by t/cli_robot.t through its
# real execute() path.  Mutating routes assert Robot's decoded form payload.
{
    package Test::CLIRobotRemainingMain;
    sub new    { my ($class, %args) = @_; return bless { %args }, $class }
    sub robot  { $_[0]->{robot} }
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
    my $robot = mock_robot(@{ $case{routes} });
    my $main = Test::CLIRobotRemainingMain->new(robot => $robot, output => ($case{output} // 'table'));

    local @ARGV = @{ $case{argv} // [] };
    my $cmd = $case{class}->new_with_options;
    my $out = eval { capture_stdout(sub { $cmd->execute($case{args} // [], [$main]) }) };
    my $err = $@;
    ok(!$err, "$case{name} executes")
        or do { diag("died with: $err"); return };
    like($out, $case{like}, "$case{name} renders the API result");
}

subtest 'key lists Robot SSH keys' => sub {
    run_command(
        name   => 'key',
        class  => 'WWW::Hetzner::Robot::CLI::Cmd::Key',
        routes => [ 'GET /key' => load_fixture('robot_keys_list') ],
        like   => qr/omnicorp-deploy/,
    );
};

subtest 'reset posts the selected reset type' => sub {
    run_command(
        name   => 'reset',
        class  => 'WWW::Hetzner::Robot::CLI::Cmd::Reset',
        argv   => [ '--type', 'hw' ],
        args   => [ '123456' ],
        routes => [
            'POST /reset/123456' => sub {
                my ($method, $path, %opts) = @_;
                is_deeply($opts{body}, { type => 'hw' }, 'reset sends the selected type as form data');
                return load_fixture('robot_reset_execute');
            },
        ],
        like => qr/Reset initiated for server 123456 \(type: hw\)/,
    );
};

for my $case (
    {
        name   => 'server default list',
        class  => 'WWW::Hetzner::Robot::CLI::Cmd::Server',
        routes => [ 'GET /server' => load_fixture('robot_servers_list') ],
        like   => qr/123456/,
    },
    {
        name   => 'server list subcommand',
        class  => 'WWW::Hetzner::Robot::CLI::Cmd::Server::Cmd::List',
        routes => [ 'GET /server' => load_fixture('robot_servers_list') ],
        like   => qr/omnicorp-dedicated-1/,
    },
    {
        name   => 'server describe',
        class  => 'WWW::Hetzner::Robot::CLI::Cmd::Server::Cmd::Describe',
        args   => [ '123456' ],
        routes => [ 'GET /server/123456' => load_fixture('robot_servers_get') ],
        like   => qr/Server Number:\s+123456/,
    },
) {
    subtest $case->{name} => sub { run_command(%$case) };
}

subtest 'traffic posts all filtering options in Robot form shape' => sub {
    run_command(
        name   => 'traffic',
        class  => 'WWW::Hetzner::Robot::CLI::Cmd::Traffic',
        argv   => [
            '--ip', '203.0.113.50,203.0.113.51',
            '--subnet', '2001:db8::/64',
            '--type', 'day',
            '--from', '2024-01-01T00',
            '--to', '2024-01-02T00',
            '--single-values',
        ],
        routes => [
            'POST /traffic' => sub {
                my ($method, $path, %opts) = @_;
                is_deeply(
                    $opts{body},
                    {
                        ip            => [ '203.0.113.50', '203.0.113.51' ],
                        subnet        => [ '2001:db8::/64' ],
                        type          => 'day',
                        from          => '2024-01-01T00',
                        to            => '2024-01-02T00',
                        single_values => 'true',
                    },
                    'traffic uses repeatable Robot form fields and single_values=true',
                );
                return load_fixture('traffic_query_single');
            },
        ],
        like => qr/2024-01-01T00/,
    );
};

subtest 'wol posts an empty Robot request body' => sub {
    run_command(
        name   => 'wol',
        class  => 'WWW::Hetzner::Robot::CLI::Cmd::Wol',
        args   => [ '123456' ],
        routes => [
            'POST /wol/123456' => sub {
                my ($method, $path, %opts) = @_;
                ok(!defined $opts{body}, 'WOL has no request payload');
                return load_fixture('robot_wol');
            },
        ],
        like => qr/Wake-on-LAN sent to server 123456/,
    );
};

done_testing;
