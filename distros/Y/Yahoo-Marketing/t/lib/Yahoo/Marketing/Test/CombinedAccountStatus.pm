package Yahoo::Marketing::Test::CombinedAccountStatus;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::CombinedAccountStatus;

sub test_can_create_combined_account_status_and_set_all_fields : Test(4) {

    my $combined_account_status = Yahoo::Marketing::CombinedAccountStatus->new
                                                                         ->accountStatus( 'account status' )
                                                                         ->onlineStatus( 'online status' )
                                                                         ->onlineStatusAsOf( 'online status as of' )
                   ;

    ok( $combined_account_status );

    is( $combined_account_status->accountStatus, 'account status', 'can get account status' );
    is( $combined_account_status->onlineStatus, 'online status', 'can get online status' );
    is( $combined_account_status->onlineStatusAsOf, 'online status as of', 'can get online status as of' );

};



1;

