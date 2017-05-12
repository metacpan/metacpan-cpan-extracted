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
    eval {$missing_parameter = $project->network->create_private;};
    ok(!$missing_parameter, 'missing parameter ok');
    
    my $new_network = $project->network->create_private( vlan_id => 12, name => 'test network');
    ok($new_network && ref $new_network eq 'Webservice::OVH::Cloud::Project::Network::Private', 'new network ok');
    
    my $found = $project->network->private($new_network->id);
    ok($found && ref $found eq 'Webservice::OVH::Cloud::Project::Network::Private', 'found ok');
    
    sleep(10);
    
    ok( $new_network->project && ref $new_network->project eq 'Webservice::OVH::Cloud::Project', 'project ok');
    ok( $new_network->is_valid, 'is valid ok' );
    ok( $new_network->id, 'id ok' );
    ok( $new_network->properties && ref $new_network->properties eq 'HASH', 'properties ok');
    ok( $new_network->regions && ref $new_network->regions eq 'ARRAY', 'regions ok');
    ok( $new_network->status, 'status ok');
    ok( $new_network->name, 'name ok');
    ok( $new_network->type, 'type ok' );
    ok( $new_network->vlan_id, 'vlan_id ok');
    
    my $new_name = 'New Name';
    $new_network->change($new_name);
    ok($new_network->name eq $new_name, 'change ok'); 
    
    my $subnets = $new_network->subnets;
    ok($subnets && ref $subnets eq 'ARRAY', 'subnets ok');
    
    sleep(30);
    
    $new_network->delete;
    
    ok(!$new_network->is_valid, 'not valid ok');
}

done_testing();