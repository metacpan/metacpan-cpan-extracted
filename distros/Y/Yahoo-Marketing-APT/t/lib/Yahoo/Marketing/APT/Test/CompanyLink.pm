package Yahoo::Marketing::APT::Test::CompanyLink;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::CompanyLink;

sub test_can_create_company_link_and_set_all_fields : Test(9) {

    my $company_link = Yahoo::Marketing::APT::CompanyLink->new
                                                    ->buyerLinkID( 'buyer link id' )
                                                    ->buyerLinkStatus( 'buyer link status' )
                                                    ->companyAccountID( 'company account id' )
                                                    ->companyName( 'company name' )
                                                    ->companyType( 'company type' )
                                                    ->companyUrl( 'company url' )
                                                    ->sellerLinkID( 'seller link id' )
                                                    ->sellerLinkStatus( 'seller link status' )
                   ;

    ok( $company_link );

    is( $company_link->buyerLinkID, 'buyer link id', 'can get buyer link id' );
    is( $company_link->buyerLinkStatus, 'buyer link status', 'can get buyer link status' );
    is( $company_link->companyAccountID, 'company account id', 'can get company account id' );
    is( $company_link->companyName, 'company name', 'can get company name' );
    is( $company_link->companyType, 'company type', 'can get company type' );
    is( $company_link->companyUrl, 'company url', 'can get company url' );
    is( $company_link->sellerLinkID, 'seller link id', 'can get seller link id' );
    is( $company_link->sellerLinkStatus, 'seller link status', 'can get seller link status' );

};



1;

