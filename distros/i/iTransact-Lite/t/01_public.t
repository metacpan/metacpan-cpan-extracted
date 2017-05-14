use Test::More;
use lib '../lib';

use_ok('iTransact::Lite');
my $itransact = iTransact::Lite->new(
  gateway_id => 999,
  api_key => 'xxx',
  api_username => 'mycoolsite',
);
isa_ok($itransact, 'iTransact::Lite');

my $response = $itransact->submit({
        AuthTransaction => {
            CustomerData    => {
                Email           => 'user@example.com',
                BillingAddress  => {
                    Address1        => '123 Main St',
                    FirstName       => 'John',
                    LastName        => 'Doe',
                    City            => 'Anytown',
                    State           => 'WI',
                    Zip             => '00000',
                    Country         => 'US',
                    Phone           => '608-555-1212',
                },
                CustId          => '123',
            },
            Total               => sprintf('%.2f', 50),
            Description         => 'Space Sneakers',
            AccountInfo         => {
                CardAccount => {
                    AccountNumber   => '2323232323232323',
                    ExpirationMonth => '07',
                    ExpirationYear  => '2019',
                    CVVNumber       => '999',
                },
            },
            TransactionControl  => {
                SendCustomerEmail   => 'FALSE',
                SendMerchantEmail   => 'FALSE',
                TestMode            => 'TRUE',
            },
        },
});

is $response->{GatewayInterface}{TransactionResponse}{TransactionResult}{ErrorMessage}, 'Invalid login credentials', 'connected to service';

done_testing();


