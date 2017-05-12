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

    ok( $project->instance, 'static instance ok' );

    my $missing_params;
    eval { $missing_params = $project->instance->create_group; };
    ok( !$missing_params, 'missing params ok' );

    my $new_group = $project->instance->create_group( region => 'GRA1', name => 'Test group' );
    ok( $new_group && ref $new_group eq 'Webservice::OVH::Cloud::Project::Instance::Group', 'new group ok' );
    ok( $new_group->is_valid, 'valid ok' );

    ok( $new_group->id, 'id ok' );
    ok( $new_group->properties && ref $new_group->properties eq 'HASH', 'properties ok' );
    ok( $new_group->name,   'name ok' );
    ok( $new_group->region, 'region ok' );

    $new_group->delete;
    ok( !$new_group->is_valid, 'not valid ok' );

}

done_testing();
