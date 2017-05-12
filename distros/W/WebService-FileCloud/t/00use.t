use Test::More tests => 1;
use WebService::FileCloud;

my $websvc = WebService::FileCloud->new();

ok( defined( $websvc ), "object instantiated" );