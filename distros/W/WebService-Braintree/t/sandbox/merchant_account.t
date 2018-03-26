# vim: sw=4 ts=4 ft=perl

use 5.010_001;
use strictures 1;

use Test::More;

BEGIN {
    plan skip_all => "sandbox_config.json required for sandbox tests"
        unless -s 'sandbox_config.json';
}

use lib qw(lib t/lib);

use WebService::Braintree;
use WebService::Braintree::ErrorCodes::MerchantAccount;
use WebService::Braintree::ErrorCodes::MerchantAccount::Individual;
use WebService::Braintree::ErrorCodes::MerchantAccount::Individual::Address;
use WebService::Braintree::ErrorCodes::MerchantAccount::Funding;
use WebService::Braintree::ErrorCodes::MerchantAccount::Business;
use WebService::Braintree::ErrorCodes::MerchantAccount::Business::Address;
use WebService::Braintree::TestHelper qw(sandbox);
use WebService::Braintree::Test;

use Storable qw(dclone);

WebService::Braintree::TestHelper->verify_sandbox
    || BAIL_OUT 'Sandbox is not prepared properly. Please read xt/README.';

my $valid_application_params = {
    individual => {
        first_name => 'Job',
        last_name => 'Leoggs',
        email => 'job@leoggs.com',
        phone => '555-555-1212',
        address => {
            street_address => '193 Credibility St.',
            postal_code => '60647',
            locality => 'Avondale',
            region => 'IN',
        },
        date_of_birth => '10/9/1985',
        ssn => '123-00-1235',
    },
    business => {
        dba_name => 'In good company',
        legal_name => 'In good company',
        tax_id => '123456780',
        address => {
            street_address => '193 Credibility St.',
            postal_code => '60647',
            locality => 'Avondale',
            region => 'IN',
        },
    },
    funding => {
        destination => WebService::Braintree::MerchantAccount::FundingDestination::Email,
        email => 'job@leoggs.com',
        mobile_phone => '3125551212',
        routing_number => '122100024',
        account_number => '43759348799',
        descriptor => 'Joes Leoggs IN',
    },
    tos_accepted => 'true',
    master_merchant_account_id => 'sandbox_master_merchant_account',
};

subtest 'Successful Create' => sub {
    my $result = WebService::Braintree::MerchantAccount->create($valid_application_params);
    validate_result($result) or return;

    is($result->merchant_account->status, WebService::Braintree::MerchantAccount::Status::Pending);
    is($result->merchant_account->master_merchant_account->id, 'sandbox_master_merchant_account');
};

subtest 'Accepts ID' => sub {
    my $params = dclone($valid_application_params);
    $params->{id} = generate_id();

    my $result = WebService::Braintree::MerchantAccount->create($params);
    validate_result($result) or return;

    is($result->merchant_account->status, WebService::Braintree::MerchantAccount::Status::Pending);
    is($result->merchant_account->master_merchant_account->id, $params->{master_merchant_account_id});
    is($result->merchant_account->id, $params->{id});
};

subtest 'Handles Unsuccessful Result' => sub {
    my $result = WebService::Braintree::MerchantAccount->create({});
    invalidate_result($result) or return;

    my $expected_error_code = WebService::Braintree::ErrorCodes::MerchantAccount::MasterMerchantAccountIdIsRequired;
    is($result->errors->for('merchant_account')->on('master_merchant_account_id')->[0]->code, $expected_error_code);
};

foreach my $destination (qw(Bank Email MobilePhone)) {
    subtest "Works with FundingDestination::$destination" => sub {
        my $params = dclone($valid_application_params);
        $params->{id} = generate_id();
        $params->{funding}{destination} = WebService::Braintree::MerchantAccount::FundingDestination->$destination;

        my $result = WebService::Braintree::MerchantAccount->create($params);
        validate_result($result) or return;
    };
}

