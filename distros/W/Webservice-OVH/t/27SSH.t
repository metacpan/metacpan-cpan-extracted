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

my $projects = $api->cloud->projects;
=head2
SKIP: {

    skip "No project exists for given account" unless scalar @$projects;
    
    my $project = $projects->[0];

    my $ssh_keys = $project->ssh_keys;
    ok( $ssh_keys && ref $ssh_keys eq 'ARRAY', 'ssh_keys ok' );
    
    my $ssh_key = $ssh_keys->[0];
    
    SKIP: {
        
        skip "No ssh keys exists for given project" unless scalar @$ssh_keys;

        my $missing_params;
        eval {$missing_params = $project->create_ssh();};
        ok(!$missing_params, 'Missing params ok');
        
        my $ssh_key = $project->create_ssh_key(name => 'Test key', public_key => $ssh_key->public_key );
        
        ok($ssh_key && ref $ssh_key eq 'Webservice::OVH::Cloud::Project::SSH', 'create ssh key ok');
        
        ok( $ssh_key->project && ref $ssh_key->project eq 'Webservice::OVH::Cloud::Project', 'project ok' );
        ok( $ssh_key->is_valid, 'Key valid ok');
        ok( $ssh_key->id, 'id ok' );
        ok( $ssh_key->properties && ref $ssh_key->properties eq 'HASH', 'properties ok' );
        ok( $ssh_key->finger_print, 'finger_print ok' );
        ok( $ssh_key->regions && ref $ssh_key->regions eq 'ARRAY', 'regions ok' );
        ok( $ssh_key->name, 'name ok' );
        ok( $ssh_key->public_key, 'public_key ok' );
            
        $ssh_key->delete;
        
        ok(!$ssh_key->is_valid, 'not valid ok');
    
    }

}
=cut
done_testing();
