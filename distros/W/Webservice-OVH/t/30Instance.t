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
=head2
SKIP: {

    skip "No project exists for given account" unless $project;

    my $instances = $project->instances;
    ok( $instances && ref $instances eq 'ARRAY', 'instances ok' );

    # No more positive instance testing, because ovh doesn't provide a sandbox to test and instances cost money
    my $ninstance = $project->instance('0000-0000');
    ok( !$ninstance, 'Negative instance ok' );
    ok( !$project->instance_exists('0000-0000') );

    my $no_parameter_instance;
    eval { $no_parameter_instance = $project->create_instance; };
    ok( !$no_parameter_instance, 'Missing Parameter ok' );
    
    ok( $project->instance, 'static instance ok' );
    ok( $project->instance->groups && ref $project->instance->groups eq 'ARRAY', 'groups ok' );

}
=cut
done_testing();
