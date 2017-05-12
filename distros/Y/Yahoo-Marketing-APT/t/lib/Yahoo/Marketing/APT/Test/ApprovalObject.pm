package Yahoo::Marketing::APT::Test::ApprovalObject;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ApprovalObject;

sub test_can_create_approval_object_and_set_all_fields : Test(4) {

    my $approval_object = Yahoo::Marketing::APT::ApprovalObject->new
                                                          ->ID( 'id' )
                                                          ->accountID( 'account id' )
                                                          ->type( 'type' )
                   ;

    ok( $approval_object );

    is( $approval_object->ID, 'id', 'can get id' );
    is( $approval_object->accountID, 'account id', 'can get account id' );
    is( $approval_object->type, 'type', 'can get type' );

};



1;

