use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use lib "$Bin/../inc";

my $json_dir = $ENV{'API_CREDENTIAL_DIR'};

use Test::More;

unless ( $json_dir && -e $json_dir ) { plan skip_all => 'No credential file found in $ENV{"API_CREDENTIAL_DIR"} or path is invalid!'; }

use Webservice::OVH;

my $api = Webservice::OVH->new_from_json($json_dir);
ok( $api, "module ok" );

my $project = $api->cloud->projects->[0];

SKIP: {

    skip "No project exists for given account" unless $project;

    my $missing_parameter;
    eval { $missing_parameter = $project->network->create_private; };
    ok( !$missing_parameter, 'missing parameter ok' );

    my $new_network = $project->network->create_private( vlan_id => 12, name => 'test network' );
    ok( $new_network && ref $new_network eq 'Webservice::OVH::Cloud::Project::Network::Private', 'new network ok' );

    my $found = $project->network->private( $new_network->id );
    ok( $found && ref $found eq 'Webservice::OVH::Cloud::Project::Network::Private', 'found ok' );

    sleep(10);

    my $missing_parameter_subnet;
    eval {$new_network->create_subnet;};
    ok( !$missing_parameter_subnet, 'Missing Parameter ok' );

    my $subnet = $new_network->create_subnet( dhcp => 0, end => '192.168.1.24', network => '192.168.1.0/24', no_gateway => 1, region => 'GRA1', start => '192.168.1.12' );
    ok( $subnet          && ref $subnet eq 'Webservice::OVH::Cloud::Project::Network::Private::Subnet',  'new subnet ok' );
    ok( $subnet->project && ref $subnet->project eq 'Webservice::OVH::Cloud::Project',                   'project ok' );
    ok( $subnet->network && ref $subnet->network eq 'Webservice::OVH::Cloud::Project::Network::Private', 'network ok' );
    ok( $subnet->is_valid, 'valid ok' );
    ok( $subnet->id,       'id ok' );
    ok( $subnet->cidr,     'cidr ok' );
    ok( $subnet->ip_pools, 'ip_pools ok' );

    sleep(10);

    $subnet->delete;

    ok( !$subnet->is_valid, 'not valid ok' );

    sleep(30);

    $new_network->delete;

    ok( !$new_network->is_valid, 'not valid ok' );

}

done_testing();
