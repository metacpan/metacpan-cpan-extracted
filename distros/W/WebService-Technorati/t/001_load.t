# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'WebService::Technorati' ); }
my $apiKey = 'a_key_that_wont_work_with_a_live_query';
my $object = WebService::Technorati->new( key => $apiKey );
isa_ok ($object, 'WebService::Technorati');


