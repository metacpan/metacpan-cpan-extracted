use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;
use WWW::Hetzner::HTTPResponse;

# Hetzner Cloud documents these DELETE routes as HTTP 204 without an action.
# The action-returning DELETE routes are deliberately covered separately in
# t/cli_delete_waits.t (server, zone and RRSet only).
{
    package Test::CLIDeleteNoActionMain;
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

sub no_content { WWW::Hetzner::HTTPResponse->new(status => 204, content => '') }

for my $case (
    [ 'certificate',     'WWW::Hetzner::CLI::Cmd::Certificate::Cmd::Delete',    '1100', 'DELETE /certificates/1100' ],
    [ 'firewall',        'WWW::Hetzner::CLI::Cmd::Firewall::Cmd::Delete',       '300',  'DELETE /firewalls/300' ],
    [ 'floating-ip',     'WWW::Hetzner::CLI::Cmd::FloatingIp::Cmd::Delete',     '500',  'DELETE /floating_ips/500' ],
    [ 'load-balancer',   'WWW::Hetzner::CLI::Cmd::LoadBalancer::Cmd::Delete',   '900',  'DELETE /load_balancers/900' ],
    [ 'network',         'WWW::Hetzner::CLI::Cmd::Network::Cmd::Delete',        '100',  'DELETE /networks/100' ],
    [ 'placement-group', 'WWW::Hetzner::CLI::Cmd::PlacementGroup::Cmd::Delete', '1300', 'DELETE /placement_groups/1300' ],
    [ 'primary-ip',      'WWW::Hetzner::CLI::Cmd::PrimaryIp::Cmd::Delete',      '700',  'DELETE /primary_ips/700' ],
    [ 'sshkey',          'WWW::Hetzner::CLI::Cmd::Sshkey::Cmd::Delete',         '2323', 'DELETE /ssh_keys/2323' ],
) {
    my ($name, $class, $id, $delete_route) = @$case;
    subtest "$name delete accepts the documented 204 response" => sub {
        load_command_class($class);
        my $cloud = mock_cloud(
            $delete_route => sub {
                my ($method, $path, %opts) = @_;
                ok(!defined $opts{body}, "$name delete sends no request body");
                return no_content();
            },
        );
        my $main = Test::CLIDeleteNoActionMain->new(cloud => $cloud, output => 'table');

        local @ARGV = ();
        my $cmd = $class->new_with_options;
        my $out = eval { capture_stdout(sub { $cmd->execute([$id], [$main]) }) };
        my $err = $@;
        ok(!$err, "$name delete executes on HTTP 204")
            or do { diag("died with: $err"); return };
        like($out, qr/deleted\./i, "$name delete reports completion after HTTP 204");
    };
}

done_testing;
