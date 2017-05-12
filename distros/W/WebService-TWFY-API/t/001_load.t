# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'WebService::TWFY::API' ); }

my $rh = { key => 'ABC123' };
my $api = WebService::TWFY::API->new( $rh );
isa_ok ($api, 'WebService::TWFY::API');


