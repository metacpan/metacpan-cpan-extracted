package Yahoo::Marketing::APT::Test::AccountService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::AccountService;
use Yahoo::Marketing::APT::Account;

use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];


sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}

# since there is no deleteAccount function, we can't test addManagedAdvertiser(s), addManagedPublisher(s) and related APIs.

sub test_can_add_and_get_currencies : Test(4) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::AccountService->new->parse_config( section => $self->section );

    my $response = $ysm_ws->addCurrencies( currencies => ['USD'] );
    ok($response);
    is($response->operationSucceeded, 'true');

    my @currencies = $ysm_ws->getCurrencies( accountID => $ysm_ws->account );
    ok( @currencies );
    is( $currencies[0], 'USD' );
}

sub test_can_set_credit_limit : Test(1) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::AccountService->new->parse_config( section => $self->section );

    my $response = $ysm_ws->setCreditLimit(
        accountID   => $ysm_ws->account,
        creditLimit => 200,
        currency    => 'USD',
    );
    ok($response);
}

sub test_can_get_account : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::AccountService->new->parse_config( section => $self->section );

    my $account = $ysm_ws->getAccount( accountID => $ysm_ws->account );
    ok( $account, 'can call getAccount' );
    is( $account->ID, $ysm_ws->account, 'account id matches' );
}

sub test_can_get_account_status : Test(2) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::AccountService->new->parse_config( section => $self->section );

    my $status = $ysm_ws->getAccountStatus( accountID => $ysm_ws->account );
    ok( $status, 'can call getAccountStatus' );
    like( $status, qr/[Inactive|Active]/, 'status matches' );
}



1;
