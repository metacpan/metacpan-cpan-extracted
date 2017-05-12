package Yahoo::Marketing::APT::Test::ApprovalDetail;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ApprovalDetail;

sub test_can_create_approval_detail_and_set_all_fields : Test(4) {

    my $approval_detail = Yahoo::Marketing::APT::ApprovalDetail->new
                                                          ->dateTimeValue( 'date time value' )
                                                          ->name( 'name' )
                                                          ->stringValue( 'string value' )
                   ;

    ok( $approval_detail );

    is( $approval_detail->dateTimeValue, 'date time value', 'can get date time value' );
    is( $approval_detail->name, 'name', 'can get name' );
    is( $approval_detail->stringValue, 'string value', 'can get string value' );

};



1;

