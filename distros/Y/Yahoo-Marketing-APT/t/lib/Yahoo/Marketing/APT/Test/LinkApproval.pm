package Yahoo::Marketing::APT::Test::LinkApproval;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::LinkApproval;

sub test_can_create_link_approval_and_set_all_fields : Test(9) {

    my $link_approval = Yahoo::Marketing::APT::LinkApproval->new
                                                      ->approveLink( 'approve link' )
                                                      ->comments( 'comments' )
                                                      ->guaranteedDealApproval( 'guaranteed deal approval' )
                                                      ->linkContact( 'link contact' )
                                                      ->linkID( 'link id' )
                                                      ->nonGuaranteedDealApproval( 'non guaranteed deal approval' )
                                                      ->proposedCurrency( 'proposed currency' )
                                                      ->sellerPaymentTermsInDays( 'seller payment terms in days' )
                   ;

    ok( $link_approval );

    is( $link_approval->approveLink, 'approve link', 'can get approve link' );
    is( $link_approval->comments, 'comments', 'can get comments' );
    is( $link_approval->guaranteedDealApproval, 'guaranteed deal approval', 'can get guaranteed deal approval' );
    is( $link_approval->linkContact, 'link contact', 'can get link contact' );
    is( $link_approval->linkID, 'link id', 'can get link id' );
    is( $link_approval->nonGuaranteedDealApproval, 'non guaranteed deal approval', 'can get non guaranteed deal approval' );
    is( $link_approval->proposedCurrency, 'proposed currency', 'can get proposed currency' );
    is( $link_approval->sellerPaymentTermsInDays, 'seller payment terms in days', 'can get seller payment terms in days' );

};



1;

