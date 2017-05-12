package Yahoo::Marketing::Test::ProcessStatus;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::ProcessStatus;

sub test_can_create_process_status_and_set_all_fields : Test(5) {

    my $process_status = Yahoo::Marketing::ProcessStatus->new
                                                        ->jobDate( '2008-01-06T17:51:55' )
                                                        ->status( 'status' )
                                                        ->summary( 'summary' )
                                                        ->timeRemaining( 'time remaining' )
                   ;

    ok( $process_status );

    is( $process_status->jobDate, '2008-01-06T17:51:55', 'can get 2008-01-06T17:51:55' );
    is( $process_status->status, 'status', 'can get status' );
    is( $process_status->summary, 'summary', 'can get summary' );
    is( $process_status->timeRemaining, 'time remaining', 'can get time remaining' );

};



1;

