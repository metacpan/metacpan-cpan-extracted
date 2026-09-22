use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;
use WWW::Hetzner::HTTPResponse;
use WWW::Hetzner::CLI::Cmd::Volume;
use WWW::Hetzner::CLI::Cmd::Volume::Cmd::List;
use WWW::Hetzner::CLI::Cmd::Volume::Cmd::Describe;
use WWW::Hetzner::CLI::Cmd::Volume::Cmd::Create;
use WWW::Hetzner::CLI::Cmd::Volume::Cmd::Attach;
use WWW::Hetzner::CLI::Cmd::Volume::Cmd::Detach;
use WWW::Hetzner::CLI::Cmd::Volume::Cmd::Resize;
use WWW::Hetzner::CLI::Cmd::Volume::Cmd::Delete;

# Volume is a Cloud resource.  Exercise its parent list, list/describe
# subcommands, entity-returning create, and all mutations through mock_cloud.
{
    package Test::CLIVolumeMain;
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
    my $main = Test::CLIVolumeMain->new(cloud => $cloud, output => ($case{output} // 'table'));

    local @ARGV = @{ $case{argv} // [] };
    my $cmd = $case{class}->new_with_options;
    ok($cmd->no_wait, "$case{name} parsed --no-wait") if $case{no_wait};

    my $out = eval { capture_stdout(sub { $cmd->execute($case{args} // [], [$main]) }) };
    my $err = $@;
    ok(!$err, "$case{name} executes")
        or do { diag("died with: $err"); return };
    like($out, $case{like}, "$case{name} reports its result");
}

for my $case (
    {
        name   => 'volume parent default list',
        class  => 'WWW::Hetzner::CLI::Cmd::Volume',
        routes => [ 'GET /volumes' => load_fixture('volumes_list') ],
        like   => qr/my-data/,
    },
    {
        name   => 'volume list',
        class  => 'WWW::Hetzner::CLI::Cmd::Volume::Cmd::List',
        routes => [ 'GET /volumes' => load_fixture('volumes_list') ],
        like   => qr/available/,
    },
    {
        name   => 'volume describe',
        class  => 'WWW::Hetzner::CLI::Cmd::Volume::Cmd::Describe',
        args   => [ '555' ],
        routes => [ 'GET /volumes/555' => load_fixture('volumes_get') ],
        like   => qr/Linux Device: \/dev\/disk\/by-id/,
    },
) {
    subtest $case->{name} => sub { run_command(%$case) };
}

subtest 'volume create waits for the action attached to its entity' => sub {
    my @slept;
    run_command(
        name   => 'volume create',
        class  => 'WWW::Hetzner::CLI::Cmd::Volume::Cmd::Create',
        argv   => [ '--name', 'data-two', '--size', '20', '--location', 'fsn1', '--format', 'xfs', '--server', '123456', '--automount' ],
        routes => [
            'POST /volumes' => sub {
                my ($method, $path, %opts) = @_;
                is_deeply(
                    { map { $_ => $opts{body}{$_} } qw(name size location format server) },
                    { name => 'data-two', size => 20, location => 'fsn1', format => 'xfs', server => 123456 },
                    'volume create forwards each scalar CLI creation option',
                );
                ok($opts{body}{automount}, 'volume create sends automount as true');
                return load_fixture('volumes_create');
            },
            'GET /actions/1234' => sub {
                my $done = load_fixture('volumes_create');
                $done->{action}{status} = 'success';
                $done->{action}{progress} = 100;
                return { action => $done->{action} };
            },
        ],
        sleeper => sub { push @slept, $_[0] },
        like    => qr/Volume created:/,
    );
    is_deeply(\@slept, [1], 'create waited for the entity action without real sleep');
};

for my $case (
    {
        name   => 'volume attach',
        class  => 'WWW::Hetzner::CLI::Cmd::Volume::Cmd::Attach',
        argv   => [ '--server', '123456', '--automount', '--no-wait' ],
        args   => [ '555' ],
        route  => 'POST /volumes/555/actions/attach',
        body   => { server => 123456, automount => \1 },
        like   => qr/Volume attach requested\./,
    },
    {
        name   => 'volume detach',
        class  => 'WWW::Hetzner::CLI::Cmd::Volume::Cmd::Detach',
        argv   => [ '--no-wait' ],
        args   => [ '555' ],
        route  => 'POST /volumes/555/actions/detach',
        body   => {},
        like   => qr/Volume detach requested\./,
    },
    {
        name   => 'volume resize',
        class  => 'WWW::Hetzner::CLI::Cmd::Volume::Cmd::Resize',
        argv   => [ '--size', '60', '--no-wait' ],
        args   => [ '555' ],
        route  => 'POST /volumes/555/actions/resize',
        body   => { size => 60 },
        like   => qr/Volume resize requested\./,
    },
) {
    subtest "$case->{name}: --no-wait sends the action request but does not poll" => sub {
        run_command(
            name    => $case->{name},
            class   => $case->{class},
            argv    => $case->{argv},
            args    => $case->{args},
            no_wait => 1,
            routes  => [
                $case->{route} => sub {
                    my ($method, $path, %opts) = @_;
                    if ($case->{name} eq 'volume attach') {
                        is($opts{body}{server}, 123456, 'volume attach sends the server ID');
                        ok($opts{body}{automount}, 'volume attach sends automount as true');
                    }
                    else {
                        is_deeply($opts{body}, $case->{body}, "$case->{name} request body");
                    }
                    return load_fixture('volumes_action');
                },
            ],
            like => $case->{like},
        );
    };
}

subtest 'volume delete accepts the documented no-content response' => sub {
    run_command(
        name   => 'volume delete',
        class  => 'WWW::Hetzner::CLI::Cmd::Volume::Cmd::Delete',
        args   => [ '555' ],
        routes => [
            'DELETE /volumes/555' => sub {
                my ($method, $path, %opts) = @_;
                ok(!defined $opts{body}, 'volume delete sends no request body');
                return WWW::Hetzner::HTTPResponse->new(status => 204, content => '');
            },
        ],
        like => qr/Volume deleted\./,
    );
};

done_testing;
