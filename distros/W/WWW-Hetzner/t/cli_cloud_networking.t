use strict;
use warnings;
use Test::More;
use lib 't/lib';

use Test::WWW::Hetzner::Mock;
use WWW::Hetzner::CLI::Cmd::Firewall;
use WWW::Hetzner::CLI::Cmd::Firewall::Cmd::AddRule;
use WWW::Hetzner::CLI::Cmd::Firewall::Cmd::ApplyTo;
use WWW::Hetzner::CLI::Cmd::Firewall::Cmd::Create;
use WWW::Hetzner::CLI::Cmd::Firewall::Cmd::Describe;
use WWW::Hetzner::CLI::Cmd::Firewall::Cmd::List;
use WWW::Hetzner::CLI::Cmd::Firewall::Cmd::RemoveFrom;
use WWW::Hetzner::CLI::Cmd::FloatingIp;
use WWW::Hetzner::CLI::Cmd::FloatingIp::Cmd::Assign;
use WWW::Hetzner::CLI::Cmd::FloatingIp::Cmd::Create;
use WWW::Hetzner::CLI::Cmd::FloatingIp::Cmd::Describe;
use WWW::Hetzner::CLI::Cmd::FloatingIp::Cmd::List;
use WWW::Hetzner::CLI::Cmd::FloatingIp::Cmd::Unassign;
use WWW::Hetzner::CLI::Cmd::LoadBalancer;
use WWW::Hetzner::CLI::Cmd::LoadBalancer::Cmd::AddService;
use WWW::Hetzner::CLI::Cmd::LoadBalancer::Cmd::AddTarget;
use WWW::Hetzner::CLI::Cmd::LoadBalancer::Cmd::Create;
use WWW::Hetzner::CLI::Cmd::LoadBalancer::Cmd::Describe;
use WWW::Hetzner::CLI::Cmd::LoadBalancer::Cmd::List;
use WWW::Hetzner::CLI::Cmd::Network;
use WWW::Hetzner::CLI::Cmd::Network::Cmd::AddRoute;
use WWW::Hetzner::CLI::Cmd::Network::Cmd::AddSubnet;
use WWW::Hetzner::CLI::Cmd::Network::Cmd::Create;
use WWW::Hetzner::CLI::Cmd::Network::Cmd::Describe;
use WWW::Hetzner::CLI::Cmd::Network::Cmd::List;

