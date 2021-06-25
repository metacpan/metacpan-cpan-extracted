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
=head2
ok( $api->cloud, "Cloud object ok" );
ok( $api->cloud->price && ref $api->cloud->price eq 'HASH', "Price information ok" );

my $projects = $api->cloud->projects;

ok( $projects && ref $projects eq 'ARRAY', "projects ok" );

if ( scalar @$projects > 0 ) {

    my $project = $projects->[0];
    ok( ref $project eq 'Webservice::OVH::Cloud::Project', "Array content ok" );
    my $test_project = $api->cloud->project( $project->id );
    ok( $api->cloud->project_exists( $project->id ), "Project found ok" );
    ok( $test_project,                               "single call ok" );
}
=cut
done_testing();
