use strict;
use Test::More;
use Test::Mock::Guard qw/mock_guard/;

use Crypt::OpenSSL::RSA;
use JSON::XS;
use MIME::Base64;
use Web::MarketReceipt::Verifier::GooglePlay;

subtest 'api version v2 format' => sub {
    my $mock = mock_guard('Crypt::OpenSSL::RSA', {
        'verify' => sub {
            my ($signed_data, $signature) = @_;

            return 1;
        }
    });

    my $signed_data = {
        orders => [{
            purchaseState => 4,
            productId     => '12345abcd',
            orderId       => 'abcdefg12345',
            purchaseTime  => 12345678,
        }],
    };
    my $signature = 'dummy signature';
    my $dummy_rsa = Crypt::OpenSSL::RSA->generate_key(1024);

    my $result = Web::MarketReceipt::Verifier::GooglePlay->new(
        public_key => $dummy_rsa->get_public_key_string(),
    )->verify(
        signed_data => encode_base64(encode_json $signed_data),
        signature   => encode_base64($signature),
    );

    isa_ok $result, 'Web::MarketReceipt';
    ok $result->is_success;
    is scalar @{$result->orders}, 1;
    is $result->orders->[0]->state, 'pending';
    is $result->orders->[0]->product_identifier, '12345abcd';
    is $result->orders->[0]->unique_identifier, 'GooglePlay:' . 'abcdefg12345';
};

subtest 'api version v3 format' => sub {
    my $mock = mock_guard('Crypt::OpenSSL::RSA', {
        'verify' => sub {
            my ($signed_data, $signature) = @_;

            return 1;
        }
    });

    my $signed_data = {
        purchaseState => 0,
        productId     => '12345abcd',
        orderId       => 'abcdefg12345',
        purchaseTime  => 12345678,
    };
    my $signature = 'dummy signature';
    my $dummy_rsa = Crypt::OpenSSL::RSA->generate_key(1024);

    my $result = Web::MarketReceipt::Verifier::GooglePlay->new(
        public_key => $dummy_rsa->get_public_key_string(),
    )->verify(
        signed_data => encode_base64(encode_json $signed_data),
        signature   => encode_base64($signature),
    );

    isa_ok $result, 'Web::MarketReceipt';
    ok $result->is_success;
    is scalar @{$result->orders}, 1;
    is $result->orders->[0]->state, 'purchased';
    is $result->orders->[0]->product_identifier, '12345abcd';
    is $result->orders->[0]->unique_identifier, 'GooglePlay:' . 'abcdefg12345';
};

done_testing;
