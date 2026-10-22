use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

use WWW::Hetzner::CLI::Cmd::Server;
use WWW::Hetzner::CLI::Cmd::Server::Cmd::List;
use WWW::Hetzner::CLI::Cmd::PrimaryIp::Cmd::List;
use WWW::Hetzner::CLI::Cmd::Image;
use WWW::Hetzner::CLI::Cmd::Datacenter;
use WWW::Hetzner::CLI::Cmd::Sshkey;
use WWW::Hetzner::CLI::Cmd::Location;
use WWW::Hetzner::CLI::Cmd::Servertype;
use WWW::Hetzner::CLI::Cmd::Zone;
use WWW::Hetzner::CLI::Cmd::Record;

# Exercises the default, human-readable list route of each top-level command.
# These commands receive entities from the controllers, and their displayed
# fields must survive each entity's normalized accessors and internal storage.
{
    package Test::CLIListTextMain;
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

my @cases = (
    {
        name    => 'server',
        class   => 'WWW::Hetzner::CLI::Cmd::Server',
        routes  => [ 'GET /servers' => load_fixture('servers_list') ],
        matches => [
            qr/203\.0\.113\.10/, 'public IPv4 is shown',
            qr/cx23/,              'server type is shown',
            qr/LOCATION/,          'the location column is headed LOCATION',
            qr/fsn1/,              'the location of a server with a datacenter is shown',
        ],
        not_matches => [
            qr/fsn1-dc14/, 'the datacenter name is no longer shown',
        ],
    },
    {
        name    => 'server list',
        class   => 'WWW::Hetzner::CLI::Cmd::Server::Cmd::List',
        routes  => [ 'GET /servers' => load_fixture('servers_list_current') ],
        matches => [
            qr/203\.0\.113\.10/, 'public IPv4 is shown',
            qr/LOCATION/,          'the location column is headed LOCATION',
            qr/fsn1/,              'the location of a current response is shown',
        ],
    },
    {
        name    => 'primary-ip list',
        class   => 'WWW::Hetzner::CLI::Cmd::PrimaryIp::Cmd::List',
        routes  => [ 'GET /primary_ips' => load_fixture('primary_ips_list_current') ],
        matches => [
            qr/203\.0\.113\.70/, 'the IP address is shown',
            qr/LOCATION/,          'the location column is headed LOCATION',
            qr/fsn1/,              'the location of a current response is shown',
        ],
    },
    {
        name    => 'primary-ip list with a datacenter response',
        class   => 'WWW::Hetzner::CLI::Cmd::PrimaryIp::Cmd::List',
        routes  => [ 'GET /primary_ips' => load_fixture('primary_ips_list') ],
        matches => [
            qr/LOCATION/, 'the location column is headed LOCATION',
        ],
        not_matches => [
            qr/fsn1-dc14/, 'the datacenter name is no longer shown',
        ],
    },
    {
        name    => 'image',
        class   => 'WWW::Hetzner::CLI::Cmd::Image',
        routes  => [ 'GET /images' => load_fixture('images_list') ],
        matches => [ qr/debian-12/, 'image name is shown', qr/system/, 'image type is shown' ],
    },
    {
        name    => 'datacenter',
        class   => 'WWW::Hetzner::CLI::Cmd::Datacenter',
        routes  => [ 'GET /datacenters' => load_fixture('datacenters_list') ],
        matches => [ qr/fsn1-dc14/, 'datacenter name is shown', qr/fsn1/, 'location is shown' ],
    },
    {
        name    => 'sshkey',
        class   => 'WWW::Hetzner::CLI::Cmd::Sshkey',
        routes  => [ 'GET /ssh_keys' => load_fixture('ssh_keys_list') ],
        matches => [ qr/omnicorp/, 'SSH key name is shown', qr/b7:2f:30:a0/, 'fingerprint is shown' ],
    },
    {
        name    => 'location',
        class   => 'WWW::Hetzner::CLI::Cmd::Location',
        routes  => [ 'GET /locations' => load_fixture('locations_list') ],
        matches => [ qr/fsn1/, 'location name is shown', qr/DE/, 'country is shown' ],
    },
    {
        name    => 'servertype',
        class   => 'WWW::Hetzner::CLI::Cmd::Servertype',
        routes  => [ 'GET /server_types' => load_fixture('server_types_list') ],
        matches => [ qr/cx11/, 'server type is shown', qr/2 GB/, 'memory is shown' ],
    },
    {
        name    => 'zone',
        class   => 'WWW::Hetzner::CLI::Cmd::Zone',
        routes  => [ 'GET /zones' => load_fixture('zones_list') ],
        matches => [ qr/example\.com/, 'zone name is shown', qr/3600/, 'zone TTL is shown' ],
    },
    {
        name    => 'record',
        class   => 'WWW::Hetzner::CLI::Cmd::Record',
        argv    => [ '--zone', 'zone123456' ],
        routes  => [ 'GET /zones/zone123456/rrsets' => load_fixture('rrsets_list') ],
        matches => [ qr/203\.0\.113\.10/, 'record value is shown', qr/\bA\b/, 'record type is shown' ],
    },
);

for my $case (@cases) {
    subtest "$case->{name}: default list prints entity data" => sub {
        my $cloud = mock_cloud(@{ $case->{routes} });
        my $main = Test::CLIListTextMain->new(cloud => $cloud, output => 'table');

        local @ARGV = @{ $case->{argv} // [] };
        my $cmd = $case->{class}->new_with_options;
        my $out = eval { capture_stdout(sub { $cmd->execute([], [$main]) }) };
        my $err = $@;
        ok(!$err, 'default list executes through its entity display fields')
            or do { diag("died with: $err"); return };

        my @matches = @{ $case->{matches} };
        while (@matches) {
            my ($pattern, $name) = splice @matches, 0, 2;
            like($out, $pattern, $name);
        }

        my @not_matches = @{ $case->{not_matches} // [] };
        while (@not_matches) {
            my ($pattern, $name) = splice @not_matches, 0, 2;
            unlike($out, $pattern, $name);
        }
    };
}

done_testing;
