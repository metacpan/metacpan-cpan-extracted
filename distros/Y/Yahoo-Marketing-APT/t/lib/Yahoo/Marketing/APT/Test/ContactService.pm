package Yahoo::Marketing::APT::Test::ContactService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::ContactService;
use Yahoo::Marketing::APT::Contact;
use Data::Dumper;

# use SOAP::Lite +trace => [qw/ debug method fault /];


sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}

sub section {
    my ( $self ) = @_;
    return $self->SUPER::section().'_managed_publisher';
}

sub startup_test_contact_service : Test(startup) {
    my ( $self ) = @_;

    $self->common_test_data( 'test_contact', $self->create_contact ) unless defined $self->common_test_data( 'test_contact' );
}


sub test_operate_contact : Test(12) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::ContactService->new->parse_config( section => $self->section );

    # test getContactCountByAccountID
    my $count = $ysm_ws->getContactCountByAccountID();
    ok($count);

    # test getContact
    my $contact = $ysm_ws->getContact( contactID => $self->common_test_data( 'test_contact' )->ID );
    ok( $contact);
    is( $contact->ID, $self->common_test_data( 'test_contact' )->ID );

    # test updateContact
    my $mi = $contact->middleInitial;
    $mi = $mi eq 'Y' ? 'X' : 'Y';
    $contact->middleInitial( $mi );
    my $response = $ysm_ws->updateContact( contact => $contact );
    ok($response);
    is( $response->operationSucceeded, 'true' );
    is( $response->contact->middleInitial, $mi );

    # test disableContact
    $response = $ysm_ws->disableContact( contactID => $contact->ID );
    ok( $response );
    is( $response->operationSucceeded, 'true' );

    # test enableContact
    $response = $ysm_ws->enableContact( contactID => $contact->ID );
    ok( $response );
    is( $response->operationSucceeded, 'true' );

    # test testUsername
    my $is_good = $ysm_ws->testUsername( username => 'yahoouser' );
    ok( $is_good );
    like( $is_good, qr/true|false/ );
}


1;
