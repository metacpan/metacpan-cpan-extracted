use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";
use lib "$Bin/../inc";

my $json_dir = $ENV{'API_CREDENTIAL_DIR'};
my $mode     = $ARGV[0];

unless ( $json_dir && -e $json_dir ) { die 'No credential file found in $ENV{"API_CREDENTIAL_DIR"} or path is invalid!'; }

use Webservice::OVH;

my $api = Webservice::OVH->new_from_json($json_dir);

my $projects = $api->cloud->projects;
print STDERR "Choosing first project\n";
my $project = $projects->[0] if scalar @$projects;
print STDERR $project->id . "\n";

# Test Access to objects

if ( $mode && ( $mode == 1 || $mode eq 'object_access' ) ) {

    my $flavors = $project->flavors;
    print STDERR "Picking random flavor\n";
    my $flavor_count = scalar @$flavors;
    my $flavor       = $flavors->[ int( rand $flavor_count ) ];
    print STDERR $flavor->{id} . "\n";

    my $images = $project->images;
    print STDERR "Picking random image\n";
    my $image_count = scalar @$images;
    my $image       = $images->[ int( rand $image_count ) ];

    my $regions = $project->regions;
    print STDERR "Choosing first region\n";
    my $region = $regions->[0];
    print STDERR $region . "\n";

    my $ssh_keys = $project->ssh_keys($region);
    print STDERR "Picking random key\n";
    my $key_count = scalar @$ssh_keys;
    my $ssh_key   = $ssh_keys->[ int( rand $key_count ) ];
    print STDERR $ssh_key->id . "\n";

    # Instance testing

} elsif ( $mode && ( $mode == 2 || $mode eq 'instance_test' ) ) {

    # Creating a new instance
    my $instance = $project->create_instance( flavor_id => "30fc1f25-348e-458f-bc0e-029a533c6c02", image_id => "d79802bf-0b36-47a4-acb6-76a293b0c037", name => "Test-Instance", region => "GRA1", ssh_key_id => "55474630636d6c6a6130746c65513d3d" );

    # Creating an instance takes some time
    sleep(60);

    # Finding instance if time given was not enough
    # Put your instance id there
    # my $instance = $project->instance("c0c1c468-e775-45f9-a2ca-cddac680d8a4");

    # Deleting instance
    $instance->delete;

    # test network and subnet

} elsif ( $mode && ( $mode == 3 || $mode eq 'network_test' ) ) {

    # Getting available Networks for the choosen project
    my $private_networks = $project->network->privates;
    my $first_network    = $private_networks->[0];
    my $found_network    = $project->network->private( $first_network->id );
    my $subnets          = $found_network->subnets;

    # Creating a new network in all regions
    # region can be specified through region => xxxx parameter
    my $new_network = $project->network->create_private( name => "Test Network 1", vlan_id => 6 );

    # Existing network, needs to be called when error occures
    #my $new_network = $api->cloud->project("c38be774d1124b9180377d4865a960af")->network->private("pn-1775_6");

    # Network needs time to be created
    sleep(10);

    # Creating a new subnet
    my $new_subnet = $new_network->create_subnet( dhcp => 'true', end => "192.168.1.24", start => "192.168.1.12", no_gateway => 'false', region => "BHS1", network => "192.168.1.0/24" );

    # Cleaning up
    $new_subnet->delete;
    $new_network->delete;

}