# Parent usage, list and describe paths each run their real execute method;
# mutations inspect decoded JSON at the mock IO seam and opt out of polling.
{
    package Test::CLICloudNetworkingMain;
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
    my $cloud = mock_cloud(@{ $case{routes} // [] });
    my $main = Test::CLICloudNetworkingMain->new(cloud => $cloud, output => ($case{output} // 'table'));

    local @ARGV = @{ $case{argv} // [] };
    my $cmd = $case{class}->new_with_options;
    ok($cmd->no_wait, "$case{name} parsed --no-wait") if $case{no_wait};
    my $out = eval { capture_stdout(sub { $cmd->execute($case{args} // [], [$main]) }) };
    my $err = $@;
    ok(!$err, "$case{name} executes")
        or do { diag("died with: $err"); return };
    like($out, $case{like}, "$case{name} reports a meaningful result");
}

for my $case (
    [ 'firewall parent',       'WWW::Hetzner::CLI::Cmd::Firewall',                         [],                              qr/Subcommands:/ ],
    [ 'firewall list',         'WWW::Hetzner::CLI::Cmd::Firewall::Cmd::List',              [ 'GET /firewalls' => load_fixture('firewalls_list') ], qr/web-firewall/ ],
    [ 'firewall describe',     'WWW::Hetzner::CLI::Cmd::Firewall::Cmd::Describe',          [ 'GET /firewalls/300' => load_fixture('firewalls_get') ], qr/Rules:/, [ '300' ] ],
    [ 'floating-ip parent',    'WWW::Hetzner::CLI::Cmd::FloatingIp',                       [],                              qr/Subcommands:/ ],
    [ 'floating-ip list',      'WWW::Hetzner::CLI::Cmd::FloatingIp::Cmd::List',            [ 'GET /floating_ips' => load_fixture('floating_ips_list') ], qr/203\.0\.113/ ],
    [ 'floating-ip describe',  'WWW::Hetzner::CLI::Cmd::FloatingIp::Cmd::Describe',        [ 'GET /floating_ips/500' => load_fixture('floating_ips_get') ], qr/Location:\s+fsn1/, [ '500' ] ],
    [ 'load-balancer parent',  'WWW::Hetzner::CLI::Cmd::LoadBalancer',                     [],                              qr/Subcommands:/ ],
    [ 'load-balancer list',    'WWW::Hetzner::CLI::Cmd::LoadBalancer::Cmd::List',          [ 'GET /load_balancers' => load_fixture('load_balancers_list') ], qr/web-lb/ ],
    [ 'load-balancer describe','WWW::Hetzner::CLI::Cmd::LoadBalancer::Cmd::Describe',      [ 'GET /load_balancers/900' => load_fixture('load_balancers_get') ], qr/Services:/, [ '900' ] ],
    [ 'network parent',        'WWW::Hetzner::CLI::Cmd::Network',                          [],                              qr/Subcommands:/ ],
    [ 'network list',          'WWW::Hetzner::CLI::Cmd::Network::Cmd::List',               [ 'GET /networks' => load_fixture('networks_list') ], qr/my-network/ ],
    [ 'network describe',      'WWW::Hetzner::CLI::Cmd::Network::Cmd::Describe',           [ 'GET /networks/100' => load_fixture('networks_get') ], qr/IP Range:/, [ '100' ] ],
) {
    my ($name, $class, $routes, $like, $args) = @$case;
    subtest $name => sub {
        run_command(name => $name, class => $class, routes => $routes, args => $args, like => $like);
    };
}

for my $case (
    {
        name   => 'firewall create', class => 'WWW::Hetzner::CLI::Cmd::Firewall::Cmd::Create',
        argv   => [ '--name', 'edge-fw', '--no-wait' ], route => 'POST /firewalls',
        body   => { name => 'edge-fw' }, fixture => 'firewalls_create', like => qr/Firewall created with ID 400/,
    },
    {
        name   => 'firewall apply-to', class => 'WWW::Hetzner::CLI::Cmd::Firewall::Cmd::ApplyTo',
        argv   => [ '--server', '123456', '--no-wait' ], args => [ '300' ], route => 'POST /firewalls/300/actions/apply_to_resources',
        body   => { apply_to => [{ type => 'server', server => { id => 123456 } }] }, fixture => 'firewalls_action', like => qr/Firewall apply requested\./,
    },
    {
        name   => 'firewall remove-from', class => 'WWW::Hetzner::CLI::Cmd::Firewall::Cmd::RemoveFrom',
        argv   => [ '--server', '123456', '--no-wait' ], args => [ '300' ], route => 'POST /firewalls/300/actions/remove_from_resources',
        body   => { remove_from => [{ type => 'server', server => { id => 123456 } }] }, fixture => 'firewalls_action', like => qr/Firewall removal requested\./,
    },
    {
        name   => 'floating-ip create', class => 'WWW::Hetzner::CLI::Cmd::FloatingIp::Cmd::Create',
        argv   => [ '--type', 'ipv4', '--home-location', 'fsn1', '--name', 'frontend', '--description', 'edge address', '--no-wait' ],
        route  => 'POST /floating_ips', body => { type => 'ipv4', home_location => 'fsn1', name => 'frontend', description => 'edge address' }, fixture => 'floating_ips_create', like => qr/Floating IP created with ID 600/,
    },
    {
        name   => 'floating-ip assign', class => 'WWW::Hetzner::CLI::Cmd::FloatingIp::Cmd::Assign',
        argv   => [ '--server', '123456', '--no-wait' ], args => [ '500' ], route => 'POST /floating_ips/500/actions/assign',
        body   => { server => 123456 }, fixture => 'floating_ips_action', like => qr/Floating IP assignment requested\./,
    },
    {
        name   => 'floating-ip unassign', class => 'WWW::Hetzner::CLI::Cmd::FloatingIp::Cmd::Unassign',
        argv   => [ '--no-wait' ], args => [ '500' ], route => 'POST /floating_ips/500/actions/unassign',
        body   => {}, fixture => 'floating_ips_action', like => qr/Floating IP unassignment requested\./,
    },
    {
        name   => 'load-balancer create', class => 'WWW::Hetzner::CLI::Cmd::LoadBalancer::Cmd::Create',
        argv   => [ '--name', 'new-lb', '--type', 'lb11', '--location', 'fsn1', '--no-wait' ], route => 'POST /load_balancers',
        body   => { name => 'new-lb', load_balancer_type => 'lb11', location => 'fsn1' }, fixture => 'load_balancers_create', like => qr/Load balancer created with ID 1000/,
    },
    {
        name   => 'load-balancer add-target', class => 'WWW::Hetzner::CLI::Cmd::LoadBalancer::Cmd::AddTarget',
        argv   => [ '--server', '123456', '--no-wait' ], args => [ '900' ], route => 'POST /load_balancers/900/actions/add_target',
        body   => { type => 'server', server => { id => 123456 } }, fixture => 'load_balancers_action', like => qr/Target add requested\./,
    },
    {
        name   => 'load-balancer add-service', class => 'WWW::Hetzner::CLI::Cmd::LoadBalancer::Cmd::AddService',
        argv   => [ '--protocol', 'http', '--listen-port', '80', '--destination-port', '8080', '--no-wait' ], args => [ '900' ], route => 'POST /load_balancers/900/actions/add_service',
        body   => { protocol => 'http', listen_port => 80, destination_port => 8080 }, fixture => 'load_balancers_action', like => qr/Service add requested\./,
    },
    {
        name   => 'network create', class => 'WWW::Hetzner::CLI::Cmd::Network::Cmd::Create',
        argv   => [ '--name', 'backend-two', '--ip-range', '10.10.0.0/16' ], route => 'POST /networks',
        body   => { name => 'backend-two', ip_range => '10.10.0.0/16' }, fixture => 'networks_create', like => qr/Network created with ID 200/,
    },
    {
        name   => 'network add-subnet', class => 'WWW::Hetzner::CLI::Cmd::Network::Cmd::AddSubnet',
        argv   => [ '--ip-range', '10.10.1.0/24', '--type', 'cloud', '--network-zone', 'eu-central', '--no-wait' ], args => [ '100' ], route => 'POST /networks/100/actions/add_subnet',
        body   => { ip_range => '10.10.1.0/24', type => 'cloud', network_zone => 'eu-central' }, fixture => 'networks_action', like => qr/Subnet add requested\./,
    },
    {
        name   => 'network add-route', class => 'WWW::Hetzner::CLI::Cmd::Network::Cmd::AddRoute',
        argv   => [ '--destination', '10.11.0.0/16', '--gateway', '10.10.1.1', '--no-wait' ], args => [ '100' ], route => 'POST /networks/100/actions/add_route',
        body   => { destination => '10.11.0.0/16', gateway => '10.10.1.1' }, fixture => 'networks_action', like => qr/Route add requested\./,
    },
) {
    subtest "$case->{name}: sends the Cloud mutation payload" => sub {
        run_command(
            name    => $case->{name}, class => $case->{class}, argv => $case->{argv}, args => $case->{args}, no_wait => ($case->{argv}[-1] eq '--no-wait'),
            routes  => [
                $case->{route} => sub {
                    my ($method, $path, %opts) = @_;
                    is_deeply($opts{body}, $case->{body}, "$case->{name} decoded JSON body");
                    return load_fixture($case->{fixture});
                },
            ],
            like => $case->{like},
        );
    };
}

subtest 'firewall apply-to waits for every action in an action array' => sub {
    my @slept;
    my $cloud = mock_cloud(
        'POST /firewalls/300/actions/apply_to_resources' => sub {
            my ($method, $path, %opts) = @_;
            is_deeply(
                $opts{body},
                { apply_to => [{ type => 'server', server => { id => 123456 } }] },
                'apply-to posts its resource envelope before waiting',
            );
            my $running = load_fixture('firewalls_action');
            $running->{actions}[0]{status} = 'running';
            $running->{actions}[0]{progress} = 0;
            return $running;
        },
        'GET /actions/8888' => sub {
            my $done = load_fixture('firewalls_action');
            $done->{actions}[0]{status} = 'success';
            $done->{actions}[0]{progress} = 100;
            return { action => $done->{actions}[0] };
        },
    );
    $cloud->sleeper(sub { push @slept, $_[0] });
    my $main = Test::CLICloudNetworkingMain->new(cloud => $cloud, output => 'table');

    local @ARGV = ('--server', '123456');
    my $cmd = WWW::Hetzner::CLI::Cmd::Firewall::Cmd::ApplyTo->new_with_options;
    my $out = capture_stdout(sub { $cmd->execute(['300'], [$main]) });
    like($out, qr/Firewall applied\./, 'reports completion only after the action array finished');
    is_deeply(\@slept, [1], 'waited for the action array without real sleeping');
};

subtest 'firewall add-rule sends the complete replacement rules array' => sub {
    run_command(
        name    => 'firewall add-rule',
        class   => 'WWW::Hetzner::CLI::Cmd::Firewall::Cmd::AddRule',
        argv    => [ '--direction', 'in', '--protocol', 'tcp', '--port', '443', '--source-ips', '192.0.2.0/24', '--no-wait' ],
        args    => [ '300' ],
        no_wait => 1,
        routes  => [
            'GET /firewalls/300' => load_fixture('firewalls_get'),
            'POST /firewalls/300/actions/set_rules' => sub {
                my ($method, $path, %opts) = @_;
                is_deeply(
                    $opts{body}{rules}[-1],
                    { direction => 'in', protocol => 'tcp', port => '443', source_ips => ['192.0.2.0/24'] },
                    'new CLI rule is appended to the complete rule set',
                );
                is(scalar @{ $opts{body}{rules} }, 3, 'existing rules are retained');
                return load_fixture('firewalls_action');
            },
        ],
        like => qr/Rule add requested\./,
    );
};

done_testing;
