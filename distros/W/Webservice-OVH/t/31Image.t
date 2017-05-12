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
    
    my $images = $project->images;
    ok($images && ref $images eq 'ARRAY' );
    my $image = $images->[0];
    ok($image, 'image ok');
    my $single_image = $project->image($image->id);
    ok($single_image, 'image found ok');
    
    ok($image->project && ref $image->project eq 'Webservice::OVH::Cloud::Project', 'project ok');
    ok($image->id, 'id ok');
    ok($image->properties && ref $image->properties eq 'HASH', 'properties ok');
    ok($image->visibility, 'visibility ok');
    ok($image->status, 'status ok');
    ok($image->name, 'name ok');
    ok($image->region, 'region ok');
    ok($image->size, 'size ok');
    ok($image->creation_date && ref $image->creation_date eq 'DateTime', 'creation_date ok');
    ok($image->user, 'user ok');
    ok($image->type, 'type ok');
    
}

done_testing();