subtest 'Create handles required validation errors' => sub {
    my $params = {
        tos_accepted => 'true',
        master_merchant_account_id => 'sandbox_master_merchant_account',
    };

    my $result = WebService::Braintree::MerchantAccount->create($params);
    invalidate_result($result) or return;

    my @errors = (
        [
            [ merchant_account => individual => 'first_name' ],
            [ Individual => 'FirstNameIsRequired' ],
        ],
        [
            [ merchant_account => individual => 'last_name' ],
            [ Individual => 'LastNameIsRequired' ],
        ],
        [
            [ merchant_account => individual => 'date_of_birth' ],
            [ Individual => 'DateOfBirthIsRequired' ],
        ],
        [
            [ merchant_account => individual => 'email' ],
            [ Individual => 'EmailIsRequired' ],
        ],
        [
            [ merchant_account => individual => address => 'street_address' ],
            [ 'Individual::Address' => 'StreetAddressIsRequired' ],
        ],
        [
            [ merchant_account => individual => address => 'postal_code' ],
            [ 'Individual::Address' => 'PostalCodeIsRequired' ],
        ],
        [
            [ merchant_account => individual => address => 'locality' ],
            [ 'Individual::Address' => 'LocalityIsRequired' ],
        ],
        [
            [ merchant_account => individual => address => 'region' ],
            [ 'Individual::Address' => 'RegionIsRequired' ],
        ],
        [
            [ merchant_account => funding => 'destination' ],
            [ 'Funding' => 'DestinationIsRequired' ],
        ],
    );
    check_error($result, @$_) for @errors;
};

subtest 'Create handles invalid validation errors' => sub {
    my $params = {
        individual => {
            first_name => '<>',
            last_name => '<>',
            email => 'bad',
            phone => '999',
            address => {
                street_address => 'nope',
                postal_code => '1',
                region => 'QQ',
            },
            date_of_birth => 'hah',
            ssn => '12345',
        },
        business => {
            legal_name => '``{}',
            dba_name => '{}``',
            tax_id => 'bad',
            address => {
                street_address => 'nope',
                postal_code => '1',
                region => 'QQ',
            },
        },
        funding => {
            destination => 'MY WALLET',
            routing_number => 'LEATHER',
            account_number => 'BACK POCKET',
            email => 'BILLFOLD',
            mobile_phone => 'TRIFOLD',
        },
        tos_accepted => 'true',
        master_merchant_account_id => 'sandbox_master_merchant_account',
    };

    my $result = WebService::Braintree::MerchantAccount->create($params);
    invalidate_result($result) or return;

    my @errors = (
        [
            [ merchant_account => individual => 'first_name' ],
            [ Individual => 'FirstNameIsInvalid' ],
        ],
        [
            [ merchant_account => individual => 'last_name' ],
            [ Individual => 'LastNameIsInvalid' ],
        ],
        [
            [ merchant_account => individual => 'email' ],
            [ Individual => 'EmailIsInvalid' ],
        ],
        [
            [ merchant_account => individual => 'phone' ],
            [ Individual => 'PhoneIsInvalid' ],
        ],
        [
            [ merchant_account => individual => 'ssn' ],
            [ Individual => 'SsnIsInvalid' ],
        ],
        [
            [ merchant_account => individual => address => 'street_address' ],
            [ 'Individual::Address' => 'StreetAddressIsInvalid' ],
        ],
        [
            [ merchant_account => individual => address => 'postal_code' ],
            [ 'Individual::Address' => 'PostalCodeIsInvalid' ],
        ],
        [
            [ merchant_account => individual => address => 'region' ],
            [ 'Individual::Address' => 'RegionIsInvalid' ],
        ],
        [
            [ merchant_account => business => 'dba_name' ],
            [ Business => 'DbaNameIsInvalid' ],
        ],
        [
            [ merchant_account => business => 'tax_id' ],
            [ Business => 'TaxIdIsInvalid' ],
        ],
        [
            [ merchant_account => business => 'legal_name' ],
            [ Business => 'LegalNameIsInvalid' ],
        ],
        [
            [ merchant_account => business => address => 'street_address' ],
            [ 'Business::Address' => 'StreetAddressIsInvalid' ],
        ],
        [
            [ merchant_account => business => address => 'postal_code' ],
            [ 'Business::Address' => 'PostalCodeIsInvalid' ],
        ],
        [
            [ merchant_account => business => address => 'region' ],
            [ 'Business::Address' => 'RegionIsInvalid' ],
        ],
        [
            [ merchant_account => funding => 'destination' ],
            [ 'Funding' => 'DestinationIsInvalid' ],
        ],
        [
            [ merchant_account => funding => 'routing_number' ],
            [ 'Funding' => 'RoutingNumberIsInvalid' ],
        ],
        [
            [ merchant_account => funding => 'account_number' ],
            [ 'Funding' => 'AccountNumberIsInvalid' ],
        ],
        [
            [ merchant_account => funding => 'email' ],
            [ 'Funding' => 'EmailIsInvalid' ],
        ],
        [
            [ merchant_account => funding => 'mobile_phone' ],
            [ 'Funding' => 'MobilePhoneIsInvalid' ],
        ],
    );
    check_error($result, @$_) for @errors;
};

