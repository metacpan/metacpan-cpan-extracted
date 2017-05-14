use Test::More;
use lib '../lib';

use_ok('iTransact::Lite');
my $itransact = iTransact::Lite->new(
  gateway_id => $ENV{IT_GATEWAY_ID},
  api_key => $ENV{IT_API_KEY},
  api_username => $ENV{IT_API_USERNAME},
);
isa_ok($itransact, 'iTransact::Lite');

my $response = $itransact->submit({
        AuthTransaction => {
            CustomerData    => {
                Email           => 'user@example.com',
                BillingAddress  => {
                    Address1        => '1360 Regent St #145',
                    FirstName       => 'JT',
                    LastName        => 'Smith',
                    City            => 'Madison',
                    State           => 'WI',
                    Zip             => '53715',
                    Country         => 'US',
                    Phone           => '608-555-1212',
                },
                CustId          => '123',
            },
            Total               => sprintf('%.2f', 5),
            Description         => 'This Is A Test',
            AccountInfo         => {
                CardAccount => {
                    AccountNumber   => $ENV{IT_CC},
                    ExpirationMonth => $ENV{IT_EXP_MONTH},
                    ExpirationYear  => $ENV{IT_EXP_YEAR},
                    CVVNumber       => $ENV{IT_CVV},
                },
            },
            TransactionControl  => {
                SendCustomerEmail   => 'FALSE',
                SendMerchantEmail   => 'FALSE',
                TestMode            => 'TRUE',
            },
        },
});

is $response->{GatewayInterface}{TransactionResponse}{TransactionResult}{ErrorMessage}, 'ok', 'connected to service';

done_testing();

