package Yahoo::Marketing::Test::Network;
# Copyright (c) 2009 Yahoo! Inc.  All rights reserved.  
# The copyrights to the contents of this file are licensed under the Perl Artistic License (ver. 15 Aug 1997) 

use strict; use warnings;

use base qw/Test::Class/;
use Test::More;

use Yahoo::Marketing::Network;

sub test_can_create_network_and_set_all_fields : Test(3) {

    my $network = Yahoo::Marketing::Network->new
                                           ->name( 'name' )
                                           ->networkId( 'network id' )
                   ;

    ok( $network );

    is( $network->name, 'name', 'can get name' );
    is( $network->networkId, 'network id', 'can get network id' );

};



1;

