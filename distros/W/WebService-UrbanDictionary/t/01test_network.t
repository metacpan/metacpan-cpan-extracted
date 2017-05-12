use Test::More;
use Test::RequiresInternet;
BEGIN { plan tests => 1 }
use LWP::UserAgent;

# Note: This test is pointless now that Test::RequiresInternet is being used.

my $browser = LWP::UserAgent->new;
my $response = $browser->get("http://www.google.com");

ok($response->code == 200);

