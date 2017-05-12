package Yahoo::Marketing::Test::Account;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::Account;

sub test_can_create_account_and_set_all_fields : Test(24) {

    my $account = Yahoo::Marketing::Account->new
                                           ->ID( 'id' )
                                           ->advancedMatchON( 'advanced match on' )
                                           ->businessItem( 'business item' )
                                           ->businessTypeCode( 'business type code' )
                                           ->contentMatchON( 'content match on' )
                                           ->displayURL( 'display url' )
                                           ->fiscalCode( 'fiscal code' )
                                           ->hasFiscalCode( 'has fiscal code' )
                                           ->hasNifCif( 'has nif cif' )
                                           ->hasVatRegistrationNumber( 'has vat registration number' )
                                           ->marketID( 'market id' )
                                           ->masterAccountID( 'master account id' )
                                           ->name( 'name' )
                                           ->nameFurigana( 'name furigana' )
                                           ->nifCif( 'nif cif' )
                                           ->personalID( 'personal id' )
                                           ->presidentName( 'president name' )
                                           ->sitePassword( 'site password' )
                                           ->siteUserName( 'site user name' )
                                           ->sponsoredSearchON( 'sponsored search on' )
                                           ->vatRegistrationCountry( 'vat registration country' )
                                           ->vatRegistrationNumber( 'vat registration number' )
                                           ->websiteURL( 'website url' )
                   ;

    ok( $account );

    is( $account->ID, 'id', 'can get id' );
    is( $account->advancedMatchON, 'advanced match on', 'can get advanced match on' );
    is( $account->businessItem, 'business item', 'can get business item' );
    is( $account->businessTypeCode, 'business type code', 'can get business type code' );
    is( $account->contentMatchON, 'content match on', 'can get content match on' );
    is( $account->displayURL, 'display url', 'can get display url' );
    is( $account->fiscalCode, 'fiscal code', 'can get fiscal code' );
    is( $account->hasFiscalCode, 'has fiscal code', 'can get has fiscal code' );
    is( $account->hasNifCif, 'has nif cif', 'can get has nif cif' );
    is( $account->hasVatRegistrationNumber, 'has vat registration number', 'can get has vat registration number' );
    is( $account->marketID, 'market id', 'can get market id' );
    is( $account->masterAccountID, 'master account id', 'can get master account id' );
    is( $account->name, 'name', 'can get name' );
    is( $account->nameFurigana, 'name furigana', 'can get name furigana' );
    is( $account->nifCif, 'nif cif', 'can get nif cif' );
    is( $account->personalID, 'personal id', 'can get personal id' );
    is( $account->presidentName, 'president name', 'can get president name' );
    is( $account->sitePassword, 'site password', 'can get site password' );
    is( $account->siteUserName, 'site user name', 'can get site user name' );
    is( $account->sponsoredSearchON, 'sponsored search on', 'can get sponsored search on' );
    is( $account->vatRegistrationCountry, 'vat registration country', 'can get vat registration country' );
    is( $account->vatRegistrationNumber, 'vat registration number', 'can get vat registration number' );
    is( $account->websiteURL, 'website url', 'can get website url' );

};



1;

