use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

# Covers the remaining certificate, placement-group, primary-IP, SSH key, DNS,
# ISO, load-balancer-type and pricing command classes.  All commands use their
# actual MooX option parsing and execute path; mutations assert decoded JSON.
{
    package Test::CLICloudIdentityMain;
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

sub load_command_class {
    my ($class) = @_;
    (my $file = $class) =~ s!::!/!g;
    require "$file.pm";
}

sub run_command {
    my (%case) = @_;
    load_command_class($case{class});
    my $cloud = mock_cloud(@{ $case{routes} // [] });
    my $main = Test::CLICloudIdentityMain->new(cloud => $cloud, output => ($case{output} // 'table'));

    local @ARGV = @{ $case{argv} // [] };
    my $cmd = $case{class}->new_with_options;
    ok($cmd->no_wait, "$case{name} parsed --no-wait") if $case{no_wait};
    my $out = eval { capture_stdout(sub { $cmd->execute($case{args} // [], [$main]) }) };
    my $err = $@;
    ok(!$err, "$case{name} executes")
        or do { diag("died with: $err"); return };
    like($out, $case{like}, "$case{name} renders expected entity data");
}

for my $case (
    [ 'certificate parent', 'WWW::Hetzner::CLI::Cmd::Certificate', [], qr/Subcommands:/ ],
    [ 'certificate list', 'WWW::Hetzner::CLI::Cmd::Certificate::Cmd::List', [ 'GET /certificates' => load_fixture('certificates_list') ], qr/my-cert/ ],
    [ 'certificate describe', 'WWW::Hetzner::CLI::Cmd::Certificate::Cmd::Describe', [ 'GET /certificates/1100' => load_fixture('certificates_get') ], qr/Domains:/, [ '1100' ] ],
    [ 'placement-group parent', 'WWW::Hetzner::CLI::Cmd::PlacementGroup', [], qr/Subcommands:/ ],
    [ 'placement-group list', 'WWW::Hetzner::CLI::Cmd::PlacementGroup::Cmd::List', [ 'GET /placement_groups' => load_fixture('placement_groups_list') ], qr/spread/ ],
    [ 'placement-group describe', 'WWW::Hetzner::CLI::Cmd::PlacementGroup::Cmd::Describe', [ 'GET /placement_groups/1300' => load_fixture('placement_groups_get') ], qr/Servers:/, [ '1300' ] ],
    [ 'primary-ip parent', 'WWW::Hetzner::CLI::Cmd::PrimaryIp', [], qr/Subcommands:/ ],
    [ 'primary-ip list', 'WWW::Hetzner::CLI::Cmd::PrimaryIp::Cmd::List', [ 'GET /primary_ips' => load_fixture('primary_ips_list') ], qr/203\.0\.113/ ],
    [ 'primary-ip describe', 'WWW::Hetzner::CLI::Cmd::PrimaryIp::Cmd::Describe', [ 'GET /primary_ips/700' => load_fixture('primary_ips_get') ], qr/Datacenter:/, [ '700' ] ],
    [ 'sshkey list', 'WWW::Hetzner::CLI::Cmd::Sshkey::Cmd::List', [ 'GET /ssh_keys' => load_fixture('ssh_keys_list') ], qr/omnicorp/ ],
    [ 'sshkey describe', 'WWW::Hetzner::CLI::Cmd::Sshkey::Cmd::Describe', [ 'GET /ssh_keys/2323' => load_fixture('ssh_keys_get') ], qr/Fingerprint:/, [ '2323' ] ],
    [ 'zone list', 'WWW::Hetzner::CLI::Cmd::Zone::Cmd::List', [ 'GET /zones' => load_fixture('zones_list') ], qr/example\.com/ ],
    [ 'zone describe', 'WWW::Hetzner::CLI::Cmd::Zone::Cmd::Describe', [ 'GET /zones/zone123456' => load_fixture('zones_get') ], qr/Nameservers:/, [ 'zone123456' ] ],
    [ 'record list', 'WWW::Hetzner::CLI::Cmd::Record::Cmd::List', [ 'GET /zones/zone123456/rrsets' => load_fixture('rrsets_list') ], qr/203\.0\.113\.10/, [], [ '--zone', 'zone123456' ] ],
    [ 'record describe', 'WWW::Hetzner::CLI::Cmd::Record::Cmd::Describe', [ 'GET /zones/zone123456/rrsets/www/A' => load_fixture('rrsets_get') ], qr/Values:/, [], [ '--zone', 'zone123456', '--name', 'www', '--type', 'A' ] ],
    [ 'iso filtered list', 'WWW::Hetzner::CLI::Cmd::Iso', [ 'GET /isos' => sub { my ($m, $p, %opts) = @_; is_deeply($opts{params}, { architecture => 'x86', name => 'debian-12' }, 'ISO filters are query parameters'); return load_fixture('isos_list') } ], qr/netboot\.xyz\.iso/, [], [ '--architecture', 'x86', '--name', 'debian-12' ] ],
    [ 'load-balancer-type list', 'WWW::Hetzner::CLI::Cmd::LoadBalancerType', [ 'GET /load_balancer_types' => load_fixture('load_balancer_types_list') ], qr/lb11/ ],
    [ 'pricing', 'WWW::Hetzner::CLI::Cmd::Pricing', [ 'GET /pricing' => load_fixture('pricing_get') ], qr/Currency:/ ],
) {
    my ($name, $class, $routes, $like, $args, $argv) = @$case;
    subtest $name => sub {
        run_command(name => $name, class => $class, routes => $routes, args => $args, argv => $argv, like => $like);
    };
}

for my $case (
    {
        name => 'certificate create', class => 'WWW::Hetzner::CLI::Cmd::Certificate::Cmd::Create',
        argv => [ '--name', 'edge-cert', '--domain', 'example.com', '--domain', 'www.example.com', '--no-wait' ],
        route => 'POST /certificates', body => { name => 'edge-cert', type => 'managed', domain_names => [ 'example.com', 'www.example.com' ] }, fixture => 'certificates_create', like => qr/Certificate created with ID 1200/,
    },
    {
        name => 'placement-group create', class => 'WWW::Hetzner::CLI::Cmd::PlacementGroup::Cmd::Create',
        argv => [ '--name', 'rack-spread', '--no-wait' ], route => 'POST /placement_groups', body => { name => 'rack-spread', type => 'spread' }, fixture => 'placement_groups_create', like => qr/Placement group created with ID 1400/,
    },
    {
        name => 'primary-ip create', class => 'WWW::Hetzner::CLI::Cmd::PrimaryIp::Cmd::Create',
        argv => [ '--name', 'frontend-v4', '--type', 'ipv4', '--datacenter', 'fsn1-dc14', '--auto-delete', '--no-wait' ],
        route => 'POST /primary_ips', body => { name => 'frontend-v4', type => 'ipv4', assignee_type => 'server', datacenter => 'fsn1-dc14', auto_delete => 1 }, fixture => 'primary_ips_create', like => qr/Primary IP created with ID 800/,
    },
    {
        name => 'primary-ip assign', class => 'WWW::Hetzner::CLI::Cmd::PrimaryIp::Cmd::Assign',
        argv => [ '--server', '123456', '--no-wait' ], args => [ '700' ], route => 'POST /primary_ips/700/actions/assign', body => { assignee_id => 123456, assignee_type => 'server' }, fixture => 'primary_ips_action', like => qr/Primary IP assignment requested\./,
    },
    {
        name => 'primary-ip unassign', class => 'WWW::Hetzner::CLI::Cmd::PrimaryIp::Cmd::Unassign',
        argv => [ '--no-wait' ], args => [ '700' ], route => 'POST /primary_ips/700/actions/unassign', body => {}, fixture => 'primary_ips_action', like => qr/Primary IP unassignment requested\./,
    },
    {
        name => 'sshkey create', class => 'WWW::Hetzner::CLI::Cmd::Sshkey::Cmd::Create',
        argv => [ '--name', 'deploy-key', '--public_key', 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITest deploy@example' ],
        route => 'POST /ssh_keys', body => { name => 'deploy-key', public_key => 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAITest deploy@example' }, fixture => 'ssh_keys_get', like => qr/SSH key created:/,
    },
    {
        name => 'zone create', class => 'WWW::Hetzner::CLI::Cmd::Zone::Cmd::Create',
        argv => [ '--name', 'new.example.com', '--ttl', '7200', '--no-wait' ], route => 'POST /zones', body => { name => 'new.example.com', ttl => 7200 }, fixture => 'zones_create', like => qr/Zone created:/,
    },
    {
        name => 'record create', class => 'WWW::Hetzner::CLI::Cmd::Record::Cmd::Create',
        argv => [ '--zone', 'zone123456', '--name', 'api', '--type', 'a', '--value', '198.51.100.20,198.51.100.21', '--ttl', '600' ],
        route => 'POST /zones/zone123456/rrsets', body => { name => 'api', type => 'A', ttl => 600, records => [ { value => '198.51.100.20' }, { value => '198.51.100.21' } ] }, fixture => 'rrsets_create', like => qr/Record created:/,
    },
) {
    subtest "$case->{name}: sends its resource-specific payload" => sub {
        run_command(
            name    => $case->{name}, class => $case->{class}, argv => $case->{argv}, args => $case->{args}, no_wait => ($case->{argv}[-1] eq '--no-wait'),
            routes  => [
                $case->{route} => sub {
                    my ($method, $path, %opts) = @_;
                    is_deeply($opts{body}, $case->{body}, "$case->{name} decoded request body");
                    return load_fixture($case->{fixture});
                },
            ],
            like => $case->{like},
        );
    };
}

done_testing;
