use Test2::V0;

use lib './lib';
use WebService::Readwise;

my $rw = WebService::Readwise->new(
    #   token => 'foo',
);

is( $rw->base_url,
    'https://readwise.io/api/v2/',
    'Base url defaults to https://readwise.io/api/v2/auth/'
);

$rw = WebService::Readwise->new( base_url => 'https://fast.com' );
is( $rw->base_url, 'https://fast.com', 'Base url can be set' );

done_testing;
