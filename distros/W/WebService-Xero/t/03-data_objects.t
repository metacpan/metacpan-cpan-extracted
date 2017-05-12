

#!perl -T
use 5.006;
use strict;
use warnings;
use Data::Dumper;
use Test::More 0.88;
use Crypt::OpenSSL::RSA;
use JSON::PP; ## not sure if really need this
use URI::Encode qw(uri_encode uri_decode );

#plan tests => 17; # instead of noplan using  done_testing;

#use Config::Tiny;



BEGIN {
    use_ok( 'WebService::Xero::Organisation' ) || print "Bail out!\n";

    ok( my $org_obj = WebService::Xero::Organisation->new(
                 'FinancialYearEndMonth' => 6,
                 'CountryCode' => 'AU',
                 'debug' => undef,
                 'DefaultPurchasesTax' => 'Tax Inclusive',
                 'FinancialYearEndDay' => 30,
                 'EndOfYearLockDate' => '',
                 'APIKey' => 'LIKEASDSADSDSFAPQSSSDFS',
                 'Version' => 'AU',
                 'LineOfBusiness' => 'IT Consulting & Services',
                 'LegalName' => 'Combined Computer Professionals Pty Ltd',
                 'PaysTax' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
                 'CreatedDateUTC' => '/Date(1435803651000)/',
                 'OrganisationStatus' => 'ACTIVE',
                 'ShortCode' => '!84jzb',
                 'PaymentTerms' => {},
                 'IsDemoCompany' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
                 'PeriodLockDate' => '',
                 'Name' => 'Combined Computer Professionals Pty Ltd',
                 'SalesTaxPeriod' => 'QUARTERLY1',
                 'TaxNumber' => '',
                 'OrganisationType' => 'COMPANY',
                 'RegistrationNumber' => 'ABNORACNORSIMILAR',
                 'Addresses' => [
                                  {
                                    'Country' => '',
                                    'PostalCode' => '4216',
                                    'AddressType' => 'STREET',
                                    'AddressLine1' => '465 Pine Ridge Rd',
                                    'Region' => 'Queensland',
                                    'City' => 'Runaway Bay',
                                    'AttentionTo' => ''
                                  },
                                  {
                                    'AttentionTo' => 'Peter and Heather Scott',
                                    'City' => 'Runaway Bay',
                                    'AddressLine1' => 'PO Box 1331',
                                    'Region' => 'QLD',
                                    'Country' => 'Australia',
                                    'PostalCode' => '4216',
                                    'AddressType' => 'POBOX'
                                  }
                                ],
                 'Phones' => [
                               {
                                 'PhoneType' => 'OFFICE',
                                 'PhoneCountryCode' => '61',
                                 'PhoneNumber' => '410 999 999'
                               }
                             ],
                 'DefaultSalesTax' => 'Tax Inclusive',
                 'OrganisationEntityType' => 'COMPANY',
                 'BaseCurrency' => 'AUD',
                 'SalesTaxBasis' => 'CASH',
                 'ExternalLinks' => [
                                      {
                                        'LinkType' => 'Website',
                                        'Url' => 'http://www.computerpros.com.au'
                                      }
                                    ],
                 'Timezone' => 'EAUSTRALIASTANDARDTIME'
               ), 'WebService::Xero::Organisation->new()');
    is( ref($org_obj), 'WebService::Xero::Organisation', 'created WebService::Xero::Organisation object is the right type' );
    like( $org_obj->as_text(), qr/Organisation/, 'WebService::Xero::Organisation->as_text()' );



    use_ok( 'WebService::Xero::Item' ) || print "Bail out!\n";
    ok( my $item_obj = WebService::Xero::Item->new(), 'WebService::Xero::Item->new()');
    is( ref($item_obj), 'WebService::Xero::Item', 'created WebService::Xero::Organisation object is the right type' );
    like( $item_obj->as_text(), qr/Item:/, 'WebService::Xero::Item->as_text()' );
    ok( $item_obj->new_from_api_data(), 'WebService::Xero::Item->new_from_api_data()' );


    use_ok( 'WebService::Xero::Invoice' ) || print "Bail out!\n";
    ok( my $inv_obj = WebService::Xero::Invoice->new(), 'WebService::Xero::Invoice->new()');
    is( ref($inv_obj), 'WebService::Xero::Invoice', 'created WebService::Invoice::Organisation object is the right type' );
    like( $inv_obj->as_text(), qr/Invoice:/, 'WebService::Xero::Invoice->as_text()' );
    ok( $inv_obj->new_from_api_data(), 'WebService::Xero::Invoice->new_from_api_data()');
    ok( $inv_obj->new_from_api_data(), 'WebService::Xero::Invoice->new_from_api_data()' );



    use_ok( 'WebService::Xero::Contact' ) || print "Bail out!\n";
    ok( my $contact_obj = WebService::Xero::Contact->new(), 'WebService::Xero::Contact->new()');
    is( ref($contact_obj), 'WebService::Xero::Contact', 'created WebService::Xero::Contact object is the right type' );
    like( $contact_obj->as_text(), qr/Contact/, 'WebService::Xero::Contact->as_text()' );

}

done_testing();