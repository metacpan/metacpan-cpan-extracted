# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

use lib qw(lib t/lib);

use WebService::Braintree::TestHelper;
use WebService::Braintree::ErrorResult;
use WebService::Braintree::Result;

subtest "multiple errors" => sub {
    my $response = {
        'api_error_response' => {
            "message" => "Customer ID is invalid.\nCredit card number is invalid."
        }
    };

    my $result = WebService::Braintree::ErrorResult->new($response->{api_error_response});
    invalidate_result($result) or return;

    is ($result->message, "Customer ID is invalid.\nCredit card number is invalid.");
};

subtest "allow access to relevant objects on response" => sub {
    my $amount = amount(40, 50);
    my $response = {
        transaction => {
            amount => $amount,
            type => "sale"
        }
    };

    my $result = WebService::Braintree::Result->new(response => $response);
    is($result->transaction->amount, $amount);
    is($result->customer, undef);
};

done_testing();
