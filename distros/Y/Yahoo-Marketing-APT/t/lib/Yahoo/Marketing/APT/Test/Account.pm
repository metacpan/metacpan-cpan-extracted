package Yahoo::Marketing::APT::Test::Account;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Account;

sub test_can_create_account_and_set_all_fields : Test(19) {

    my $account = Yahoo::Marketing::APT::Account->new
                                           ->ID( 'id' )
                                           ->accountTypes( 'account types' )
                                           ->address( 'address' )
                                           ->agencyName( 'agency name' )
                                           ->category( 'category' )
                                           ->companyID( 'company id' )
                                           ->companyName( 'company name' )
                                           ->companyNameFurigana( 'company name furigana' )
                                           ->defaultCurrency( 'default currency' )
                                           ->externalAccountID( 'external account id' )
                                           ->language( 'language' )
                                           ->location( 'location' )
                                           ->managedAccount( 'managed account' )
                                           ->managedAgencyBillingEnabled( 'managed agency billing enabled' )
                                           ->managingAccountID( 'managing account id' )
                                           ->status( 'status' )
                                           ->timezone( 'timezone' )
                                           ->yahooOwnedAndOperatedFlag( 'yahoo owned and operated flag' )
                   ;

    ok( $account );

    is( $account->ID, 'id', 'can get id' );
    is( $account->accountTypes, 'account types', 'can get account types' );
    is( $account->address, 'address', 'can get address' );
    is( $account->agencyName, 'agency name', 'can get agency name' );
    is( $account->category, 'category', 'can get category' );
    is( $account->companyID, 'company id', 'can get company id' );
    is( $account->companyName, 'company name', 'can get company name' );
    is( $account->companyNameFurigana, 'company name furigana', 'can get company name furigana' );
    is( $account->defaultCurrency, 'default currency', 'can get default currency' );
    is( $account->externalAccountID, 'external account id', 'can get external account id' );
    is( $account->language, 'language', 'can get language' );
    is( $account->location, 'location', 'can get location' );
    is( $account->managedAccount, 'managed account', 'can get managed account' );
    is( $account->managedAgencyBillingEnabled, 'managed agency billing enabled', 'can get managed agency billing enabled' );
    is( $account->managingAccountID, 'managing account id', 'can get managing account id' );
    is( $account->status, 'status', 'can get status' );
    is( $account->timezone, 'timezone', 'can get timezone' );
    is( $account->yahooOwnedAndOperatedFlag, 'yahoo owned and operated flag', 'can get yahoo owned and operated flag' );

};



1;

