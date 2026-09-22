use strict;
use warnings;
use Test::More;
use JSON::MaybeXS qw(decode_json);
use lib 't/lib';

use Test::WWW::Hetzner::Mock;

use WWW::Hetzner::CLI::Cmd::Server;
use WWW::Hetzner::CLI::Cmd::Image;
use WWW::Hetzner::CLI::Cmd::Datacenter;
use WWW::Hetzner::CLI::Cmd::Sshkey;
use WWW::Hetzner::CLI::Cmd::Location;
use WWW::Hetzner::CLI::Cmd::Servertype;
use WWW::Hetzner::CLI::Cmd::Zone;
use WWW::Hetzner::CLI::Cmd::Record;

# Regression guard for karr #9: the top-level list commands handed the arrayref
# of blessed entities straight to encode_json, so --output json died with
# "encountered object ..., but neither allow_blessed, convert_blessed nor
# allow_tags settings are enabled". The correct form, already used by the
# Cmd/*/Cmd/List.pm subcommands, is encode_json([ map { $_->data } @$list ]).
# Exercises the real Cmd::execute($args, $chain) path against a mock_cloud,
# not the controllers directly, so it fails the same way the CLI bug did.

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

my @cases = (
    {
        name   => 'server',
        class  => 'WWW::Hetzner::CLI::Cmd::Server',
        routes => [ 'GET /servers' => load_fixture('servers_list') ],
        check  => sub {
            my ($list) = @_;
            is(scalar @$list, 1, 'one server in the list');
            is($list->[0]{id}, 123456, 'server id survives --output json');
            is($list->[0]{name}, 'omnicorp-cop', 'server name survives --output json');
            is($list->[0]{server_type}{name}, 'cx23', 'nested server_type survives --output json');
        },
    },
    {
        name   => 'image',
        class  => 'WWW::Hetzner::CLI::Cmd::Image',
        routes => [ 'GET /images' => load_fixture('images_list') ],
        check  => sub {
            my ($list) = @_;
            is(scalar @$list, 3, 'three images in the list');
            is($list->[0]{name}, 'debian-12', 'image name survives --output json');
            is($list->[0]{type}, 'system', 'image type survives --output json');
        },
    },
    {
        name   => 'datacenter',
        class  => 'WWW::Hetzner::CLI::Cmd::Datacenter',
        routes => [ 'GET /datacenters' => load_fixture('datacenters_list') ],
        check  => sub {
            my ($list) = @_;
            is(scalar @$list, 3, 'three datacenters in the list');
            is($list->[0]{name}, 'fsn1-dc14', 'datacenter name survives --output json');
            is($list->[0]{location}{name}, 'fsn1', 'nested location survives --output json');
        },
    },
    {
        name   => 'sshkey',
        class  => 'WWW::Hetzner::CLI::Cmd::Sshkey',
        routes => [ 'GET /ssh_keys' => load_fixture('ssh_keys_list') ],
        check  => sub {
            my ($list) = @_;
            is(scalar @$list, 1, 'one SSH key in the list');
            is($list->[0]{id}, 2323, 'SSH key id survives --output json');
            is(
                $list->[0]{fingerprint},
                'b7:2f:30:a0:2f:6c:58:6c:21:04:58:61:ba:06:3b:2f',
                'SSH key fingerprint survives --output json',
            );
        },
    },
    {
        name   => 'location',
        class  => 'WWW::Hetzner::CLI::Cmd::Location',
        routes => [ 'GET /locations' => load_fixture('locations_list') ],
        check  => sub {
            my ($list) = @_;
            is(scalar @$list, 3, 'three locations in the list');
            is($list->[0]{name}, 'fsn1', 'location name survives --output json');
            is($list->[0]{country}, 'DE', 'location country survives --output json');
        },
    },
    {
        name   => 'servertype',
        class  => 'WWW::Hetzner::CLI::Cmd::Servertype',
        routes => [ 'GET /server_types' => load_fixture('server_types_list') ],
        check  => sub {
            my ($list) = @_;
            is(scalar @$list, 3, 'three server types in the list');
            is($list->[0]{name}, 'cx11', 'server type name survives --output json');
            is($list->[0]{cores}, 1, 'server type cores survives --output json');
        },
    },
    {
        name   => 'zone',
        class  => 'WWW::Hetzner::CLI::Cmd::Zone',
        routes => [ 'GET /zones' => load_fixture('zones_list') ],
        check  => sub {
            my ($list) = @_;
            is(scalar @$list, 1, 'one zone in the list');
            is($list->[0]{id}, 'zone123456', 'zone id survives --output json');
            is($list->[0]{name}, 'example.com', 'zone name survives --output json');
        },
    },
    {
        name   => 'record',
        class  => 'WWW::Hetzner::CLI::Cmd::Record',
        argv   => ['--zone', 'zone123456'],
        routes => [ 'GET /zones/zone123456/rrsets' => load_fixture('rrsets_list') ],
        check  => sub {
            my ($list) = @_;
            is(scalar @$list, 5, 'five records in the list');
            is($list->[0]{name}, '@', 'record name survives --output json');
            is($list->[0]{type}, 'A', 'record type survives --output json');
            is(
                $list->[0]{records}[0]{value},
                '203.0.113.10',
                'nested record values survive --output json',
            );
        },
    },
);

for my $case (@cases) {
    subtest "$case->{name}: --output json prints a decodable JSON list" => sub {
        my $cloud = mock_cloud(@{ $case->{routes} });
        my $main  = Test::FakeMain->new(cloud => $cloud, output => 'json');

        local @ARGV = @{ $case->{argv} // [] };
        my $cmd = $case->{class}->new_with_options;

        my $out = eval { capture_stdout(sub { $cmd->execute([], [$main]) }) };
        my $err = $@;
        ok(!$err, 'execute did not die encoding the entity list to JSON')
            or do { diag("died with: $err"); return };

        my $decoded = eval { decode_json($out) };
        ok(!$@, 'printed output is valid JSON')
            or do { diag("decode failed: $@; output was: " . ($out // '<undef>')); return };

        is(ref $decoded, 'ARRAY', 'a JSON array was printed')
            or return;

        $case->{check}->($decoded);
    };
}

done_testing;
