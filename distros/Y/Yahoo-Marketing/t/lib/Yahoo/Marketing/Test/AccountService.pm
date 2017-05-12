package Yahoo::Marketing::Test::AccountService;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/ Yahoo::Marketing::Test::PostTest /;
use Test::More;
use Module::Build;

use Yahoo::Marketing::AccountService;
use Yahoo::Marketing::VaultService;
use Yahoo::Marketing::User;
use Yahoo::Marketing::Address;
use Yahoo::Marketing::BillingUser;
use Yahoo::Marketing::CreditCardInfo;

#use SOAP::Lite +trace => [qw/ debug method fault /];



sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}


sub test_get_account_balance : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::AccountService->new->parse_config( section => $self->section );

    my $balance = $ysm_ws->getAccountBalance(
        accountID => $ysm_ws->account,
    );
    ok( $balance );
    like( $balance, qr/^-?\d+\.\d+$/, 'looks like a float number' );
}

sub test_add_money_and_get_account_balance : Test(5) {
    my $self = shift;

    return 'skipping add money and get account balance test, less danger of playing with real money';

    my $ysm_ws = Yahoo::Marketing::AccountService->new->parse_config( section => $self->section );

    my $balance = $ysm_ws->getAccountBalance(
        accountID => $ysm_ws->account,
    );
    ok( $balance );
    like( $balance, qr/^-?\d+\.\d+$/, 'looks like a float number' );

    my $payment_method_id;
    ok( $payment_method_id = $ysm_ws->getActiveCreditCard(
            accountID => $ysm_ws->account,
        )
    );

    return "no active payment method, skipping addMoney tests"
        if $payment_method_id == -1;

    my $add_amount = 108.01;

    $ysm_ws->addMoney(
        accountID => $ysm_ws->account,
        amount    => $add_amount,
    );

    my $new_balance = $ysm_ws->getAccountBalance(
        accountID => $ysm_ws->account,
    );
    ok( $new_balance );
    is( sprintf('%.2f', $new_balance), sprintf('%.2f', $balance + $add_amount), 'amount is right' );
}

sub test_get_and_set_charge_amount : Test(3) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::AccountService->new->parse_config( section => $self->section );

    my $charge_amount = $ysm_ws->getChargeAmount( accountID => $ysm_ws->account );
    ok( defined( $charge_amount ) );

    return "charge amount is 0, skipping setChargeAmount tests"
        if $charge_amount == 0;
    
    $ysm_ws->setChargeAmount(
        accountID    => $ysm_ws->account,
        chargeAmount => '300',
    );

    $charge_amount = $ysm_ws->getChargeAmount( accountID => $ysm_ws->account );
    is( $charge_amount, 300 );

    # test again
    $ysm_ws->setChargeAmount(
        accountID    => $ysm_ws->account,
        chargeAmount => 101,
    );
    $charge_amount = $ysm_ws->getChargeAmount( accountID => $ysm_ws->account );
    is( $charge_amount, 101 );
}

sub test_get_and_set_active_credit_card : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::AccountService->new->parse_config( section => $self->section );

    my $active_payment_method_id = $ysm_ws->getActiveCreditCard( accountID => $ysm_ws->account );
    ok( $active_payment_method_id );

    my $vault_service = Yahoo::Marketing::VaultService->new->parse_config( section => $self->section );

    my @payment_methods = $vault_service->getPaymentMethods;

    return "no payment methods, skipping setActiveCreditCard tests"
        if @payment_methods < 1;

    $ysm_ws->setActiveCreditCard(
        accountID       => $ysm_ws->account,
        paymentMethodID => $payment_methods[0]->ID,
    );
    is( $ysm_ws->getActiveCreditCard( accountID => $ysm_ws->account ), $payment_methods[0]->ID, 'payment method id is right' );

}



sub test_set_get_and_delete_continent_block_list : Test(9) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::AccountService->new->parse_config( section => $self->section );

    my @continents;

    ok( $ysm_ws->setContinentBlockListForAccount(
        accountID  => $ysm_ws->account,
        continents => [ 'Africa' ],
    ) );

    @continents = $ysm_ws->getContinentBlockListForAccount(
        accountID => $ysm_ws->account,
    );

    ok( @continents );
    is( $continents[0], 'Africa', 'continent block list contains Africa' );

    ok( $ysm_ws->setContinentBlockListForAccount(
        accountID  => $ysm_ws->account,
        continents => [ qw(Europe Asia Australia) ],
    ) );

    @continents = $ysm_ws->getContinentBlockListForAccount(
        accountID => $ysm_ws->account,
    );

    ok( @continents );
    ok( grep { $_ eq 'Europe'    } @continents, 'continent block list includes Europe'     );
    ok( grep { $_ eq 'Asia'      } @continents, 'continent block list includes Asia'       );
    ok( grep { $_ eq 'Australia' } @continents, 'continent block list includes Austrailia' );

    $ysm_ws->deleteContinentBlockListFromAccount(
        accountID => $ysm_ws->account,
    );

    local $TODO = 'deleteContinentBlockListFromAccount not yet instantaneous?';

    eval {
        @continents = $ysm_ws->getContinentBlockListForAccount(
            accountID => $ysm_ws->account,
        );
    };

    ok( $@ =~ /does not exist/ , 'Continent block list was cleared');
}


