use strict;
use warnings;

use Test::More;

use WebService::PayPal::PaymentsAdvanced::Mocker::SilentPOST;

my $post = WebService::PayPal::PaymentsAdvanced::Mocker::SilentPOST->new(
    secure_token_id => 'FOO' );

my @methods = (
    'credit_card_auth_verification_success',
    'credit_card_duplicate_invoice_id',
    'credit_card_success',
    'paypal_success',
);

for my $method (@methods) {
    ok(
        $post->$method,
        $method
    );
}

done_testing();
