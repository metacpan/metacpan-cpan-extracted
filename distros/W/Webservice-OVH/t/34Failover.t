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
    
    ok( $project->ip      && ref $project->ip eq 'Webservice::OVH::Cloud::Project::IP',           'ip ok' );
    
    my $failovers = $project->ip->failovers;
    ok( $failovers && ref $failovers eq 'ARRAY');
    
}

done_testing();