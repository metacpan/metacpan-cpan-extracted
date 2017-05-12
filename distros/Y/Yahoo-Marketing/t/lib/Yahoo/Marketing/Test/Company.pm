package Yahoo::Marketing::Test::Company;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::Company;

sub test_can_create_company_and_set_all_fields : Test(5) {

    my $company = Yahoo::Marketing::Company->new
                                           ->companyID( 'company id' )
                                           ->companyName( 'company name' )
                                           ->companyNameFurigana( 'company name furigana' )
                                           ->createTimestamp( '2008-01-06T17:51:55' )
                   ;

    ok( $company );

    is( $company->companyID, 'company id', 'can get company id' );
    is( $company->companyName, 'company name', 'can get company name' );
    is( $company->companyNameFurigana, 'company name furigana', 'can get company name furigana' );
    is( $company->createTimestamp, '2008-01-06T17:51:55', 'can get 2008-01-06T17:51:55' );

};



1;