subtest 'Handles tax id and legal name mutual requirement errors' => sub {
    subtest 'tax_id only' => sub {
        my $result = WebService::Braintree::MerchantAccount->create({
            business => {tax_id => '1234567890'},
            tos_accepted => 'true',
            master_merchant_account_id => 'sandbox_master_merchant_account',
        });
        invalidate_result($result) or return;

        my @errors = (
            [
                [ merchant_account => business => 'legal_name' ],
                [ Business => 'LegalNameIsRequiredWithTaxId' ],
            ],
            [
                [ merchant_account => business => 'tax_id' ],
                [ Business => 'TaxIdMustBeBlank' ],
            ],
        );
        check_error($result, @$_) for @errors;
    };

    subtest 'legal_name only' => sub {
        my $result = WebService::Braintree::MerchantAccount->create({
            business => {legal_name => 'foogurt'},
            tos_accepted => 'true',
            master_merchant_account_id => 'sandbox_master_merchant_account',
        });
        invalidate_result($result) or return;

        my @errors = (
            [
                [ merchant_account => business => 'tax_id' ],
                [ Business => 'TaxIdIsRequiredWithLegalName' ],
            ],
        );
        check_error($result, @$_) for @errors;
    };
};

subtest 'Handles funding destination requirement errors' => sub {
    subtest 'bank requirements' => sub {
        my $result = WebService::Braintree::MerchantAccount->create({
            funding => {destination => WebService::Braintree::MerchantAccount::FundingDestination::Bank},
            tos_accepted => 'true',
            master_merchant_account_id => 'sandbox_master_merchant_account',
        });
        invalidate_result($result) or return;

        my @errors = (
            [
                [ merchant_account => funding => 'account_number' ],
                [ Funding => 'AccountNumberIsRequired' ],
            ],
            [
                [ merchant_account => funding => 'routing_number' ],
                [ Funding => 'RoutingNumberIsRequired' ],
            ],
        );
        check_error($result, @$_) for @errors;
    };

    subtest 'mobilephone requirements' => sub {
        my $result = WebService::Braintree::MerchantAccount->create({
            funding => {destination => WebService::Braintree::MerchantAccount::FundingDestination::MobilePhone},
            tos_accepted => 'true',
            master_merchant_account_id => 'sandbox_master_merchant_account',
        });
        invalidate_result($result) or return;

        my @errors = (
            [
                [ merchant_account => funding => 'mobile_phone' ],
                [ Funding => 'MobilePhoneIsRequired' ],
            ],
        );
        check_error($result, @$_) for @errors;
    };

    subtest 'email requirements' => sub {
        my $result = WebService::Braintree::MerchantAccount->create({
            funding => {destination => WebService::Braintree::MerchantAccount::FundingDestination::Email},
            tos_accepted => 'true',
            master_merchant_account_id => 'sandbox_master_merchant_account',
        });
        invalidate_result($result) or return;

        my @errors = (
            [
                [ merchant_account => funding => 'email' ],
                [ Funding => 'EmailIsRequired' ],
            ],
        );
        check_error($result, @$_) for @errors;
    };
};

subtest 'Can find a merchant account by ID' => sub {
    my $params = dclone($valid_application_params);
    $params->{id} = generate_id();

    my $result = WebService::Braintree::MerchantAccount->create($params);
    validate_result($result) or return;

    my $merchant_account = WebService::Braintree::MerchantAccount->find($params->{id});
    isa_ok($merchant_account, 'WebService::Braintree::_::MerchantAccount');
};

subtest 'Calling find with a nonexistant ID returns a NotFoundError' => sub {
    should_throw('NotFoundError', sub {
        WebService::Braintree::MerchantAccount->find('asdlkfj');
    });
};

done_testing();

sub generate_id {
    return 'sub_merchant_account_id' . int(rand(1000000));
}

# While this function may seem a little overly complicated, the alternative is
# a whole bunch of lines that look like this:
#
# is($result->errors->for('merchant_account')->for('individual')->on('date_of_birth')->[0]->code, WebService::Braintree::ErrorCodes::MerchantAccount::Individual::DateOfBirthIsRequired);
#
# It's a lot to read this way.
sub check_error {
    my ($result, $error_path, $validation) = @_;

    my $on = pop @$error_path;
    my $error = $result->errors;
    $error = $error->for($_) foreach @$error_path;
    $error = $error->on($on)->[0]->code;

    my ($class, $const) = @$validation;
    my $expected = "WebService::Braintree::ErrorCodes::MerchantAccount::$class"->$const;

    is($error, $expected, "${class}->${const}");
}
