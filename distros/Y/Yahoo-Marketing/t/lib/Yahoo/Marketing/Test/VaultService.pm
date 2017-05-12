package Yahoo::Marketing::Test::VaultService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/ Yahoo::Marketing::Test::PostTest /;
use Test::More;

use Yahoo::Marketing::User;
use Yahoo::Marketing::Account;
use Yahoo::Marketing::Address;
use Yahoo::Marketing::Company;
use Yahoo::Marketing::BillingUser;
use Yahoo::Marketing::VaultService;
use Yahoo::Marketing::MasterAccount;
use Yahoo::Marketing::CreditCardInfo;

sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}

sub test_add_new_customer : Test(8) {
    my ( $self ) = @_;


    return 'not running addNewCustomer test to prevent creating a new master account for each test run';

    my $ysm_ws = Yahoo::Marketing::VaultService->new->parse_config( section => $self->section );

    my $username = $self->_make_username;

    my $user = Yahoo::Marketing::User->new
                                     ->email( 'test@yahoo-inc.com' )
                                     ->firstName( 'test' )
                                     ->lastName( 'user' )
                                     ->locale( 'en_US' )
                                     ->mobilePhone( '111-111-1111' )
                                     ->timezone( 'America/Los_Angeles' )
                                     ->workPhone( '111-111-1111' )
    ;
    my $billing_user = Yahoo::Marketing::BillingUser->new
                                                    ->email( 'test@yahoo-inc.com' )
                                                    ->firstName( 'test' )
                                                    ->lastName( 'user' )
                                                    ->phone( '111-111-1111' )
    ;
    my $address = Yahoo::Marketing::Address->new
                                           ->address1('123 Sunshine Street')
                                           ->city('Sunnyvale')
                                           ->country('US')
                                           ->postalCode( '94089' )
                                           ->state( 'CA' )
    ;
    my $account_aggregate = $ysm_ws->addNewCustomer( company            => Yahoo::Marketing::Company->new
                                                                                                 ->companyName( 'new test company' )
                                                  ,
                                                  masterAccount      => Yahoo::Marketing::MasterAccount->new
                                                                                                       ->currencyID( 'USD' )   
                                                                                                       ->name( 'new master account test' )
                                                                                                       ->timezone( 'America/Los_Angeles' )
                                                                                                       ->trackingON( 'false' )
                                                                                                       ->marketID( 'US' )
                                                  ,
                                                  account            => Yahoo::Marketing::Account->new
                                                                                                 ->marketID( 'US' )
                                                                                                 ->name( 'new account test' )
                                                                                                 ->displayURL( 'http://yahoo.com' )
                                                  ,
                                                  username           => $username,
                                                  userInfo           => $user,
                                                  address            => $address,
                                                  billingUserInfo    => $billing_user,
                                                  billingAddress     => $address,
                                                  cc                 => Yahoo::Marketing::CreditCardInfo->new
                                                                                                        ->cardNumber( '4111111111111111' )
                                                                                                        ->cardType( 'VISA' )
                                                                                                        ->expMonth( 2 )
                                                                                                        ->expYear( 2010 )
                                                                                                        ->securityCode( 123 )
                                                  ,
                                                  depositAmount      => 100,
                                                  promoCode          => '',   # can be null, must be present
                                  )
    ;

    my $master_account = $account_aggregate->masterAccount;
    ok( $master_account );
    like( $master_account->ID, qr/^\d+$/, 'ID is numeric' );
    is( $master_account->currencyID,  'USD', 'Currency ID is correct' );
    is( $master_account->taggingON, 'false', 'Tagging is not on' );
    is( $master_account->timezone,  'America/Los_Angeles', 'Timezone is correct' );
    is( $master_account->name,  'new master account test', 'Name is correct' );
    is( $master_account->signupStatus, 'Success', 'signupStatus is Success' );
    is( $master_account->trackingON,  'false', 'Tracking is not on' );
}




sub test_get_and_set_active_credit_card : Test(1) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::VaultService->new->parse_config( section => $self->section );

    my @payment_methods = $ysm_ws->getPaymentMethods;

    ok( @payment_methods );

    return "no payment methods, skipping setActiveCreditCard tests"
        if @payment_methods < 1;
}




sub _make_username {
    my $time = time();
    return 'tu'.substr( $time, length($time) - 8, length( $time ) );
}




1;


__END__

* addCreditCard  (changed in Version 3.0.0)
* addNewCustomer  (changed in Version 3.0.0)
* getPaymentMethods  (changed in Version 3.0.0)
* updateCreditCard  (changed in Version 3.0.0)


