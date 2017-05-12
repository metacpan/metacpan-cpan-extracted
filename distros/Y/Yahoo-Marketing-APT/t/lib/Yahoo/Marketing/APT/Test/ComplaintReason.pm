package Yahoo::Marketing::APT::Test::ComplaintReason;
# Copyright (c) 2010 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::APT::ComplaintReason;

sub test_can_create_complaint_reason_and_set_all_fields : Test(3) {

    my $complaint_reason = Yahoo::Marketing::APT::ComplaintReason->new
                                                            ->reason( 'reason' )
                                                            ->reasonID( 'reason id' )
                   ;

    ok( $complaint_reason );

    is( $complaint_reason->reason, 'reason', 'can get reason' );
    is( $complaint_reason->reasonID, 'reason id', 'can get reason id' );

};



1;

