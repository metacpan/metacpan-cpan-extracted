package Yahoo::Marketing::APT::Test::Approver;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::Approver;

sub test_can_create_approver_and_set_all_fields : Test(3) {

    my $approver = Yahoo::Marketing::APT::Approver->new
                                             ->approverID( 'approver id' )
                                             ->approverType( 'approver type' )
                   ;

    ok( $approver );

    is( $approver->approverID, 'approver id', 'can get approver id' );
    is( $approver->approverType, 'approver type', 'can get approver type' );

};



1;

