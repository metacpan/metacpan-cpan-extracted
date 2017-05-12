package Yahoo::Marketing::Test::CompanyService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/ Yahoo::Marketing::Test::PostTest /;
use Test::More;
use Module::Build;

use Yahoo::Marketing::CompanyService;

sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}

sub test_get_company : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::CompanyService->new->parse_config( section => $self->section );

    my $company = $ysm_ws->getCompany;

    ok( $company );
    like( $company->companyID, qr/^\d+$/, "company ID is all digits" );
}



1;
