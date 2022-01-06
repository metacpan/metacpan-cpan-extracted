use strict;
use warnings;

use Test::More;

use WebService::PayPal::PaymentsAdvanced::Mocker ();

for my $plack ( 1, 0 ) {
    {
        my $mocker
            = WebService::PayPal::PaymentsAdvanced::Mocker->new(
            plack => $plack );
        if ($plack) {
            isa_ok( $mocker->mocked_ua, 'Test::LWP::UserAgent' );
        }
        my $suffix = $plack ? 'Plack enabled' : 'Plack not enabled';
        ok( $mocker->payflow_link, "payflow_link $suffix" );
        ok( $mocker->payflow_pro,  "payflow_pro $suffix" );
    }
}

done_testing();
