package Yahoo::Marketing::APT::Test::AccountDescriptor;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::AccountDescriptor;

sub test_can_create_account_descriptor_and_set_all_fields : Test(4) {

    my $account_descriptor = Yahoo::Marketing::APT::AccountDescriptor->new
                                                                ->accountID( 'account id' )
                                                                ->accountType( 'account type' )
                                                                ->companyName( 'company name' )
                   ;

    ok( $account_descriptor );

    is( $account_descriptor->accountID, 'account id', 'can get account id' );
    is( $account_descriptor->accountType, 'account type', 'can get account type' );
    is( $account_descriptor->companyName, 'company name', 'can get company name' );

};



1;

