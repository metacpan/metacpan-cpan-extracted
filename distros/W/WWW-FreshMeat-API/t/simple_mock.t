use Test::More tests => 9;
use WWW::FreshMeat::API;


# just doing some quick & dirty mock tests using returns defined in metadata in V1_03.
# Proper tests to follow!

my $fm = WWW::FreshMeat::API->new( mock => 1 );


is ref( $fm->login ), 'HASH', 'login test';

is ref( $fm->fetch_available_licenses ), 'ARRAY', 'fetch_available_licenses test';

is ref( $fm->fetch_available_release_foci ), 'HASH', 'fetch_available_release_foci test';

is ref( $fm->fetch_branch_list ), 'ARRAY', 'fetch_branch_list test';

is ref( $fm->fetch_project_list ), 'ARRAY', 'fetch_project_list test';

is ref( $fm->fetch_release ), 'HASH', 'fetch_release test';

is ref( $fm->publish_release ), 'HASH', 'publish_release test';

is ref( $fm->withdraw_release ), 'HASH', 'withdraw_release test';

is ref( $fm->logout ), 'HASH', 'logout test';
