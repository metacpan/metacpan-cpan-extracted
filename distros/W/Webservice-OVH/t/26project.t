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

# Get example project
my $project = $api->cloud->projects->[0];

SKIP: {

    skip "No project exists for given account" unless $project;

    my $properties = $project->properties;
    ok( $properties && ref $properties eq 'HASH', "Properties ok" );
    ok( $project->description, 'description ok' );
    ok( $project->unleash == 0 || $project->unleash == 1, 'unleash ok' );
    ok( ( $project->order && ref $project->order eq 'Webservice::OVH::Me::Order' ) || !$project->order, 'order ok' );
    ok( $project->status, 'status ok' );
    ok( $project->access, 'access ok' );

    my $old_description = $project->description;
    my $new_description = "New description";
    $project->change($new_description);
    ok( $project->description eq $new_description, 'project change ok' );
    $project->change($old_description);
    ok( $project->description eq $old_description, 'project restore ok' );

    ok( $project->vrack && ref $project->vrack eq 'HASH', 'vrack ok' );

    my $instances = $project->instances;
    ok( $instances && ref $instances eq 'ARRAY', 'instances ok' );

    # No more positive instance testing, because ovh doesn't provide a sandbox to test and instances cost money
    my $ninstance = $project->instance('0000-0000');
    ok( !$ninstance, 'Negative instance ok' );
    ok( !$project->instance_exists('0000-0000') );

    my $no_parameter_instance;
    eval { $no_parameter_instance = $project->create_instance; };
    ok( !$no_parameter_instance, 'Missing Parameter ok' );

    ok( $project->regions && ref $project->regions eq 'ARRAY', 'regions ok' );
    my $region            = $project->regions->[0];
    my $region_properties = $project->region($region);
    ok( $region, 'single region ok' );
    ok( $region_properties && ref $region_properties eq 'HASH', 'region properties ok' );

    ok( $project->flavors && ref $project->flavors eq 'ARRAY', 'flavors ok' );
    my $flavor            = $project->flavors->[0];
    my $flavor_properties = $project->flavor( $flavor->{id} );
    ok( $flavor, 'single flavor ok' );
    ok( $flavor_properties && ref $flavor_properties eq 'HASH', 'flavor properties ok' );

    ok( $project->images && ref $project->images eq 'ARRAY', 'images ok' );
    my $image        = $project->images->[0];
    my $single_image = $project->image( $image->id );
    ok( $image, 'single image ok' );
    ok( $single_image && ref $single_image eq 'Webservice::OVH::Cloud::Project::Image', 'image found ok' );
    ok( $project->image_exists( $image->id ), 'image exists ok' );

    my $ssh_keys = $project->ssh_keys;
    ok( $ssh_keys && ref $ssh_keys eq 'ARRAY', 'ssh_keys ok' );

    SKIP: {

        skip "No ssh keys found" unless scalar @$ssh_keys;

        my $ssh_key        = $ssh_keys->[0];
        my $single_ssh_key = $project->ssh_key( $ssh_key->id );

        ok( $ssh_key, 'single ssh key ok' );
        ok( $single_ssh_key && ref $single_ssh_key eq 'Webservice::OVH::Cloud::Project::SSH', 'ssh key found ok' );
        ok( $project->ssh_key_exists( $single_ssh_key->id ), 'SSH key exists ok' );
    }

    ok( $project->network && ref $project->network eq 'Webservice::OVH::Cloud::Project::Network', 'network ok' );
    ok( $project->ip      && ref $project->ip eq 'Webservice::OVH::Cloud::Project::IP',           'ip ok' );
}

done_testing();
