package Yahoo::Marketing::Test::OptInStatus;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::OptInStatus;

sub test_can_create_opt_in_status_and_set_all_fields : Test(3) {

    my $opt_in_status = Yahoo::Marketing::OptInStatus->new
                                                     ->optInEnabled( 'opt in enabled' )
                                                     ->optInReporting( 'opt in reporting' )
                   ;

    ok( $opt_in_status );

    is( $opt_in_status->optInEnabled, 'opt in enabled', 'can get opt in enabled' );
    is( $opt_in_status->optInReporting, 'opt in reporting', 'can get opt in reporting' );

};



1;

