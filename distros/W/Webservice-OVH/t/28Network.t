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
# Get first project
my $project = $api->cloud->projects->[0];

SKIP: {

    skip "No project exists for given account" unless $project;
    
    ok($project->network, 'Network ok');
    
    my $privates = $project->network->privates;
    ok($privates && ref $privates eq 'ARRAY', 'privates ok');
    
    SKIP: {
        
        skip "No project exists for given account" unless $privates->[0];
    
        my $private = $privates->[0];
        my $single_private = $project->network->private($private->id);
        ok($single_private && ref $single_private eq 'Webservice::OVH::Cloud::Project::Network::Private', 'found private ok');
    }
    
    ok( $project->network->project && ref $project->network->project eq 'Webservice::OVH::Cloud::Project', 'project ok');
    
}
=cut
done_testing();