sub test_get_account : Test(3) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::AccountService->new->parse_config( section => $self->section );

    my $account = $ysm_ws->getAccount( accountID => $ysm_ws->account );

    ok( $account );
    is( $account->ID, $ysm_ws->account, 'accountID is right' );
    is( $account->marketID, 'US', 'marketID is right' );
}

sub test_get_accounts : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::AccountService->new->parse_config( section => $self->section );

    my @accounts = $ysm_ws->getAccounts;

    ok( @accounts );
    my $found = 0;
    foreach my $account ( @accounts ) {
        $found = 1 if $account->ID eq $ysm_ws->account;
    }
    is( $found, 1, 'found default account' );
}

sub test_get_account_status : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::AccountService->new->parse_config( section => $self->section );

    my $account_status = $ysm_ws->getAccountStatus( accountID => $ysm_ws->account );

    ok( $account_status );
    like( $account_status->accountStatus, qr/^Active|Inactive$/, 'account status seems right' );
}

sub test_update_account : Test(7) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::AccountService->new->parse_config( section => $self->section );

    my $account = $ysm_ws->getAccount( accountID => $ysm_ws->account );
    ok( $account );
    my $market_id = $account->marketID;
    my $name = $account->name;
    my $display_url = $account->displayURL;

    $ysm_ws->updateAccount(
        account => $account->marketID( 'US' )
                           ->name( 'update account test name' )
                           ->displayURL( 'http://searchmarketing.yahoo.com' ),
        updateAll => 'false',
    );
    $account = $ysm_ws->getAccount( accountID => $ysm_ws->account );
    is( $account->marketID, 'US', 'marketID is right' );
    is( $account->name, 'update account test name', 'name is right' );
    is( $account->displayURL, 'http://searchmarketing.yahoo.com', 'displayURL is right' );

    $ysm_ws->updateAccount(
        account => $account->marketID( $market_id )
                           ->name( $name )
                           ->displayURL( $display_url ),
        updateAll => 'false',
    );
    $account = $ysm_ws->getAccount( accountID => $ysm_ws->account );
    is( $account->marketID, $market_id, 'marketID is right' );
    is( $account->name, $name, 'name is right' );
    is( $account->displayURL, $display_url, 'displayURL is right' );
}


sub test_update_account_status : Test(3) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::AccountService->new->parse_config( section => $self->section );

    my $account_status = $ysm_ws->getAccountStatus( accountID => $ysm_ws->account );
    ok( $account_status );
    my $new_status = $account_status->accountStatus eq 'Active' ? 'Inactive' : 'Active';

    $ysm_ws->updateStatusForAccount(
        accountID     => $ysm_ws->account,
        accountStatus => $new_status,
    );
    is( $ysm_ws->getAccountStatus( accountID => $ysm_ws->account )->accountStatus, $new_status, 'new status is right' );
    $ysm_ws->updateStatusForAccount(
        accountID     => $ysm_ws->account,
        accountStatus => $account_status->accountStatus,
    );
    is( $ysm_ws->getAccountStatus( accountID => $ysm_ws->account )->accountStatus, $account_status->accountStatus, 'change back to old status' );
}

sub test_set_get_delete_blocked_domain_list : Test(8) {
    my ( $self ) = @_;

    my $ysm_ws = Yahoo::Marketing::AccountService->new->parse_config( section => $self->section );

    ok( $ysm_ws->deleteBlockedDomainListForAccount( accountID => $ysm_ws->account ) );

    ok( not $ysm_ws->getBlockedDomainListForAccount( accountID => $ysm_ws->account ) );

    ok( $ysm_ws->setBlockedDomainListForAccount( accountID => $ysm_ws->account, blockedDomainList => [ 'microsoft.com', 'perl.org' ] ) );

    my @blocked_domains = $ysm_ws->getBlockedDomainListForAccount( accountID => $ysm_ws->account );

    is( scalar @blocked_domains, 2 );

    ok( grep { /^microsoft\.com$/ } @blocked_domains );
    ok( grep { /^perl\.org$/  } @blocked_domains );

    ok( $ysm_ws->deleteBlockedDomainListForAccount( accountID => $ysm_ws->account ) );

    ok( not $ysm_ws->getBlockedDomainListForAccount( accountID => $ysm_ws->account ) );
}



1;


# setBlockedDomainListForAccount
# getBlockedDomainListForAccount
# deleteBlockedDomainListForAccount

