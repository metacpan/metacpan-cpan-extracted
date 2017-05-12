package Yahoo::Marketing::Test::MasterAccountService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/ Yahoo::Marketing::Test::PostTest /;
use Test::More;

use Yahoo::Marketing::User;
use Yahoo::Marketing::Address;
use Yahoo::Marketing::Account;
use Yahoo::Marketing::BillingUser;
use Yahoo::Marketing::MasterAccount;
use Yahoo::Marketing::CreditCardInfo;
use Yahoo::Marketing::CompanyService;
use Yahoo::Marketing::MasterAccountService;

sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}


sub test_get_master_account : Test(7) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::MasterAccountService->new->parse_config( section => $self->section );

    my $master_account = $ysm_ws->getMasterAccount( masterAccountID => $ysm_ws->master_account );

    ok( $master_account );
    is( $master_account->ID, $ysm_ws->master_account, 'master account id is right' );
    ok( $master_account->currencyID );
    ok( $master_account->timezone );
    ok( $master_account->name );
    is( $master_account->signupStatus, 'Success', 'signupStatus is Success' );
    ok( $master_account->trackingON =~ /^(false|true)$/ );
}

sub test_get_master_accounts_by_company_id : Test(4) {
    my $self = shift;

    my $company_ws = Yahoo::Marketing::CompanyService->new->parse_config( section => $self->section );

    my $company = $company_ws->getCompany;

    my $ysm_ws = Yahoo::Marketing::MasterAccountService->new->parse_config( section => $self->section );

    my @master_accounts = $ysm_ws->getMasterAccountsByCompanyID( companyID => $company->companyID );

    ok( @master_accounts );
    ok( @master_accounts >= 1, 'at least one master account' );
    ok( ( scalar grep { $_->companyID == $company->companyID } @master_accounts ) == @master_accounts, 'all master accounts have same, correct company ID' );
    ok( ( grep { $_->ID == $ysm_ws->master_account } @master_accounts ) == 1, 'only 1 master account matching the one we started with' );
}

sub test_get_master_account_status : Test(1) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::MasterAccountService->new->parse_config( section => $self->section );

    my $master_account_status = $ysm_ws->getMasterAccountStatus( masterAccountID => $ysm_ws->master_account );
    ok( $master_account_status =~ /^(Active|Inactive)$/, 'master account status is right' );
}

sub test_update_master_account : Test(4) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::MasterAccountService->new->parse_config( section => $self->section );

    my $master_account = $ysm_ws->getMasterAccount( masterAccountID => $ysm_ws->master_account );
    my $old_name = $master_account->name;
    my $old_tracking_on = $master_account->trackingON;

    $ysm_ws->updateMasterAccount(
        masterAccount => $master_account->trackingON( $old_tracking_on eq 'false' ? 'true' : 'false' ),
    );

    my $fetched_master_account = $ysm_ws->getMasterAccount( masterAccountID => $ysm_ws->master_account );

    ok( $fetched_master_account );
    is( $fetched_master_account->trackingON, $old_tracking_on eq 'false' ? 'true' : 'false', 'trackingON is right' );

    $ysm_ws->updateMasterAccount(
        masterAccount => $master_account->trackingON( $old_tracking_on ),
    );

    $fetched_master_account = $ysm_ws->getMasterAccount( masterAccountID => $ysm_ws->master_account );

    ok( $fetched_master_account );
    is( $fetched_master_account->trackingON, $old_tracking_on, 'trackingON changed back' );

}



1;


__END__

    * addNewCustomer
    * getMasterAccount
    * getMasterAccountStatus
    * updateMasterAccount


