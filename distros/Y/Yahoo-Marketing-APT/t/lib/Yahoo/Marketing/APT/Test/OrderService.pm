package Yahoo::Marketing::APT::Test::OrderService;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997)

use strict; use warnings;

use base qw/ Yahoo::Marketing::APT::Test::PostTest /;
use Test::More;
use utf8;

use Yahoo::Marketing::APT::OrderService;
use DateTime::Format::W3CDTF;
use Yahoo::Marketing::APT::Order;

use Data::Dumper;

 use SOAP::Lite +trace => [qw/ debug method fault /];


sub SKIP_CLASS {
    my $self = shift;
    # 'not running post tests' is a true value
    return 'not running post tests' unless $self->run_post_tests;
    return;
}

sub section {
    my ( $self ) = @_;
    return $self->SUPER::section().'_managed_advertiser';
}


sub test_order_service : Test(4) {
    my $self = shift;

    my $ysm_ws = Yahoo::Marketing::APT::OrderService->new->parse_config( section => $self->section );

    my $formatter = DateTime::Format::W3CDTF->new;
    my $start_datetime = DateTime->now;
    $start_datetime->set_time_zone( 'America/Chicago' );
    $start_datetime->add( days => 2 );

    my $end_datetime = DateTime->now;
    $end_datetime->set_time_zone( 'America/Chicago' );
    $end_datetime->add( days => 12 );

    # test addOrder
    my $order = Yahoo::Marketing::APT::Order->new
                                            ->endDate( $end_datetime )
                                            ->isInternal( 'true' )
                                            ->name( 'test order' )
                                            ->startDate( $start_datetime )
                                                ;
    my $response = $ysm_ws->addOrder( order => $order );
    ok( $response );
    is( $response->operationSucceeded, 'true' );
    $order = $response->order;

    # test cancelOrder
    $response = $ysm_ws->cancelOrder( orderID => $order->ID );
    ok( $response );
    is( $response->operationSucceeded, 'true' );

}

1;
