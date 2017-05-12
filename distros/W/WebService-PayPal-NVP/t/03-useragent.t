use Test::RequiresInternet ( 'api-3t.sandbox.paypal.com' => '443' );
use Test::More;

use WebService::PayPal::NVP;

my $nvp = WebService::PayPal::NVP->new(
    branch => 'sandbox',
    pwd    => 'bar',
    sig    => 'seekrit',
    ua     => LWP::UserAgent->new( timeout => 3 ),
    user   => 'foo',
);

is( $nvp->ua->timeout, 3, 'Custom UserAgent set' );

done_testing();
