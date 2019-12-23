use Test::More;
use lib '../lib/';
BEGIN { use_ok( 'WebService::Thumbalizr' ); }
require_ok( 'WebService::Thumbalizr' );

my $thumbalizr = WebService::Thumbalizr->new(key => 'my_key', secret => 'my_secret');

done_testing;